{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, pkg-config
, nix-update-script, git, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "resplice";
  version = "0.0.3";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "resplice";
    rev = "e9d46ddf9dbd04edb52660ea5d4e54bfa55292b5";
    hash = "sha256-04CIrs2qce+bfsazAluXuguHfFMocL7rki8wJuEJuiI=";
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
