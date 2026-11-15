# Systemd hardening shared by the fossdb server, collector and worker.
#
# This is a plain attrset, not a NixOS module, so it must not be listed in
# module-list.nix. Each service merges it into its own serviceConfig and adds
# only what it additionally needs.
#
# All three components are network clients or servers that read and write a
# state directory and nothing else, so the baseline can be strict.
{
  CapabilityBoundingSet = [ "" ];
  DevicePolicy = "closed";
  LockPersonality = true;
  MemoryDenyWriteExecute = true;
  NoNewPrivileges = true;
  PrivateDevices = true;
  PrivateMounts = true;
  PrivateTmp = true;
  # Not PrivateUsers: the server chowns its admin socket to a shared group so
  # that administrators outside its own user can reach it.
  PrivateUsers = false;
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
  RemoveIPC = true;
  RestrictAddressFamilies = [
    "AF_INET"
    "AF_INET6"
    # The server's admin socket, and the collector's and worker's DNS
    # resolution through nsswitch.
    "AF_UNIX"
  ];
  RestrictNamespaces = true;
  RestrictRealtime = true;
  RestrictSUIDSGID = true;
  SystemCallArchitectures = "native";
  SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" ];
  SystemCallErrorNumber = "EPERM";
  UMask = "0077";
}
