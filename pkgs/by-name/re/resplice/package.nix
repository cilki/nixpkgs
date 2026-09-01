{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, pkg-config
, nix-update-script, git, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "resplice";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "cilki";
    repo= "resplice";
    rev= "90162fc86bfeeb4a47660cdd873adb65b6f2f1ab";
    hash= "sha256-78qUKZ1rFQmHSOhW6c73oJPGM8vwqkU2GhOe2Raguwc=";
  };

  cargoHash = "sha256-XIr5nycihj3ENfFK1xLhLyustlUH2dY78t3a0uOUrXI=";

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
