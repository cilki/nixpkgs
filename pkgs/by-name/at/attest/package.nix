{
  fetchFromGitHub,
  rustPlatform,
  lib,
  versionCheckHook,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "attest";
  version = "0.5.5";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "attest";
    tag = "3c12213f59cd13ff54fc415ba153c815e8bc1c17";
    hash = "sha256-c1ibpul1+gGjajqKfbN9ykBhfLCd2BPVcypzQLmSWoM=";
  };

  cargoHash = "sha256-RN8L5HlYshgmfEqkHAfLAnHZVqWlQ4YDyQXfICg/Dtg=";

  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru.updateScript = nix-update-script { };

  meta = {
    mainProgram = "attest";
    description = "Dead simple test framework for the age of AI";
    homepage = "https://github.com/fossable/attest";
    license = lib.licenses.unlicense;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ cilki ];
  };
})
