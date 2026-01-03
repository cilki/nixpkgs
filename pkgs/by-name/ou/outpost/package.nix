{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, nix-update-script, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "outpost";
  version = "0.0.8";

  src = fetchFromGitHub {
    owner = "fossable";
    repo = "outpost";
    rev = "v${finalAttrs.version}";
    hash = "sha256-O9yhyJZpjQxC0HP43RsOgPMOKp6d23SNhMLiGtmwXzs=";
  };

  cargoHash = "sha256-NF0Fj+r6qWcM4VEIm1fzveZuz6MIaG32Z+zBfSMC/t4=";

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru.updateScript = nix-update-script { };

  meta = {
    mainProgram = "outpost";
    description = "Immutable infrastructure for the desktop";
    homepage = "https://github.com/fossable/outpost";
    license = lib.licenses.unlicense;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ cilki ];
  };
})
