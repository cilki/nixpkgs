{ lib, rustPlatform, fetchFromGitHub, git, }:

rustPlatform.buildRustPackage {
  pname = "codemine";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "codemine";
    rev = "b4120b3f6ae4567df8ba5f0ff622f5876bcf250a";
    hash = "sha256-qUVsYsP6uuQeoCEq2mxPLn/bkiDXRy1VxrOzqLYO+38=";
  };

  cargoHash = "sha256-NBBGxOdeC4ILtVvWF46aBaDPiac43faW1qwn7BDMpmM=";

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
