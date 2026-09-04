{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, pkg-config
, nix-update-script, git, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "resplice";
  version = "0.0.3";

  src = fetchFromGitHub {
    owner = "cilki";
    repo= "resplice";
    rev= "39c9df8bfae799fd3e0e8969a5958ee84edfe166";
    hash= "sha256-D1p/Zw9lzgpyJYvddXo1Bo/JpYHMERNmVoN1UA+Op/k=";
  };

  cargoHash = "sha256-F8nhgOfNKS2V3qlm7ZW5ShcH4XllKQSjXUpnfIObz0M=";

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
