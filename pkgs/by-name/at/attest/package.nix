{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, nix-update-script, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "attest";
  version = "0.6.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "attest";
    rev = "eafd44b278466c61149c11f1e02a84381ef774ce";
    hash = "sha256-X+ZctyjhFhTU57OekjuPxy+rjSbyjSDT7ORsKD6RYQE=";
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
