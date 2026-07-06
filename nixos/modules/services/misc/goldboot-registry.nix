{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.goldboot-registry;
in
{
  options.services.goldboot-registry = {
    enable = lib.mkEnableOption "the goldboot image registry server";

    package = lib.mkPackageOption pkgs "goldboot-registry" { };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = ''
        Address to bind the goldboot registry to. The registry speaks plain
        HTTP and performs no authentication, so this should stay on loopback
        when the nginx reverse proxy is used.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port to bind the goldboot registry to.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Open the registry port in the firewall. Only useful for direct
        (unproxied) access from other hosts; leave disabled when using
        {option}`services.goldboot-registry.nginx`.
      '';
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/goldboot-registry";
      description = "Directory holding hosted .gb images.";
    };

    maxUploadSize = lib.mkOption {
      type = lib.types.ints.positive;
      default = 32 * 1024 * 1024 * 1024;
      description = "Maximum allowed PUT body size in bytes.";
    };

    nginx = {
      enable = lib.mkEnableOption ''
        an nginx reverse proxy in front of the registry, handling TLS and
        authentication (the registry itself does neither)
      '';

      hostname = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "registry.example.com";
        description = ''
          Hostname of the nginx virtual host to create. TLS is configured
          through the standard virtual host options, e.g.
          {option}`services.nginx.virtualHosts.<hostname>.enableACME` and
          {option}`services.nginx.virtualHosts.<hostname>.forceSSL`.
        '';
      };

      basicAuthFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = "/var/lib/secrets/goldboot-registry.htpasswd";
        description = ''
          Path to an htpasswd file used for HTTP Basic Authentication on the
          virtual host. The goldboot client sends Basic Auth credentials for
          the proxy to enforce. The file should live outside the Nix store;
          create entries with `htpasswd -B <file> <username>` from
          `pkgs.apacheHttpd`. Leave as `null` to run an open registry.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.nginx.enable -> cfg.nginx.hostname != null;
        message = "services.goldboot-registry.nginx.enable requires services.goldboot-registry.nginx.hostname";
      }
    ];

    users.users.goldboot-registry = {
      isSystemUser = true;
      group = "goldboot-registry";
      home = cfg.dataDir;
      description = "goldboot image registry";
    };
    users.groups.goldboot-registry = { };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    systemd.services.goldboot-registry = {
      description = "goldboot image registry";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = lib.escapeShellArgs [
          (lib.getExe cfg.package)
          "--bind"
          "${cfg.listenAddress}:${toString cfg.port}"
          "--data-dir"
          cfg.dataDir
          "--max-upload-size"
          (toString cfg.maxUploadSize)
        ];
        User = "goldboot-registry";
        Group = "goldboot-registry";
        StateDirectory = "goldboot-registry";
        StateDirectoryMode = "0750";
        WorkingDirectory = cfg.dataDir;
        # Hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        ProtectProc = "invisible";
        PrivateTmp = true;
        PrivateDevices = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
          "~@resources"
        ];
        MemoryDenyWriteExecute = true;
        UMask = "0027";
        ReadWritePaths = [ cfg.dataDir ];
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    services.nginx = lib.mkIf cfg.nginx.enable {
      enable = lib.mkDefault true;
      virtualHosts.${cfg.nginx.hostname} = {
        basicAuthFile = lib.mkIf (cfg.nginx.basicAuthFile != null) cfg.nginx.basicAuthFile;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.port}";
          recommendedProxySettings = true;
          extraConfig = ''
            client_max_body_size ${toString cfg.maxUploadSize};
            # Stream uploads straight to the registry instead of spooling
            # multi-gigabyte image pushes to disk first.
            proxy_request_buffering off;
            proxy_read_timeout 1h;
            proxy_send_timeout 1h;
          '';
        };
      };
    };
  };

  meta.maintainers = with lib.maintainers; [ cilki ];
}
