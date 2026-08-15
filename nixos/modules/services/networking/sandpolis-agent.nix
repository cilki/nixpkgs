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
    "--server"
    "%d/sandpolis.server"
  ]
  ++ lib.optionals (cfg.dataDir != null) [
    "--data"
    cfg.dataDir
  ]
  ++ logFlag
  ++ cfg.extraArgs;
in
{
  options.services.sandpolis-agent = {
    enable = lib.mkEnableOption "Sandpolis agent";

    package = lib.mkPackageOption pkgs "sandpolis-agent" { };

    serverFile = lib.mkOption {
      type = lib.types.path;
      example = "/var/lib/secrets/sandpolis/fleet.server";
      description = ''
        Path to the {file}`.server` file naming the server this agent connects
        to. The file carries the realm CA along with this agent's own
        certificate, whose common name is the server's address.

        Generate one on the server with
        {command}`sandpolis-server new-agent-cert --realm <file> --address <host:port> --output <file>`.
        Polling mode is baked into the file at that point by the
        {option}`--poll` and {option}`--poll-timeout` flags, so it is not
        configurable here.

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

        LoadCredential = [ "sandpolis.server:${toString cfg.serverFile}" ];

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
