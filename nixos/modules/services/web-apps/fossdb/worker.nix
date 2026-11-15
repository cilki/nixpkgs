{ config, lib, pkgs, ... }:

let
  inherit (lib)
    literalExpression mkDefault mkEnableOption mkIf mkOption mkPackageOption
    optional types;

  cfg = config.services.fossdb.worker;
  serverCfg = config.services.fossdb.server;

  hardening = import ./hardening.nix;

  # Declared here as well as in server.nix: a collector or worker can run on
  # a host with no server, and would otherwise have no account to run as.
  account = import ./account.nix {
    inherit lib;
    inherit serverCfg;
  };

  localServer = serverCfg.enable;

  provisioned = localServer && serverCfg.provisionApiKeys && cfg.apiKeyFile
    == null;

  provisionedKeyFile = "${serverCfg.dataDir}/keys/worker.key";
in {
  options.services.fossdb.worker = {
    enable = mkEnableOption ''
      the FossDB worker, which downloads and analyses package releases

      Workers fetch and unpack arbitrary third-party archives, so run them
      with as little privilege as possible and preferably not on the same
      host as anything sensitive
    '';

    package = mkPackageOption pkgs "fossdb" { };

    serverUrl = mkOption {
      type = types.strMatching "^https?://.*[^/]$";
      default = "http://127.0.0.1:${toString serverCfg.workerPort}";
      defaultText = literalExpression ''
        "http://127.0.0.1:''${toString config.services.fossdb.server.workerPort}"'';
      example = "http://fossdb.internal:3002";
      description = ''
        Base URL of the server's internal worker API, without a trailing
        slash.

        Note this is the worker API port, not the public one. That API is
        protected by an API key alone, so when reaching it across a network
        restrict it at the firewall as well.
      '';
    };

    apiKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/fossdb-worker-key";
      description = ''
        File containing a worker API key, as produced by
        `fossdb admin api-key create --role worker`.

        Do not use a nix-store path here as it would make the key publicly
        readable. The file is passed via systemd credentials and need only be
        readable by root.

        When null and the server runs on this host with
        {option}`services.fossdb.server.provisionApiKeys` enabled, a key is
        minted automatically and this option can be left unset. When null and
        there is no local server, the service will fail to start.
      '';
    };

    intervalSeconds = mkOption {
      type = types.ints.positive;
      default = 60;
      description = ''
        How long to wait before asking the server for another analysis task
        once none is available.
      '';
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = literalExpression ''
        {
          RUST_LOG = "info,fossdb_worker=debug";
        }
      '';
      description = "Extra environment variables for the worker process.";
    };
  };

  config = mkIf cfg.enable (account // {
    assertions = [{
      assertion = cfg.apiKeyFile != null || provisioned;
      message = ''
        services.fossdb.worker.apiKeyFile must be set unless the FossDB
        server runs on this host with services.fossdb.server.provisionApiKeys
        enabled.

        Create a key on the server with:
          fossdb admin api-key create --role worker --label <host>
      '';
    }];

    systemd.services.fossdb-worker = {
      description = "FossDB package analysis worker";
      documentation = [ "https://github.com/fossable/fossdb" ];

      wants = [ "network-online.target" ];
      after = [ "network-online.target" ]
        ++ optional localServer "fossdb-server.service"
        ++ optional provisioned "fossdb-provision.service";
      requires = optional provisioned "fossdb-provision.service";
      wantedBy = [ "multi-user.target" ];
      partOf = [ "fossdb.target" ];

      environment = {
        WORKER_SERVER_URL = cfg.serverUrl;
        WORKER_INTERVAL_SECS = toString cfg.intervalSeconds;
        RUST_LOG = mkDefault "info";
      } // (if cfg.apiKeyFile != null then {
        WORKER_API_KEY_FILE = "%d/api-key";
      } else {
        WORKER_API_KEY_FILE = provisionedKeyFile;
      }) // cfg.extraEnvironment;

      serviceConfig = hardening // {
        Type = "exec";
        User = serverCfg.user;
        Group = serverCfg.group;
        ExecStart = "${cfg.package}/bin/fossdb-worker";

        LoadCredential =
          optional (cfg.apiKeyFile != null) "api-key:${cfg.apiKeyFile}";

        ReadOnlyPaths = optional provisioned serverCfg.dataDir;

        # Analysis unpacks untrusted archives into a scratch directory. Give
        # it a private one rather than letting it write to the state
        # directory, which holds the database and the provisioned keys.
        PrivateTmp = true;
        RuntimeDirectory = "fossdb-worker";
        RuntimeDirectoryMode = "0700";

        Restart = "on-failure";
        RestartSec = "30s";
      };
    };
  });

  meta.maintainers = with lib.maintainers; [ cilki ];
}
