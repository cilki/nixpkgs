{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, pkg-config
, nix-update-script, git, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "workset";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "fossable";
    repo = "workset";
    rev = "b99b583ed805a1f43c0cef91597626d1b64d4b66";
    hash = "sha256-tRXb3Vaio6NZ/wju2tI9nZY5EmTf8X2yMuU/8Knipag=";
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
