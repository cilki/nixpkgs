{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption mkIf mkOption optionalAttrs optionalString optional types;

  cfg = config.services.fossdb;
in {
  options.services.fossdb = {
    enable = mkEnableOption "FossDB, a free software database";

    package = mkOption {
      type = types.package;
      default = pkgs.fossdb;
      defaultText = lib.literalExpression "pkgs.fossdb";
      description = "The fossdb package to use.";
    };

    user = mkOption {
      type = types.str;
      default = "fossdb";
      description = "User account under which fossdb runs.";
    };

    group = mkOption {
      type = types.str;
      default = "fossdb";
      description = "Group account under which fossdb runs.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/fossdb";
      description = "Directory where fossdb stores its database file.";
    };

    hostName = mkOption {
      type = types.str;
      example = "fossdb.example.com";
      description = "Hostname for the fossdb service.";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description =
        "Internal port for the fossdb service. The service will be proxied through nginx on ports 80/443.";
    };

    enableACME = mkOption {
      type = types.bool;
      default = true;
      description =
        "Whether to enable ACME certificate for the configured hostname.";
    };

    useACMEHost = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        A host of an existing ACME certificate to use.
        This is useful if you have many subdomains and want to avoid hitting the rate limit.
        Mutually exclusive with `enableACME`.
      '';
    };

    extraEnvironment = mkOption {
      type = types.attrs;
      default = { };
      example = lib.literalExpression ''
        {
          RUST_LOG = "info";
        }
      '';
      description = "Extra environment variables to pass to fossdb.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description =
        "Whether to open the firewall for the nginx ports (80, 443).";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.enableACME || cfg.useACMEHost != null;
        message =
          "Either services.fossdb.enableACME or services.fossdb.useACMEHost must be set.";
      }
      {
        assertion = !(cfg.enableACME && cfg.useACMEHost != null);
        message =
          "services.fossdb.enableACME and services.fossdb.useACMEHost are mutually exclusive.";
      }
    ];

    # Create system user and group
    users.users = optionalAttrs (cfg.user == "fossdb") {
      fossdb = {
        isSystemUser = true;
        home = cfg.dataDir;
        inherit (cfg) group;
      };
    };

    users.groups = optionalAttrs (cfg.group == "fossdb") { fossdb = { }; };

    # Main fossdb systemd service
    systemd.services.fossdb = {
      description = "fossdb web application";
      documentation = [ "https://github.com/fossdb/fossdb" ];

      wants = [ "network-online.target" ]
        ++ optional (cfg.useACMEHost != null) "acme-${cfg.useACMEHost}.service";
      after = [ "network-online.target" ]
        ++ optional (cfg.useACMEHost != null) "acme-${cfg.useACMEHost}.service";
      wantedBy = [ "multi-user.target" ];

      environment = {
        FOSSDB_DATA_DIR = cfg.dataDir;
        FOSSDB_PORT = toString cfg.port;
        FOSSDB_HOST = "127.0.0.1";
      } // cfg.extraEnvironment;

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.package}/bin/fossdb";

        # Directory management
        StateDirectory = mkIf (cfg.dataDir == "/var/lib/fossdb") [ "fossdb" ];
        StateDirectoryMode = "0750";
        WorkingDirectory = cfg.dataDir;

        # Restart policy
        Restart = "on-failure";
        RestartSec = "5s";

        # Security hardening
        CapabilityBoundingSet = [ "" ];
        LockPersonality = true;
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
        ReadWritePaths =
          mkIf (cfg.dataDir != "/var/lib/fossdb") [ cfg.dataDir ];
        RemoveIPC = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" ];
        UMask = "0027";
      };
    };

    # Configure nginx reverse proxy with ACME
    services.nginx = {
      enable = true;
      virtualHosts.${cfg.hostName} = {
        forceSSL = true;
        enableACME = cfg.enableACME;
        useACMEHost = mkIf (cfg.useACMEHost != null) cfg.useACMEHost;

        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.port}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_buffering off;
          '';
        };
      };
    };

    # Open firewall if requested
    networking.firewall =
      mkIf cfg.openFirewall { allowedTCPPorts = [ 80 443 ]; };

    # Ensure nginx user can reload after ACME renewal if using ACME
    security.acme.certs = mkIf (cfg.useACMEHost != null) {
      ${cfg.useACMEHost}.reloadServices = [ "nginx.service" ];
    };
  };

  meta.maintainers = with lib.maintainers; [ cilki ];
}
