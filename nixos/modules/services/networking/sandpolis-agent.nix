{ config, lib, pkgs, ... }:

let
  cfg = config.services.sandpolis-agent;

  # systemd creates and owns this directory for us when it sits in a place it
  # manages; anywhere else it becomes the administrator's problem and just has
  # to be made writable through the sandbox.
  managedStateDir = cfg.dataDir != null
    && lib.hasPrefix "/var/lib/" cfg.dataDir;

  logFlag = {
    info = [ ];
    debug = [ "--debug" ];
    trace = [ "--trace" ];
  }.${cfg.logLevel};

  args = [
    (lib.getExe cfg.package)
    # One process is one instance, named by its subcommand.
    "agent"
    # The credential, not the original path, so the file itself can stay
    # readable only by root.
    "--realm"
    "%d/sandpolis.realm.pem"
  ] ++ lib.optionals (cfg.dataDir != null) [ "--data" cfg.dataDir ]
    ++ lib.optionals (cfg.poll != null) [
      "--poll"
      cfg.poll
      "--poll-timeout"
      (toString cfg.pollTimeout)
    ] ++ logFlag ++ cfg.extraArgs;
in {
  options.services.sandpolis-agent = {
    enable = lib.mkEnableOption "Sandpolis agent";

    package = lib.mkPackageOption pkgs "sandpolis-agent" { };

    boot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to install the Sandpolis boot agent, a unified kernel image
        that runs before the OS on every boot. It counts down toward
        chainloading the regular NixOS bootloader (by setting the UEFI
        `BootNext` variable and rebooting), unless interrupted at the console
        or held by the server for cold snapshot operations.

        The image is copied to {file}`EFI/sandpolis/sandpolis.efi` on the EFI
        system partition and registered as the first UEFI boot entry, ahead of
        the NixOS bootloader, which stays in the boot order as the entry the
        boot agent chainloads.

        Requires booting through UEFI with
        {option}`boot.loader.efi.canTouchEfiVariables` enabled.
      '';
    };

    realm = lib.mkOption {
      type = lib.types.path;
      example = "/var/lib/secrets/sandpolis/fleet.realm.pem";
      description = ''
        Path to the realm cert naming the server this agent connects to. It
        carries the realm CA along with this agent's own certificate, whose
        common name is the server's address, as three PEM blocks.

        The server writes one per realm into its
        {option}`services.sandpolis-server.dataDir` on every start; copy the one
        for the realm this agent should join.

        The file is passed through a systemd credential, so it may be owned by
        root and unreadable to anyone else.
      '';
    };

    dataDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "/var/lib/sandpolis/agent";
      description = ''
        Directory where the agent's database is stored.

        Set to `null` to keep the database entirely in-memory, losing everything
        when the service stops.
      '';
    };

    poll = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "0 */5 * * * *";
      description = ''
        Cron expression putting the agent in polling mode, where it stays
        disconnected between check-ins instead of holding a connection open.

        The default of `null` keeps the agent continuously connected, which is
        what makes it reachable at any moment.
      '';
    };

    pollTimeout = lib.mkOption {
      type = lib.types.ints.positive;
      default = 30;
      description = ''
        How long each check-in window stays open, in seconds. The server pulls
        the agent's accumulated data and delivers any pending work during this
        window.

        Only meaningful when {option}`services.sandpolis-agent.poll` is set.
      '';
    };

    logLevel = lib.mkOption {
      type = lib.types.enum [ "info" "debug" "trace" ];
      default = "info";
      description = ''
        Verbosity of the agent's logs. For finer control, set `RUST_LOG` in
        {option}`systemd.services.sandpolis-agent.environment`.
      '';
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra command-line arguments passed to the agent.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = cfg.boot -> config.boot.loader.efi.canTouchEfiVariables;
      message = ''
        services.sandpolis-agent.boot needs a UEFI system with
        boot.loader.efi.canTouchEfiVariables enabled, since it registers the
        boot agent in the UEFI boot order.
      '';
    }];

    # Puts the boot agent ahead of the regular bootloader: copies the UKI onto
    # the EFI system partition and makes it the first UEFI boot entry. The
    # NixOS bootloader keeps its own entry, which is what the boot agent
    # chainloads once its countdown expires.
    systemd.services.sandpolis-agent-boot = lib.mkIf cfg.boot {
      description = "Sandpolis boot agent installer";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      unitConfig.ConditionPathExists = "/sys/firmware/efi/efivars";

      path = [ pkgs.diffutils pkgs.efibootmgr pkgs.util-linux ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = let esp = config.boot.loader.efi.efiSysMountPoint;
      in ''
        uki=${cfg.package.efi}/sandpolis.efi
        target=${lib.escapeShellArg esp}/EFI/sandpolis/sandpolis.efi

        if ! cmp --silent "$uki" "$target"; then
          install -D --mode 0644 "$uki" "$target"
        fi

        # The boot entry points at the partition backing the ESP mount.
        source=$(findmnt --noheadings --output SOURCE --target ${
          lib.escapeShellArg esp
        })
        disk=/dev/$(lsblk --noheadings --nodeps --output PKNAME "$source")
        part=$(lsblk --noheadings --nodeps --output PARTN "$source")

        find_entry() {
          efibootmgr | grep -F 'File(\EFI\sandpolis\sandpolis.efi)' | head -n1 | cut -c5-8
        }

        entry=$(find_entry)
        if [ -z "$entry" ]; then
          efibootmgr --create --disk "$disk" --part "$part" \
            --label Sandpolis --loader '\EFI\sandpolis\sandpolis.efi' > /dev/null
          entry=$(find_entry)
        fi

        order=$(efibootmgr | sed -n 's/^BootOrder: //p')
        if [ "''${order%%,*}" != "$entry" ]; then
          rest=$(echo "$order" | tr ',' '\n' | grep -vx "$entry" | paste -sd, -)
          efibootmgr --bootorder "$entry''${rest:+,$rest}" > /dev/null
        fi
      '';
    };

    systemd.services.sandpolis-agent = {
      description = "Sandpolis agent";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = lib.escapeShellArgs args;
        Restart = "on-failure";

        LoadCredential = [ "sandpolis.realm.pem:${toString cfg.realm}" ];

        DynamicUser = true;
        StateDirectory = lib.optional managedStateDir
          (lib.removePrefix "/var/lib/" cfg.dataDir);
        StateDirectoryMode = "0700";
        ReadWritePaths =
          lib.optional (cfg.dataDir != null && !managedStateDir) cfg.dataDir;

        # Hardening. The agent inspects the host, so the sandbox is deliberately
        # looser than the server's.
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectControlGroups = true;
        LockPersonality = true;
      };
    };
  };

  meta.maintainers = with lib.maintainers; [ cilki ];
}
