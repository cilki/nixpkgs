{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, pkg-config
, nix-update-script, git, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "workset";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "fossable";
    repo = "workset";
    rev = "850490fafca84c8b97e4fcc02f3fc9746c421181";
    hash = "sha256-+HgBH1ul7AoaiTU5uOzaIrTfHcml8uACNrJASxTmw24=";
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
