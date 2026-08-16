{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.sandpolis-client;

  # Where the realm cert lands. The client attaches to every cert it finds in
  # its data directory, so the name only has to be unique among them.
  installedCert = "${cfg.dataDir}/default.realm.pem";
in
{
  options.programs.sandpolis-client = {
    enable = lib.mkEnableOption "the Sandpolis client";

    package = lib.mkPackageOption pkgs "sandpolis-client" { };

    realmCert = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/var/lib/secrets/sandpolis/ops.realm.pem";
      description = ''
        Path to a realm cert naming the server clients connect to. It carries
        the realm CA along with the client certificate, whose common name is the
        server's address, as three PEM blocks.

        The server writes one per realm into its
        {option}`services.sandpolis-server.dataDir` on every start; copy the one
        for the realm these clients should join.

        It is installed into {option}`programs.sandpolis-client.dataDir` at
        activation, readable by {option}`programs.sandpolis-client.group` and no
        one else, so the original may live outside the Nix store and stay
        root-owned. Leave this `null` to have clients start at the login dialog
        instead.
      '';
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/sandpolis/client";
      description = ''
        Directory holding the client's database and its realm certs.

        Clients attach to every {file}`*.realm.pem` file here, which is how they
        are configured without anyone naming a file on the command line. It is
        shared by every user in {option}`programs.sandpolis-client.group`, so
        their clients also share the database it holds.
      '';
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "sandpolis";
      description = ''
        Group owning {option}`programs.sandpolis-client.dataDir`. A user must be
        a member to run the client, since the realm cert is not readable
        otherwise.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    # The client's flags come after its subcommand, so a wrapper can't supply
    # them; the environment is what reaches every way of starting it, including
    # a desktop launcher.
    environment.variables.S7S_DATA = cfg.dataDir;

    users.groups.${cfg.group} = { };

    systemd.tmpfiles.settings."10-sandpolis-client".${cfg.dataDir}.d = {
      user = "root";
      group = cfg.group;
      mode = "0770";
    };

    # A copy rather than a symlink into the store: the cert carries a private
    # key, and the store is world-readable.
    systemd.services.sandpolis-client-cert = lib.mkIf (cfg.realmCert != null) {
      description = "Install the Sandpolis client's realm cert";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-tmpfiles-setup.service" ];
      restartTriggers = [ (toString cfg.realmCert) ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = lib.escapeShellArgs [
          "${pkgs.coreutils}/bin/install"
          "-m"
          "0640"
          "-o"
          "root"
          "-g"
          cfg.group
          (toString cfg.realmCert)
          installedCert
        ];
      };
    };
  };

  meta.maintainers = with lib.maintainers; [ cilki ];
}
