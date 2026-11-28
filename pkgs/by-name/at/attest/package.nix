{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, nix-update-script, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "attest";
  version = "0.6.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "attest";
    rev = "8dc6f5d8b2875453eb03159910f6a91789343ba0";
    hash = "sha256-7bJQfSU/32dYiwwK2XQQlC+s0xdYf2xiUlwDsmlW2pE=";
  };

  cargoHash = "sha256-c0hMi0Mlk34gqcYZXRy+k3CGpi74o2YL3Fy5vuZWHVQ=";

  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru.updateScript = nix-update-script { };

  meta = {
    mainProgram = "attest";
    description = "Dead simple test framework for the age of AI";
    homepage = "https://github.com/fossable/attest";
    license = lib.licenses.unlicense;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ cilki ];
  };
})
