{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, pkg-config
, nix-update-script, git, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "resplice";
  version = "0.0.3";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "resplice";
    rev = "86ed33f9851c21d6209d29a0db32530bc08e81cc";
    hash = "sha256-P4bBB0D1JW2VWRvdfhng+N+RpiL473fCRA39pyP44ro=";
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
