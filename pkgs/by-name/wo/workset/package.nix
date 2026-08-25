{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, pkg-config
, nix-update-script, git, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "workset";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "fossable";
    repo = "workset";
    rev = "d021e3b34ac9dc9c4006b561acbec0571c91955c";
    hash = "sha256-ujdpbwoeJDYEtkOEajH9qoRe3sfCH5faj7LUVVMCx7I=";
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
