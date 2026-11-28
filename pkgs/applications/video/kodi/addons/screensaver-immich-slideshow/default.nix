{
  lib,
  buildKodiAddon,
  fetchFromGitHub,
  iptcinfo3,
  dateutil,
  requests,
}:

buildKodiAddon rec {
  pname = "screensaver-immich-slideshow";
  namespace = "screensaver.immich.slideshow";
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "smfontes";
    repo = namespace;
    rev = version;
    hash = "sha256-n9XD7oT3XkEWf+D/VOMEyi3yZOH1V+GgV0TTcshjiWM=";
  };

  propagatedBuildInputs = [
    iptcinfo3
    dateutil
    requests
  ];

  meta = {
    homepage = "https://github.com/smfontes/screensaver.immich.slideshow";
    description = "Kodi screensaver that displays a slideshow of pictures from Immich";
    license = lib.licenses.gpl2Only;
    teams = [ lib.teams.kodi ];
  };
}
