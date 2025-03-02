{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.sandpolis-server;
  eachBitcoind =
    filterAttrs (bitcoindName: cfg: cfg.enable) config.services.bitcoind;

  rpcUserOpts = { name, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        example = "alice";
        description = ''
          Username for JSON-RPC connections.
        '';
      };
      passwordHMAC = mkOption {
        type = types.uniq (types.strMatching "[0-9a-f]+\\$[0-9a-f]{64}");
        example =
          "f7efda5c189b999524f151318c0c86$d5b51b3beffbc02b724e5d095828e0bc8b2456e9ac8757ae3211a5d9b16a22ae";
        description = ''
          Password HMAC-SHA-256 for JSON-RPC connections. Must be a string of the
          format \<SALT-HEX\>$\<HMAC-HEX\>.

          Tool (Python script) for HMAC generation is available here:
          <https://github.com/bitcoin/bitcoin/blob/master/share/rpcauth/rpcauth.py>
        '';
      };
    };
    config = { name = mkDefault name; };
  };

  bitcoindOpts = { config, lib, name, ... }: {
    options = {

      enable = mkEnableOption "Sandpolis server";

      package = mkPackageOption pkgs "sandpolis-server" { };

      configFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/var/lib/${name}/bitcoin.conf";
        description = "The configuration file path to supply bitcoind.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          par=16
          rpcthreads=16
          logips=1
        '';
        description =
          "Additional configurations to be appended to {file}`bitcoin.conf`.";
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/bitcoind-${name}";
        description = "The data directory for bitcoind.";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to automatically open the specified ports in the firewall.
        '';
      };

      listenAddresses = lib.mkOption {
        type = with lib.types;
          listOf (submodule {
            options = {
              addr = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = ''
                  Host, IPv4 or IPv6 address to listen to.
                '';
              };
              port = lib.mkOption {
                type = lib.types.nullOr lib.types.int;
                default = null;
                description = ''
                  Port to listen to.
                '';
              };
            };
          });
        default = [{
          addr = "0.0.0.0";
          port = 8768;
        }];
        example = [
          {
            addr = "192.168.3.1";
            port = 22;
          }
          {
            addr = "0.0.0.0";
            port = 64022;
          }
        ];
        description = ''
          List of addresses and ports to listen on (ListenAddress directive
          in config). If port is not specified for address sshd will listen
          on all ports specified by `ports` option.
          NOTE: this will override default listening on all local addresses and port 22.
          NOTE: setting this option won't automatically enable given ports
          in firewall configuration.
        '';
      };

      pidFile = mkOption {
        type = types.path;
        default = "${config.dataDir}/bitcoind.pid";
        description = "Location of bitcoind pid file.";
      };

      extraCmdlineOptions = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Extra command line options to pass to sandpolis.
          Run sandpolis-server --help to list all available options.
        '';
      };
    };
  };
in {

  options = {
    services.sandpolis-server = mkOption {
      type = types.attrsOf (types.submodule bitcoindOpts);
      default = { };
      description = "Specification of one or more bitcoind instances.";
    };
  };

  config = mkIf (eachBitcoind != { }) {

    environment.systemPackages = [ cfg.package ];

    networking.firewall.allowedTCPPorts =
      lib.optionals cfg.openFirewall cfg.ports;

    systemd.services = mapAttrs' (bitcoindName: cfg:
      (nameValuePair "bitcoind-${bitcoindName}" (let
        configFile = pkgs.writeText "bitcoin.conf" ''
          # If Testnet is enabled, we need to add [test] section
          # otherwise, some options (e.g.: custom RPC port) will not work
          ${optionalString cfg.testnet "[test]"}
          # RPC users
          ${concatMapStringsSep "\n"
          (rpcUser: "rpcauth=${rpcUser.name}:${rpcUser.passwordHMAC}")
          (attrValues cfg.rpc.users)}
          # Extra config options (from bitcoind nixos service)
          ${cfg.extraConfig}
        '';
      in {
        description = "Sandpolis server";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          User = "sandpolis-server";
          Group = "sandpolis-server";
          ExecStart = ''
            ${cfg.package}/bin/sandpolis \
            ${
              if (cfg.configFile != null) then
                "-conf=${cfg.configFile}"
              else
                "-conf=${configFile}"
            } \
            -datadir=${cfg.dataDir} \
            -pid=${cfg.pidFile} \
            ${optionalString cfg.testnet "-testnet"}\
            ${optionalString (cfg.port != null) "-port=${toString cfg.port}"}\
            ${
              optionalString (cfg.prune != null) "-prune=${toString cfg.prune}"
            }\
            ${
              optionalString (cfg.dbCache != null)
              "-dbcache=${toString cfg.dbCache}"
            }\
            ${
              optionalString (cfg.rpc.port != null)
              "-rpcport=${toString cfg.rpc.port}"
            }\
            ${toString cfg.extraCmdlineOptions}
          '';
          Restart = "on-failure";

          # Hardening measures
          PrivateTmp = "true";
          ProtectSystem = "full";
          NoNewPrivileges = "true";
          PrivateDevices = "true";
          MemoryDenyWriteExecute = "true";
        };
      }))) eachBitcoind;

    systemd.tmpfiles.rules = flatten (mapAttrsToList (bitcoindName: cfg:
      [ "d '${cfg.dataDir}' 0770 '${cfg.user}' '${cfg.group}' - -" ])
      eachBitcoind);

    users.users = {
      name = "sandpolis-server";
      group = "sandpolis-server";
      description = "Sandpolis server user";
      home = cfg.dataDir;
      isSystemUser = true;
    };

    users.groups = { "sandpolis-server" = { }; };
  };

  maintainers = with maintainers; [ cilki ];
}
