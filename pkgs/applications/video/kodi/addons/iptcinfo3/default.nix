{
  lib,
  rel,
  buildKodiAddon,
  fetchzip,
  addonUpdateScript,
}:

buildKodiAddon rec {
  pname = "iptcinfo3";
  namespace = "script.module.iptcinfo3";
  version = "2.2.0";

  src = fetchzip {
    url = "https://mirrors.kodi.tv/addons/${lib.toLower rel}/${namespace}/${namespace}-${version}.zip";
    hash = "sha256-M6iS0mAZInU/RUWkwENthshiuX6HHnqbTtI5MjXVdgs=";
  };

  passthru = {
    pythonPath = "lib";
    updateScript = addonUpdateScript {
      attrPath = "kodi.packages.iptcinfo3";
    };
  };

  meta = {
    homepage = "https://github.com/jamesacampbell/iptcinfo3";
    description = "Extract IPTC metadata from image files";
    license = lib.licenses.gpl2Only;
    teams = [ lib.teams.kodi ];
  };
}
