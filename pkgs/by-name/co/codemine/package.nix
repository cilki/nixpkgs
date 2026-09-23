{ lib, rustPlatform, fetchFromGitHub, git, }:

rustPlatform.buildRustPackage {
  pname = "codemine";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "codemine";
    rev = "3c0ee1ac160ece1bf96583833ff942638b9de161";
    hash = "sha256-HKDSN+18D4fF3d5312yHefI8NYJpxQ1V5KZaNbxJ4Uc=";
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
