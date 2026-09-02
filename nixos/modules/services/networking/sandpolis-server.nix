{ config, lib, pkgs, ... }:

let
  cfg = config.services.sandpolis-server;

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
    "server"
  ] ++ lib.optionals (cfg.dataDir != null) [ "--data" cfg.dataDir ]
    ++ [ "--listen" "${cfg.address}:${toString cfg.port}" ] ++ logFlag
    ++ cfg.extraArgs;
in {
  options.services.sandpolis-server = {
    enable = lib.mkEnableOption "Sandpolis server";

    package = lib.mkPackageOption pkgs "sandpolis-server" { };

    dataDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "/var/lib/sandpolis/server";
      description = ''
        Directory holding the database and the realm configs.

        Every {file}`*.realm.ron` file in this directory is served, one realm
        per file, named for the part of the filename before the suffix. The
        server creates {file}`default.realm.ron` if it finds none, so a fresh
        install comes up serving something. Realm configs are mutable state
        rather than configuration: the server writes a freshly minted realm CA
        back into its file, and the account and probe layers persist into it as
        well.

        Each start also writes one realm cert per realm to
        {file}`<realm>.realm.pem` here. That file is what attaches an agent or a
        client, so this is where {option}`services.sandpolis-agent.realm`
        and {option}`programs.sandpolis-client.realmCert` are copied from.

        Note that the server only persists accounts when exactly one realm
        config is loaded, since accounts are not yet realm-scoped upstream.

        Set to `null` to keep the database entirely in-memory, losing everything
        when the service stops. Such a server has no directory to scan, so it
        serves a single implicit `default` realm whose CA is lost with it.
      '';
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Address the server listens on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8768;
      description = "Port the server listens on.";
    };

    logLevel = lib.mkOption {
      type = lib.types.enum [ "info" "debug" "trace" ];
      default = "info";
      description = ''
        Verbosity of the server's logs. For finer control, set `RUST_LOG` in
        {option}`systemd.services.sandpolis-server.environment`.
      '';
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra command-line arguments passed to the server.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the listen port in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts =
      lib.optional cfg.openFirewall cfg.port;

    # The server logs a canonical "Authentication failure" line at WARN for
    # every failed login, token, or client-certificate check, which fail2ban
    # turns into firewall bans; this replaces the in-application blocklist the
    # server used to keep.
    services.fail2ban.jails.sandpolis-server =
      lib.mkIf config.services.fail2ban.enable {
        filter.Definition = {
          failregex = "^.*WARN.*Authentication failure.*peer=<HOST>\\b";
          journalmatch = "_SYSTEMD_UNIT=sandpolis-server.service";
        };
        settings = {
          port = cfg.port;
          backend = "systemd";
          maxretry = lib.mkDefault 5;
          findtime = lib.mkDefault "10m";
          bantime = lib.mkDefault "1h";
        };
      };

    systemd.services.sandpolis-server = {
      description = "Sandpolis server";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = lib.escapeShellArgs args;
        Restart = "on-failure";

        DynamicUser = true;
        StateDirectory = lib.optional managedStateDir
          (lib.removePrefix "/var/lib/" cfg.dataDir);
        StateDirectoryMode = "0700";
        ReadWritePaths =
          lib.optional (cfg.dataDir != null && !managedStateDir) cfg.dataDir;

        # Hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        RestrictNamespaces = true;
        LockPersonality = true;
        SystemCallArchitectures = "native";
      };
    };
  };

  meta.maintainers = with lib.maintainers; [ cilki ];
}
