{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.sandpolis-agent;

  # systemd creates and owns this directory for us when it sits in a place it
  # manages; anywhere else it becomes the administrator's problem and just has
  # to be made writable through the sandbox.
  managedStateDir = cfg.dataDir != null && lib.hasPrefix "/var/lib/" cfg.dataDir;

  logFlag =
    {
      info = [ ];
      debug = [ "--debug" ];
      trace = [ "--trace" ];
    }
    .${cfg.logLevel};

  args = [
    (lib.getExe cfg.package)
    # One process is one instance, named by its subcommand.
    "agent"
    # The credential, not the original path, so the file itself can stay
    # readable only by root.
    "--realm"
    "%d/sandpolis.realm.pem"
  ]
  ++ lib.optionals (cfg.dataDir != null) [
    "--data"
    cfg.dataDir
  ]
  ++ lib.optionals (cfg.poll != null) [
    "--poll"
    cfg.poll
    "--poll-timeout"
    (toString cfg.pollTimeout)
  ]
  ++ logFlag
  ++ cfg.extraArgs;
in
{
  options.services.sandpolis-agent = {
    enable = lib.mkEnableOption "Sandpolis agent";

    package = lib.mkPackageOption pkgs "sandpolis-agent" { };

    realmCert = lib.mkOption {
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
      type = lib.types.enum [
        "info"
        "debug"
        "trace"
      ];
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
    systemd.services.sandpolis-agent = {
      description = "Sandpolis agent";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = lib.escapeShellArgs args;
        Restart = "on-failure";

        LoadCredential = [ "sandpolis.realm.pem:${toString cfg.realmCert}" ];

        DynamicUser = true;
        StateDirectory = lib.optional managedStateDir (lib.removePrefix "/var/lib/" cfg.dataDir);
        StateDirectoryMode = "0700";
        ReadWritePaths = lib.optional (cfg.dataDir != null && !managedStateDir) cfg.dataDir;

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
