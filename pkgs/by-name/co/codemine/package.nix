{ lib, rustPlatform, fetchFromGitHub, git, }:

rustPlatform.buildRustPackage {
  pname = "codemine";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "codemine";
    rev = "291ebc2d05c4dbeb3c73196d3019845da074f179";
    hash = "sha256-H/ilSbFUg9FQpzOdZ6mGeUSJAMzg7OPjtUrTeO6rn/0=";
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
