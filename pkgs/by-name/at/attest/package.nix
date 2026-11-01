{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, nix-update-script, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "attest";
  version = "0.6.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "attest";
    rev = "d2dbc5241b119b33c04e7c11407ca32d3ececdee";
    hash = "sha256-kwC5yzaPcVl8s4eYG27qJ4P0eiHe9T26CHYd2mIK2Ec=";
  };

  cargoHash = "sha256-5lGg3djyowhOFHHoZ8ibBcgzsX8BRJz6YdY5HT6B2LU=";

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
