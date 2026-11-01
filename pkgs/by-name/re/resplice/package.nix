{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, pkg-config
, nix-update-script, git, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "resplice";
  version = "0.0.3";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "resplice";
    rev = "2dfebb5c6ddfea9d33916428549a11bbaa2ce499";
    hash = "sha256-yCd+9jcLk2VU9WC3YmYcNOBAUyvBcPG/XIM1KZ747qI=";
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
