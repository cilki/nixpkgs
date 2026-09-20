{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage {
  pname = "codemine";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "codemine";
    rev = "bb241c5f80c3771fd0a2712235f225e614dc3758";
    hash = "sha256-Ko/H9pEAQipE0gTDjHQHddJ5or/W6B/s2uM0BWIkSfE=";
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
