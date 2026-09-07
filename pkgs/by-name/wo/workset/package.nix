{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, pkg-config
, nix-update-script, git, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "workset";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "workset";
    rev = "12a00ac8007e863b622bed66e2e8fd1833918436";
    hash = "sha256-KxMp4fbbbCWkahy914npHuRgX/B9QcwwofUJhjBxAps=";
  };

  cargoHash = "sha256-y0fokmohH2R907AphLiCkK4e6S0jc968ZILZuOoFJ+k=";

  nativeBuildInputs = [ pkg-config ];

  nativeCheckInputs = [ git ];

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru.updateScript = nix-update-script { };

  meta = {
    mainProgram = "workset";
    description = "Manage git repos with working sets";
    homepage = "https://github.com/fossable/workset";
    license = lib.licenses.unlicense;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ cilki ];
  };
})
