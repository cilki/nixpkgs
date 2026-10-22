{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, pkg-config
, nix-update-script, git, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "workset";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "workset";
    rev = "5fb1f1fa2c2e2602c4debc49b07089a257c4cce4";
    hash = "sha256-fjU5renZPLG/XZmuc4y2Z34v10D24NtCvRHyXVkYajk=";
  };

  cargoHash = "sha256-PhGLMPDs7ktSe85TdnfwM9hNhd2dnykVrJu5Hy4rOng=";

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
