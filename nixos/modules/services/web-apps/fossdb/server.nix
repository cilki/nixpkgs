{ config, lib, pkgs, ... }:

let
  inherit (lib)
    getExe literalExpression mkDefault mkEnableOption mkIf mkOption
    mkPackageOption mkRenamedOptionModule optional optionalString types;

  cfg = config.services.fossdb.server;
  collectorCfg = config.services.fossdb.collector;
  workerCfg = config.services.fossdb.worker;

  hardening = import ./hardening.nix;

  account = import ./account.nix {
    inherit lib;
    serverCfg = cfg;
  };

  # Where the provisioning service writes keys it mints for locally enabled
  # components. Only ever read by services running as the fossdb group.
  keyDir = "${cfg.dataDir}/keys";

  # Components that run on this host and have not been given an explicit key
  # file, and therefore need one provisioned.
  needsProvisioning =
    (optional (collectorCfg.enable && collectorCfg.apiKeyFile == null)
      "collector")
    ++ (optional (workerCfg.enable && workerCfg.apiKeyFile == null) "worker");

  # `fossdb admin` requires the CLI to have been built with the admin feature,
  # which the nixpkgs package does.
  adminCli = "${cfg.package}/bin/fossdb";
in {
  imports = [
    # The module originally defined a single flat service. Point the old names
    # at their new homes so existing configurations keep evaluating.
    (mkRenamedOptionModule [ "services" "fossdb" "enable" ] [
      "services"
      "fossdb"
      "server"
      "enable"
    ])
    (mkRenamedOptionModule [ "services" "fossdb" "package" ] [
      "services"
      "fossdb"
      "server"
      "package"
    ])
    (mkRenamedOptionModule [ "services" "fossdb" "user" ] [
      "services"
      "fossdb"
      "server"
      "user"
    ])
    (mkRenamedOptionModule [ "services" "fossdb" "group" ] [
      "services"
      "fossdb"
      "server"
      "group"
    ])
    (mkRenamedOptionModule [ "services" "fossdb" "dataDir" ] [
      "services"
      "fossdb"
      "server"
      "dataDir"
    ])
    (mkRenamedOptionModule [ "services" "fossdb" "hostName" ] [
      "services"
      "fossdb"
      "server"
      "hostName"
    ])
    (mkRenamedOptionModule [ "services" "fossdb" "port" ] [
      "services"
      "fossdb"
      "server"
      "port"
    ])
    (mkRenamedOptionModule [ "services" "fossdb" "enableACME" ] [
      "services"
      "fossdb"
      "server"
      "enableACME"
    ])
    (mkRenamedOptionModule [ "services" "fossdb" "useACMEHost" ] [
      "services"
      "fossdb"
      "server"
      "useACMEHost"
    ])
    (mkRenamedOptionModule [ "services" "fossdb" "openFirewall" ] [
      "services"
      "fossdb"
      "server"
      "openFirewall"
    ])
    (mkRenamedOptionModule [ "services" "fossdb" "extraEnvironment" ] [
      "services"
      "fossdb"
      "server"
      "extraEnvironment"
    ])
  ];

  options.services.fossdb.server = {
    enable =
      mkEnableOption "the FossDB server, which serves the public API and feeds";

    package = mkPackageOption pkgs "fossdb" { };

    user = mkOption {
      type = types.str;
      default = "fossdb";
      description = "User account under which the FossDB services run.";
    };

    group = mkOption {
      type = types.str;
      default = "fossdb";
      description = ''
        Group under which the FossDB services run.

        Members of this group can reach the server's admin socket and so can
        mint and revoke API keys. Treat membership as administrative.
      '';
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/fossdb";
      description = ''
        Directory holding the database file and any API keys provisioned for
        locally enabled collectors and workers.
      '';
    };

    hostName = mkOption {
      type = types.str;
      example = "fossdb.example.com";
      description = ''
        Public hostname. Used for the nginx virtual host and, unless
        {option}`publicBaseUrl` overrides it, for the absolute URLs in
        RSS/Atom feeds.
      '';
    };

    publicBaseUrl = mkOption {
      type = types.nullOr (types.strMatching "^https?://.*[^/]$");
      default = null;
      defaultText = literalExpression
        ''"https://''${config.services.fossdb.server.hostName}"'';
      example = "https://fossdb.example.com";
      description = ''
        Absolute origin users reach this server at, without a trailing slash.

        Feed documents must contain absolute URLs and the server cannot infer
        its own public origin from behind a reverse proxy. Override this only
        if the public origin differs from {option}`hostName`.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      description = ''
        Port for the public API. Proxied by nginx, so this need not be
        reachable from outside the host.
      '';
    };

    listenAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = ''
        Address the public API binds to. Defaults to loopback because nginx
        proxies it; widen this only if you are not using the bundled nginx
        configuration.
      '';
    };

    collectorPort = mkOption {
      type = types.port;
      default = 3001;
      description = "Port for the internal collector API.";
    };

    workerPort = mkOption {
      type = types.port;
      default = 3002;
      description = "Port for the internal worker API.";
    };

    internalListenAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      example = "10.0.0.1";
      description = ''
        Address the collector and worker APIs bind to.

        These APIs are protected by an API key alone and grant write access to
        package data, so they stay on loopback by default. Change this only to
        run a collector or worker on another host, and firewall the ports to
        those hosts.
      '';
    };

    serveFrontend = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether nginx should serve the FossDB web frontend, a static
        single-page application, alongside the API.
      '';
    };

    adminSocket = mkOption {
      type = types.path;
      default = "/run/fossdb/admin.sock";
      description = ''
        Unix socket for `fossdb admin`. Access is governed entirely by this
        socket's permissions: it is created mode 0660 owned by
        {option}`group`, so anyone in that group can mint and revoke API keys.
      '';
    };

    provisionApiKeys = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to automatically mint API keys for collectors and workers
        enabled on this host that have no {option}`apiKeyFile` set.

        Keys are written under `''${dataDir}/keys` and reissued if they are
        missing or have been revoked. Set this to false to manage every key by
        hand with `fossdb admin api-key create`.
      '';
    };

    accountGraceHours = mkOption {
      type = types.ints.positive;
      default = 4;
      description = ''
        How long an account with no subscriptions is kept before being
        deleted.

        Registration is unauthenticated, so this bounds how much an abusive
        signup run can leave behind. Note the rule applies continuously: an
        established account that removes its last subscription also becomes
        eligible for deletion.
      '';
    };

    timelineRetentionDays = mkOption {
      type = types.ints.positive;
      default = 90;
      description = "How long timeline events are kept before being purged.";
    };

    enableACME = mkOption {
      type = types.bool;
      default = true;
      description =
        "Whether to obtain an ACME certificate for {option}`hostName`.";
    };

    useACMEHost = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Use an existing ACME certificate belonging to another host, which
        avoids issuing a certificate per subdomain. Mutually exclusive with
        {option}`enableACME`.
      '';
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = literalExpression ''
        {
          RUST_LOG = "info,fossdb_server=debug";
        }
      '';
      description = "Extra environment variables for the server process.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open ports 80 and 443 for nginx.";
    };
  };

  config = mkIf cfg.enable (account // {
    assertions = [
      {
        assertion = cfg.enableACME != (cfg.useACMEHost != null);
        message = ''
          Exactly one of services.fossdb.server.enableACME or
          services.fossdb.server.useACMEHost must be set.
        '';
      }
      {
        assertion = let ports = [ cfg.port cfg.collectorPort cfg.workerPort ];
        in lib.length (lib.unique ports) == lib.length ports;
        message = ''
          services.fossdb.server.port, collectorPort and workerPort must all
          differ.
        '';
      }
    ];

    warnings = optional (cfg.internalListenAddress != "127.0.0.1"
      && !config.networking.firewall.enable) ''
        services.fossdb.server.internalListenAddress is not loopback and the
        firewall is disabled. The collector and worker APIs grant write
        access to package data and are protected only by an API key.
      '';

    systemd.services.fossdb-server = {
      description = "FossDB server";
      documentation = [ "https://github.com/fossable/fossdb" ];

      wants = [ "network-online.target" ]
        ++ optional (cfg.useACMEHost != null) "acme-${cfg.useACMEHost}.service";
      after = [ "network-online.target" ]
        ++ optional (cfg.useACMEHost != null) "acme-${cfg.useACMEHost}.service";
      wantedBy = [ "multi-user.target" ];
      partOf = [ "fossdb.target" ];

      environment = {
        DATABASE_PATH = "${cfg.dataDir}/fossdb.db";
        SERVER_PORT = toString cfg.port;
        BIND_ADDRESS = cfg.listenAddress;
        COLLECTOR_PORT = toString cfg.collectorPort;
        WORKER_PORT = toString cfg.workerPort;
        INTERNAL_BIND_ADDRESS = cfg.internalListenAddress;
        PUBLIC_BASE_URL = if cfg.publicBaseUrl != null then
          cfg.publicBaseUrl
        else
          "https://${cfg.hostName}";
        ADMIN_SOCKET_PATH = cfg.adminSocket;
        ACCOUNT_GRACE_HOURS = toString cfg.accountGraceHours;
        TIMELINE_RETENTION_DAYS = toString cfg.timelineRetentionDays;
        RUST_LOG = mkDefault "info";
      } // cfg.extraEnvironment;

      serviceConfig = hardening // {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.package}/bin/fossdb-server serve";

        StateDirectory = mkIf (cfg.dataDir == "/var/lib/fossdb") "fossdb";
        StateDirectoryMode = "0750";
        WorkingDirectory = cfg.dataDir;
        ReadWritePaths =
          mkIf (cfg.dataDir != "/var/lib/fossdb") [ cfg.dataDir ];

        # The admin socket lives here. 0750 so the group can traverse to it
        # while everyone else cannot.
        RuntimeDirectory = "fossdb";
        RuntimeDirectoryMode = "0750";

        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    # Mint API keys for locally enabled components that were not given one.
    #
    # Runs after the server because keys are created through its admin socket;
    # there is no offline key-creation path, by design, so that revocation is
    # always effective.
    systemd.services.fossdb-provision =
      mkIf (cfg.provisionApiKeys && needsProvisioning != [ ]) {
        description =
          "Provision FossDB API keys for local collectors and workers";
        after = [ "fossdb-server.service" ];
        requires = [ "fossdb-server.service" ];
        wantedBy = [ "multi-user.target" ];
        partOf = [ "fossdb.target" ];

        path = [ pkgs.coreutils pkgs.jq ];

        script = ''
          set -euo pipefail

          socket=${lib.escapeShellArg cfg.adminSocket}
          keydir=${lib.escapeShellArg keyDir}
          hostname=${lib.escapeShellArg config.networking.hostName}

          install -d -m 0750 "$keydir"

          # The server creates its socket shortly after start; Type=exec only
          # tells us the process launched, not that it is listening.
          for _ in $(seq 1 60); do
            [ -S "$socket" ] && break
            sleep 0.5
          done

          if [ ! -S "$socket" ]; then
            echo "admin socket $socket never appeared; cannot provision keys" >&2
            exit 1
          fi

          # Keys that currently exist and still work, as "<id> <role>" lines.
          active=$(${adminCli} admin --socket "$socket" --json api-key list \
            | jq -r '.[] | select(.revoked_at == null) | "\(.key_id) \(.role)"')

          provision() {
            role="$1"
            keyfile="$keydir/$role.key"

            if [ -s "$keyfile" ]; then
              # Reuse the stored key only if the server still considers it
              # valid. This reissues after a revoke or a database reset instead
              # of leaving the component permanently unauthorised.
              stored_id=$(cut -d_ -f2 < "$keyfile")
              if echo "$active" | grep -qx "$stored_id $role"; then
                echo "reusing existing $role key $stored_id"
                return 0
              fi
              echo "stored $role key is unknown or revoked; issuing a new one"
            fi

            # Write via a private temporary file so the key is never briefly
            # world-readable at its final path.
            tmp=$(mktemp "$keydir/.$role.XXXXXX")
            trap 'rm -f "$tmp"' RETURN

            ${adminCli} admin --socket "$socket" --json api-key create \
              --role "$role" --label "$hostname ($role)" \
              | jq -r '.key' > "$tmp"

            if [ ! -s "$tmp" ]; then
              echo "failed to mint a $role key" >&2
              return 1
            fi

            chmod 0640 "$tmp"
            mv "$tmp" "$keyfile"
            trap - RETURN
            echo "issued a new $role key"
          }

          ${lib.concatMapStringsSep "\n" (role: "provision ${role}")
          needsProvisioning}
        '';

        serviceConfig = hardening // {
          Type = "oneshot";
          RemainAfterExit = true;
          User = cfg.user;
          Group = cfg.group;

          StateDirectory = mkIf (cfg.dataDir == "/var/lib/fossdb") "fossdb";
          WorkingDirectory = cfg.dataDir;
          ReadWritePaths =
            mkIf (cfg.dataDir != "/var/lib/fossdb") [ cfg.dataDir ];

        };
      };

    # Grouping target so `systemctl restart fossdb.target` cycles the whole
    # deployment.
    systemd.targets.fossdb = {
      description = "All FossDB services";
      wantedBy = [ "multi-user.target" ];
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = mkDefault true;

      virtualHosts.${cfg.hostName} = {
        forceSSL = true;
        inherit (cfg) enableACME;
        useACMEHost = mkIf (cfg.useACMEHost != null) cfg.useACMEHost;

        # Static frontend at the root, with the API and feeds proxied past it.
        root = mkIf cfg.serveFrontend "${cfg.package.frontend}";

        locations = {
          "/api/" = {
            proxyPass = "http://${cfg.listenAddress}:${toString cfg.port}";
            extraConfig = ''
              proxy_buffering off;
            '';
          };

          "/ws/" = {
            proxyPass = "http://${cfg.listenAddress}:${toString cfg.port}";
            proxyWebsockets = true;
          };

          # RSS/Atom. The account id is in the path and is a credential, so
          # make sure nothing caches these responses.
          "/feed/" = {
            proxyPass = "http://${cfg.listenAddress}:${toString cfg.port}";
            extraConfig = ''
              proxy_buffering off;
              proxy_hide_header Set-Cookie;
            '';
          };

          # Single-page application: unknown paths resolve to index.html so
          # client-side routes survive a reload.
          "/" = mkIf cfg.serveFrontend { tryFiles = "$uri $uri/ /index.html"; };
        };
      };
    };

    networking.firewall =
      mkIf cfg.openFirewall { allowedTCPPorts = [ 80 443 ]; };

    security.acme.certs = mkIf (cfg.useACMEHost != null) {
      ${cfg.useACMEHost}.reloadServices = [ "nginx.service" ];
    };
  });

  meta.maintainers = with lib.maintainers; [ cilki ];
}
