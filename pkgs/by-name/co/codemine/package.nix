{ lib, rustPlatform, fetchFromGitHub, git, }:

rustPlatform.buildRustPackage {
  pname = "codemine";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "codemine";
    rev = "d730799e02326f1ea32f213a12058c9ea4532faf";
    hash = "sha256-QFaUiUlJ3kCjPSV5CSayByhKUYKfNYf6QfmLCtdampQ=";
  };

  cargoHash = "sha256-aXW3cxqw7JYJQdI5Y2Ou9o/qJOqEPp93uC27jxwRzBE=";

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
