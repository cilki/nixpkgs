{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.futo-notes-server;
in
{
  options.services.futo-notes-server = {

    enable = lib.mkEnableOption "FUTO Notes sync server";

    package = lib.mkPackageOption pkgs "futo-notes-server" { };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = ''
        TCP port the server listens on. The server listens on all
        interfaces; upstream provides no option for a bind address, so use
        a firewall or reverse proxy to restrict access.
      '';
    };

    database = {
      createLocally = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether a PostgreSQL database should be automatically created and
          configured on the local host. If set to `false`, you need to
          provision a database yourself and set
          {option}`services.futo-notes-server.database.url`.
        '';
      };

      url = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default =
          if cfg.database.createLocally then
            "postgres://futo-notes-server@localhost/futo-notes-server?host=/run/postgresql"
          else
            null;
        defaultText = lib.literalExpression ''
          if config.services.futo-notes-server.database.createLocally then
            "postgres://futo-notes-server@localhost/futo-notes-server?host=/run/postgresql"
          else
            null
        '';
        example = "postgres://futo-notes:password@10.0.0.2:5432/futo-notes";
        description = ''
          PostgreSQL connection string, passed to the server as
          `DATABASE_URL`.
        '';
      };
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/run/keys/futo-notes-server.env";
      description = ''
        File containing secret environment variables in the format of an
        {manpage}`systemd.exec(5)` `EnvironmentFile=`. The server
        authenticates clients with a single password whose scrypt hash must
        be provided as `FUTO_NOTES_PASSWORD_HASH`; generate it with
        {command}`futo-notes-server hash <password>`.
      '';
    };

    logLevel = lib.mkOption {
      type = lib.types.enum [
        "debug"
        "info"
        "warn"
        "error"
      ];
      default = "info";
      description = "Log verbosity level.";
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''
        {
          MAX_BLOB_BYTES = "209715200";
          AUTH_RATE_LIMIT = "20";
        }
      '';
      description = ''
        Additional environment variables passed to the server. See the
        upstream `.env.example` for the supported settings.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the firewall for the configured port.";
    };

  };

  config = lib.mkIf cfg.enable {

    assertions = [
      {
        assertion = cfg.database.url != null;
        message = "services.futo-notes-server.database.url must be set when services.futo-notes-server.database.createLocally is false";
      }
    ];

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    services.postgresql = lib.mkIf cfg.database.createLocally {
      enable = true;
      ensureDatabases = [ "futo-notes-server" ];
      ensureUsers = [
        {
          name = "futo-notes-server";
          ensureDBOwnership = true;
        }
      ];
    };

    systemd.services.futo-notes-server = {
      description = "FUTO Notes sync server";
      documentation = [ "https://gitlab.futo.org/futo-notes/futo-notes-server" ];
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
      ]
      ++ lib.optionals cfg.database.createLocally [ "postgresql.target" ];
      requires = lib.optionals cfg.database.createLocally [ "postgresql.target" ];

      # Database migrations run automatically at startup.
      environment = {
        PORT = toString cfg.port;
        DATABASE_URL = cfg.database.url;
        BLOB_DIR = "/var/lib/futo-notes-server/blobs";
        LOG_LEVEL = cfg.logLevel;
        AUTH_MODE = "password";
      }
      // cfg.extraEnvironment;

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        DynamicUser = true;
        User = "futo-notes-server";
        StateDirectory = "futo-notes-server";
        StateDirectoryMode = "0700";
        EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
        Restart = "on-failure";
        RestartSec = 5;

        # Hardening
        CapabilityBoundingSet = [ "" ];
        DeviceAllow = [ "" ];
        LockPersonality = true;
        # The JavaScript JIT needs W+X mappings
        MemoryDenyWriteExecute = false;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
        UMask = "0077";
      };
    };
  };

  meta.maintainers = with lib.maintainers; [ cilki ];
}
