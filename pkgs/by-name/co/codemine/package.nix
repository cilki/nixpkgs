{ lib, rustPlatform, fetchFromGitHub, }:

rustPlatform.buildRustPackage {
  pname = "codemine";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "codemine";
    rev = "5b369d178126601c69da17a8d11063151303cb2f";
    hash = "sha256-P2uzPeDEW+YefYnHGLo1lrD7OdL/QDxPby275jhpeuQ=";
  };

  cargoHash = "sha256-PvLGpktBYxD4F5cNkWAQTBiiA8bkNNfgkuAhj15UcoE=";

  meta = {
    description = "Turn AI agents into code-mining bots";
    homepage = "https://github.com/cilki/codemine";
    license = lib.licenses.unlicense;
    maintainers = with lib.maintainers; [ cilki ];
    mainProgram = "codemine";
    platforms = lib.platforms.linux;
  };
}
