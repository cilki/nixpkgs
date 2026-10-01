{ lib, rustPlatform, fetchFromGitHub, git, }:

rustPlatform.buildRustPackage {
  pname = "codemine";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "codemine";
    rev = "b33d4285e40be2c3fe985881b5ac89287264ae55";
    hash = "sha256-vFKZSkIPMTe2uANAkOtLRkcYIjHTAo7ngzh5+8bptoI=";
  };

  cargoHash = "sha256-SxLBUwzpgIFhDuIF3MGMWAxFs8mNt+o6339Ri79Nk+0=";

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
