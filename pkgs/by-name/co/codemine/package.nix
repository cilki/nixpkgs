{ lib, rustPlatform, fetchFromGitHub, git, }:

rustPlatform.buildRustPackage {
  pname = "codemine";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "codemine";
    rev = "78c49c0f5e43d9d0dfd101bf6a6bf7b2751a8b32";
    hash = "sha256-5a0xWGkZv5Bc4eOhb0kXaMmFMnXV8MqG7FLGNGwgrpg=";
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
