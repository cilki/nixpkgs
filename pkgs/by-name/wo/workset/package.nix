{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, pkg-config
, nix-update-script, git, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "workset";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "workset";
    rev = "7dfbcd4a1bd0c3eafe7f4f16d0bc27c2174bd837";
    hash = "sha256-a9v4p/KlC10AU+VQ/YcCur630bZeaLXilVzBwGAfOhQ=";
  };

  cargoHash = "sha256-2ivluy2jWDIZP4SrHHndwuECAcN19cTcX/WJBHMmjhU=";

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
