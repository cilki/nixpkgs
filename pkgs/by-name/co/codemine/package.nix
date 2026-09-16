{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage {
  pname = "codemine";
  version = "0.1.0-unstable-2026-09-14";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "codemine";
    rev = "9491a4ff8bcdd3f74868ce0a4b03267aec4116f0";
    hash = "sha256-JWZoOEYeqGBtHDsm2NWdBFfObQlwFA3pm6ofytuiZ44=";
  };

  cargoHash = "sha256-CXgHTwqDwKakHZ4vg+6IQcApQb7eCv8PxhNFZTvA9X8=";

  meta = {
    description = "Unattended software development harness that sweeps repositories with opencode turns";
    homepage = "https://github.com/cilki/codemine";
    license = lib.licenses.unlicense;
    maintainers = with lib.maintainers; [ cilki ];
    mainProgram = "codemine";
    platforms = lib.platforms.linux;
  };
}
