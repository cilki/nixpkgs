{ lib, callPackage, ... }:

let
  metaCommon = with lib; {
    description = "";
    homepage = "https://github.com/fossable/sandpolis";
    license = licenses.agpl3Plus;
    sourceProvenance = with sourceTypes; [ fromSource ];
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ cilki ];
  };
in {

  sandpolis-agent = callPackage ./agent.nix { metaCommon = metaCommon; };
  sandpolis-server = callPackage ./server.nix { metaCommon = metaCommon; };
  sandpolis-client = callPackage ./client.nix { metaCommon = metaCommon; };
}
