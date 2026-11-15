# System account shared by the fossdb server, collector and worker.
#
# This is a plain function, not a NixOS module, so it must not be listed in
# module-list.nix.
#
# Every component declares the account rather than relying on the server to
# do it, because a collector or worker can run on a host with no server at
# all. Declaring it from several modules at once is safe: the values are
# identical, and the option types involved merge equal definitions.
{ lib, serverCfg }: {
  users.users = lib.optionalAttrs (serverCfg.user == "fossdb") {
    fossdb = {
      isSystemUser = true;
      home = serverCfg.dataDir;
      group = serverCfg.group;
    };
  };

  users.groups =
    lib.optionalAttrs (serverCfg.group == "fossdb") { fossdb = { }; };
}
