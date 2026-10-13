{ lib, rustPlatform, fetchFromGitHub, git, }:

rustPlatform.buildRustPackage {
  pname = "codemine";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "codemine";
    rev = "86921f8ad0ee38e0b366cf35fa5f1240de5767b4";
    hash = "sha256-J71mlojWd6FSPXJdOCjllmhtP1QCL6dsFAn1yUkCp5c=";
  };

  cargoHash = "sha256-Bjt0wmtexWuTGKi+Hnr2wFfle68koh0o4ySs3JJMhHc=";

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
