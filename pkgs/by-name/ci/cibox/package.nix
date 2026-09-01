{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, pkg-config
, nix-update-script, git, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "cibox";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "fossable";
    repo = "cibox";
    rev = "fdf446a272cbd2c2eddd0d8dd1326b9b12739244";
    hash = "sha256-xif2VBPG7SLrhE4vqtXofJKmxzxYziMSxsHP/G4JGWI=";
  };

  cargoHash = "sha256-Bh1Pe1cwUPVCelpMDx9GeYL0N55a24iDq3PFY8Ceqds=";

  nativeBuildInputs = [ pkg-config ];

  nativeCheckInputs = [ git ];

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru.updateScript = nix-update-script { };

  meta = {
    mainProgram = "cibox";
    description = "Control your CI/CD";
    homepage = "https://github.com/fossable/cibox";
    license = lib.licenses.unlicense;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ cilki ];
  };
})
