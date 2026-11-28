{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, pkg-config
, nix-update-script, git, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "resplice";
  version = "0.0.3";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "resplice";
    rev = "30d402be44c894881e51c1eabdc440f9fc0cdefd";
    hash = "sha256-zBvw5k94ngKIwr6KkPKulDiUF9fX6bJ4v3iEgr1H9kc=";
  };

  cargoHash = "sha256-2+NqrWYYvSiMrJZmCvu05hUrRsJywGiV23qIRysPe1E=";

  nativeBuildInputs = [ pkg-config ];

  nativeCheckInputs = [ git ];

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru.updateScript = nix-update-script { };

  meta = {
    mainProgram = "resplice";
    description = "Rewrite it in Rust";
    homepage = "https://github.com/cilki/resplice";
    license = lib.licenses.unlicense;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ cilki ];
  };
})
