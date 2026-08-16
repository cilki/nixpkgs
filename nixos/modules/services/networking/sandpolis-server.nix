{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.sandpolis-server;

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
    "server"
  ]
  ++ lib.optionals (cfg.realmCert != null) [
    # The credential, not the original path, so the file itself can stay
    # readable only by root.
    "--realm"
    "%d/sandpolis.realm.pem"
  ]
  ++ lib.optionals (cfg.dataDir != null) [
    "--data"
    cfg.dataDir
  ]
  ++ [
    "--listen"
    "${cfg.address}:${toString cfg.port}"
  ]
  ++ lib.concatMap (ip: [
    "--blocked-ips"
    ip
  ]) cfg.blockedIps
  ++ logFlag
  ++ cfg.extraArgs;
in
{
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
        client, so this is where {option}`services.sandpolis-agent.realmCert`
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

    blockedIps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "192.0.2.1" ];
      description = ''
        IP addresses denied access to the server, rejected before
        authentication runs.
      '';
    };

    realmCert = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/var/lib/secrets/sandpolis/ops.realm.pem";
      description = ''
        Path to a realm cert naming an upstream server, which makes this a local
        stratum server rather than the network's global stratum one. It carries
        the realm CA along with this server's own certificate, whose common name
        is the upstream address, as three PEM blocks.

        The global stratum server writes one per realm into its
        {option}`services.sandpolis-server.dataDir` on every start; copy the one
        for the realm this server should join.

        The file is passed through a systemd credential, so it may be owned by
        root and unreadable to anyone else. A local stratum server serves no
        realms of its own, so any realm config in
        {option}`services.sandpolis-server.dataDir` is ignored while this is set.
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
    networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;

    systemd.services.sandpolis-server = {
      description = "Sandpolis server";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = lib.escapeShellArgs args;
        Restart = "on-failure";

        LoadCredential = lib.optional (
          cfg.realmCert != null
        ) "sandpolis.realm.pem:${toString cfg.realmCert}";

        DynamicUser = true;
        StateDirectory = lib.optional managedStateDir (lib.removePrefix "/var/lib/" cfg.dataDir);
        StateDirectoryMode = "0700";
        ReadWritePaths = lib.optional (cfg.dataDir != null && !managedStateDir) cfg.dataDir;

        # Hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        LockPersonality = true;
        SystemCallArchitectures = "native";
      };
    };
  };

  meta.maintainers = with lib.maintainers; [ cilki ];
}
