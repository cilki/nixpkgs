{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, pkg-config, openssl
, nix-update-script, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "goldboot-registry";
  version = "0.0.5";

  src = fetchFromGitHub {
    owner = "fossable";
    repo = "goldboot";
    rev = "goldboot-registry-v${finalAttrs.version}";
    hash = lib.fakeHash;
  };

  cargoHash = lib.fakeHash;

  buildAndTestSubdir = "goldboot-registry";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  # The integration test spawns the binary, exercising the real subcommand
  # dispatch + argon2 + axum stack; it requires only stdlib + crates.
  doCheck = true;

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/goldboot-registry";
  versionCheckProgramArg = "--version";

  passthru.updateScript = nix-update-script { };

  meta = {
    mainProgram = "goldboot-registry";
    description = "Image registry server for the goldboot image format";
    homepage = "https://github.com/fossable/goldboot";
    changelog =
      "https://github.com/fossable/goldboot/releases/tag/goldboot-registry-v${finalAttrs.version}";
    license = lib.licenses.unlicense;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ cilki ];
  };
})
