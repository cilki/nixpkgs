{ lib, rustPlatform, fetchFromGitHub, git, }:

rustPlatform.buildRustPackage {
  pname = "codemine";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "codemine";
    rev = "49b55aa5cfe7506b9e0f98ed508a9b8a56a84e32";
    hash = "sha256-KkzVs7iusZSTJY3txjw2UbFiFFJuBvr5LV+LCREiAh4=";
  };

  cargoHash = "sha256-bA400oxKDLR1HskGDwoR/5cp2UhN84bJOGJoPJRHlso=";

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
