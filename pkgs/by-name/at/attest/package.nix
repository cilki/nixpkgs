{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, nix-update-script, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "attest";
  version = "0.5.5";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "attest";
    rev = "7d53ecc87bdb4839db5a8c739969ba92f889c14f";
    hash = "sha256-+hBgT1R12lG6jTDAu48pdn+atfOi/vTfbwAHQzoAGVE=";
  };

  cargoHash = "sha256-qA+XbpULpXXJmO9eHXm3ZkWT9StafSFoLHiDVmFqgSg=";

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
