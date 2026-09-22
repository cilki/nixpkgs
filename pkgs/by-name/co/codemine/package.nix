{ lib, rustPlatform, fetchFromGitHub, git, }:

rustPlatform.buildRustPackage {
  pname = "codemine";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "codemine";
    rev = "c87685fba97977ba736ca01d7b2268a0665dace5";
    hash = "sha256-Wq7uKvG+jPIot9XP7SdDPZhMKsPNX/uXI6ftd909ieU=";
  };

  cargoHash = "sha256-PvLGpktBYxD4F5cNkWAQTBiiA8bkNNfgkuAhj15UcoE=";

  nativeCheckInputs = [ git ];

  meta = {
    description = "Turn AI agents into code-mining bots";
    homepage = "https://github.com/cilki/codemine";
    license = lib.licenses.unlicense;
    maintainers = with lib.maintainers; [ cilki ];
    mainProgram = "codemine";
    platforms = lib.platforms.linux;
  };
}
