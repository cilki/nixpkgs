{ config, lib, pkgs, ... }:

let
  inherit (lib)
    literalExpression mkDefault mkEnableOption mkIf mkOption mkPackageOption
    optional optionalAttrs types;

  cfg = config.services.fossdb.collector;
  serverCfg = config.services.fossdb.server;

  hardening = import ./hardening.nix;

  # Declared here as well as in server.nix: a collector or worker can run on
  # a host with no server, and would otherwise have no account to run as.
  account = import ./account.nix {
    inherit lib;
    inherit serverCfg;
  };

  # True when the server runs here too, in which case keys can be provisioned
  # locally and the service should wait for that to happen.
  localServer = serverCfg.enable;

  provisioned = localServer && serverCfg.provisionApiKeys && cfg.apiKeyFile
    == null;

  provisionedKeyFile = "${serverCfg.dataDir}/keys/collector.key";
in {
  options.services.fossdb.collector = {
    enable = mkEnableOption ''
      the FossDB collector, which ingests package metadata from upstream
      registries into a FossDB server
    '';

    package = mkPackageOption pkgs "fossdb" { };

    serverUrl = mkOption {
      type = types.strMatching "^https?://.*[^/]$";
      default = "http://127.0.0.1:${toString serverCfg.collectorPort}";
      defaultText = literalExpression ''
        "http://127.0.0.1:''${toString config.services.fossdb.server.collectorPort}"'';
      example = "http://fossdb.internal:3001";
      description = ''
        Base URL of the server's internal collector API, without a trailing
        slash.

        Note this is the collector API port, not the public one. That API is
        protected by an API key alone, so when reaching it across a network
        restrict it at the firewall as well.
      '';
    };

    apiKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/fossdb-collector-key";
      description = ''
        File containing a collector API key, as produced by
        `fossdb admin api-key create --role collector`.

        Do not use a nix-store path here as it would make the key publicly
        readable. The file is passed via systemd credentials and need only be
        readable by root.

        When null and the server runs on this host with
        {option}`services.fossdb.server.provisionApiKeys` enabled, a key is
        minted automatically and this option can be left unset. When null and
        there is no local server, the service will fail to start.
      '';
    };

    intervalHours = mkOption {
      type = types.ints.positive;
      default = 1;
      description = "How often to poll upstream registries for new packages.";
    };

    librariesIoApiKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/libraries-io-key";
      description = ''
        File containing a libraries.io API key, which raises that service's
        rate limits. Only consulted by the libraries.io collector.
      '';
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = literalExpression ''
        {
          RUST_LOG = "info,fossdb_collector=debug";
        }
      '';
      description = "Extra environment variables for the collector process.";
    };
  };

  config = mkIf cfg.enable (account // {
    assertions = [{
      assertion = cfg.apiKeyFile != null || provisioned;
      message = ''
        services.fossdb.collector.apiKeyFile must be set unless the FossDB
        server runs on this host with services.fossdb.server.provisionApiKeys
        enabled.

        Create a key on the server with:
          fossdb admin api-key create --role collector --label <host>
      '';
    }];

    systemd.services.fossdb-collector = {
      description = "FossDB package collector";
      documentation = [ "https://github.com/fossable/fossdb" ];

      wants = [ "network-online.target" ];
      after = [ "network-online.target" ]
        ++ optional localServer "fossdb-server.service"
        ++ optional provisioned "fossdb-provision.service";
      # Only bind to provisioning: without a key there is nothing to do, but a
      # server restart should not take the collector down with it.
      requires = optional provisioned "fossdb-provision.service";
      wantedBy = [ "multi-user.target" ];
      partOf = [ "fossdb.target" ];

      environment = {
        SERVER_INTERNAL_URL = cfg.serverUrl;
        COLLECTOR_INTERVAL_HOURS = toString cfg.intervalHours;
        RUST_LOG = mkDefault "info";
      }
      # The binary reads the key from the file named here, so the secret never
      # enters its environment where /proc would expose it.
        // (if cfg.apiKeyFile != null then {
          COLLECTOR_API_KEY_FILE = "%d/api-key";
        } else {
          COLLECTOR_API_KEY_FILE = provisionedKeyFile;
        }) // optionalAttrs (cfg.librariesIoApiKeyFile != null) {
          LIBRARIES_IO_API_KEY_FILE = "%d/libraries-io-key";
        } // cfg.extraEnvironment;

      serviceConfig = hardening // {
        Type = "exec";
        User = serverCfg.user;
        Group = serverCfg.group;
        ExecStart = "${cfg.package}/bin/fossdb-collector";

        LoadCredential =
          optional (cfg.apiKeyFile != null) "api-key:${cfg.apiKeyFile}"
          ++ optional (cfg.librariesIoApiKeyFile != null)
          "libraries-io-key:${cfg.librariesIoApiKeyFile}";

        # Needs to read the provisioned key out of the server's state
        # directory, but writes nothing itself.
        ReadOnlyPaths = optional provisioned serverCfg.dataDir;

        Restart = "on-failure";
        RestartSec = "30s";
      };
    };
  });

  meta.maintainers = with lib.maintainers; [ cilki ];
}
