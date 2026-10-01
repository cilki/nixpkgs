{ lib, rustPlatform, fetchFromGitHub, git, }:

rustPlatform.buildRustPackage {
  pname = "codemine";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "codemine";
    rev = "4e9e4c52fa950c18b30f3341fe43172bf64cdc87";
    hash = "sha256-Vxb3yasrtcP7xo+dVJnuZaqniKMqANw0b083tpIWOx4=";
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
