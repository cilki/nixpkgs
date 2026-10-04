{ lib, rustPlatform, fetchFromGitHub, git, }:

rustPlatform.buildRustPackage {
  pname = "codemine";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "codemine";
    rev = "54a31c1f48d11da47aa1f55ad02329d5851ffa06";
    hash = "sha256-44Fjx2mM9446BSR/N8WRsSizyx3JRg+KX8BETxlNh/Q=";
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
