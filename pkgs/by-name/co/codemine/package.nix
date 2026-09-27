{ lib, rustPlatform, fetchFromGitHub, git, }:

rustPlatform.buildRustPackage {
  pname = "codemine";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "codemine";
    rev = "910facd9f8ed6f0f7010f9b0a226038e9d22bb02";
    hash = "sha256-YDELQ2pW4xwIs9X+v/DlQrNvqBuRrkgPo6pYGy0gl7c=";
  };

  cargoHash = "sha256-mqE8VXqyNYg/BHN3ne8G8aVwh4SWFc7iB2Nh1vmwC80=";

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
