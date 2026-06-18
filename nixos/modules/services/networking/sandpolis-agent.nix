{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.sandpolis-agent;
  stateDir = "/var/lib/sandpolis-agent";

  realmCertFlags = lib.concatMapStringsSep " " (cert: "--realm-cert ${cert}") cfg.realmCerts;
in
{
  options.services.sandpolis-agent = {
    enable = lib.mkEnableOption "the Sandpolis agent";

    package = lib.mkPackageOption pkgs "sandpolis-agent" { };

    servers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "https://sandpolis.example.com:8768/default" ];
      description = ''
        Server URLs the agent should maintain connections to, passed through
        the `$S7S_SERVER` environment variable.
      '';
    };

    realmCerts = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      example = [ "/var/lib/secrets/sandpolis/agent.cert" ];
      description = ''
        Realm certificates the agent uses to authenticate with a server. Each
        path is passed as a `--realm-cert` flag. Certificates are loaded on every
        start and are not persisted, so they must remain available.

        Generate one on the server with
        {command}`sandpolis-server new-agent-cert`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.servers == [ ] || cfg.realmCerts != [ ];
        message = "services.sandpolis-agent: a realm certificate (realmCerts) is required to connect to a server.";
      }
    ];

    systemd.services.sandpolis-agent = {
      description = "Sandpolis agent";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      environment.S7S_SERVER = lib.concatStringsSep "," cfg.servers;

      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} --data-dir ${stateDir} ${realmCertFlags}";
        Restart = "on-failure";

        DynamicUser = true;
        StateDirectory = "sandpolis-agent";
        StateDirectoryMode = "0700";
        WorkingDirectory = stateDir;

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
