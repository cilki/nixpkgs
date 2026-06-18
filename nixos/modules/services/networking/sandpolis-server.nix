{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.sandpolis-server;
  stateDir = "/var/lib/sandpolis-server";

  # Only the server uses a RON config file, and only for the `server` section;
  # the database location is set with `--data-dir` and everything else uses the
  # application defaults.
  configFile = pkgs.writeText "sandpolis-server.ron" ''
    Configuration(
        server: (
            listen: "${cfg.address}:${toString cfg.port}",
            local: ${lib.boolToString cfg.local},
            service: KeyCdn,
        ),
    )
  '';
in
{
  options.services.sandpolis-server = {
    enable = lib.mkEnableOption "the Sandpolis server";

    package = lib.mkPackageOption pkgs "sandpolis-server" { };

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

    local = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Run as a local stratum (LS) server instead of joining the global
        stratum (GS).
      '';
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
        ExecStart = "${lib.getExe cfg.package} --config ${configFile} --data-dir ${stateDir}";
        Restart = "on-failure";

        DynamicUser = true;
        StateDirectory = "sandpolis-server";
        StateDirectoryMode = "0700";
        WorkingDirectory = stateDir;

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
