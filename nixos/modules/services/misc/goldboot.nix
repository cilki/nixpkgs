{ config, lib, pkgs, ... }:
let
  cfg = config.services.goldboot;

  # Build the parts of the config we can know at evaluation time (no
  # secrets). The systemd unit's preStart script merges in the password
  # hashes loaded via LoadCredential and emits the final TOML to
  # /run/goldboot-registry/config.toml — so secrets never enter the
  # /nix/store.
  staticConfig = {
    server = {
      bind = "${cfg.listenAddress}:${toString cfg.port}";
      data_dir = cfg.dataDir;
      token_ttl_secs = cfg.tokenTtl;
      max_upload_size = cfg.maxUploadSize;
    } // lib.optionalAttrs cfg.tls.enable {
      tls_cert = "%d/tls-cert";
      tls_key = "%d/tls-key";
    };
  } // cfg.extraConfig;

  staticConfigJson = pkgs.writeText "goldboot-registry-static.json"
    (builtins.toJSON staticConfig);

  # For each configured user, build an awk fragment that injects the
  # corresponding [users.<name>] block from the credential file. Awk is
  # used so the password hash never appears as a literal in /nix/store.
  userBlocks = lib.concatMapStringsSep "\n" (name:
    let
      u = cfg.users.${name};
      credPath = ''"$CREDENTIALS_DIRECTORY/${name}-hash"'';
    in ''
      printf '\n[users.%s]\n' ${lib.escapeShellArg name} >> "$cfg_out"
      printf 'password_hash = "'
      tr -d '\n' < ${credPath}
      printf '"\n'
      printf 'pull = %s\n' ${lib.boolToString u.pull}
      printf 'push = %s\n' ${lib.boolToString u.push}
    '') (lib.attrNames cfg.users);

in {
  options.services.goldboot = {
    enable = lib.mkEnableOption "the goldboot image registry server";

    package = lib.mkPackageOption pkgs "goldboot-registry" { };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Address to bind the goldboot registry to.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port to bind the goldboot registry to.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the configured port in the firewall.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/goldboot-registry";
      description = "Directory holding hosted .gb images.";
    };

    tokenTtl = lib.mkOption {
      type = lib.types.ints.positive;
      default = 86400;
      description = "Lifetime of issued bearer tokens, in seconds.";
    };

    maxUploadSize = lib.mkOption {
      type = lib.types.ints.positive;
      default = 32 * 1024 * 1024 * 1024;
      description = "Maximum allowed PUT body size in bytes.";
    };

    tls = {
      enable = lib.mkEnableOption "TLS";
      certFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Path to the TLS certificate (PEM). Loaded via LoadCredential so
          the file must be readable by root at activation time but the
          service itself runs unprivileged.
        '';
      };
      keyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to the TLS private key (PEM).";
      };
    };

    users = lib.mkOption {
      default = { };
      description = ''
        Registry user accounts. Each user is identified by a path to a
        file (outside the Nix store) containing the argon2id hash of its
        password. Generate one with:

            goldboot-registry user hash > /var/lib/secrets/alice.hash

        The hash file is loaded via systemd `LoadCredential=` at service
        start time, so its plaintext never enters /nix/store.
      '';
      type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
        options = {
          passwordHashFile = lib.mkOption {
            type = lib.types.path;
            description = ''
              Path to a file containing the argon2id hash of this
              user's password.
            '';
          };
          pull = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Allow this user to pull images.";
          };
          push = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Allow this user to push images.";
          };
        };
      }));
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Extra TOML keys merged into the generated configuration.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.tls.enable
          -> (cfg.tls.certFile != null && cfg.tls.keyFile != null);
        message =
          "services.goldboot.tls.enable requires both certFile and keyFile";
      }
      {
        assertion =
          let pathInStore = p: lib.hasPrefix builtins.storeDir (toString p);
          in !(lib.any (u: pathInStore u.passwordHashFile)
            (lib.attrValues cfg.users));
        message =
          "services.goldboot.users.*.passwordHashFile must point outside /nix/store "
          + "(otherwise the hash is world-readable in the Nix store).";
      }
    ];

    users.users.goldboot-registry = {
      isSystemUser = true;
      group = "goldboot-registry";
      home = cfg.dataDir;
      description = "goldboot image registry";
    };
    users.groups.goldboot-registry = { };

    networking.firewall.allowedTCPPorts =
      lib.mkIf cfg.openFirewall [ cfg.port ];

    systemd.services.goldboot-registry = {
      description = "goldboot image registry";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      preStart = ''
        umask 077
        cfg_out=/run/goldboot-registry/config.toml
        # Render the static (no-secret) portion via remarshal
        ${
          lib.getExe pkgs.remarshal
        } -i ${staticConfigJson} -if json -of toml > "$cfg_out"
        # Append user blocks, reading each password hash from the
        # credential directory provisioned by systemd.
        ${userBlocks}
        chmod 0640 "$cfg_out"
      '';

      serviceConfig = {
        ExecStart = "${
            lib.getExe cfg.package
          } start --config /run/goldboot-registry/config.toml";
        User = "goldboot-registry";
        Group = "goldboot-registry";
        StateDirectory = "goldboot-registry";
        StateDirectoryMode = "0750";
        RuntimeDirectory = "goldboot-registry";
        RuntimeDirectoryMode = "0750";
        WorkingDirectory = cfg.dataDir;
        LoadCredential =
          lib.mapAttrsToList (n: u: "${n}-hash:${toString u.passwordHashFile}")
          cfg.users ++ lib.optionals cfg.tls.enable [
            "tls-cert:${toString cfg.tls.certFile}"
            "tls-key:${toString cfg.tls.keyFile}"
          ];
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
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" ];
        MemoryDenyWriteExecute = true;
        UMask = "0027";
        ReadWritePaths = [ cfg.dataDir ];
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };

  meta.maintainers = with lib.maintainers; [ cilki ];
}
