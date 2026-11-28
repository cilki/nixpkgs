{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, pkg-config
, nix-update-script, git, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "cibox";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "fossable";
    repo = "cibox";
    rev = "39c886f9efb07550719ba50a0a1c7d082cad30c3";
    hash = "sha256-jbnsbzrtwVtAths0nxBhcUVDUZNNv9QKec3U3IAV+M0=";
  };

  cargoHash = "sha256-YwNjYao5w8+xZNJ5/I64OXhEH8JZ9MN/fgJI9S9gW78=";

  nativeBuildInputs = [ pkg-config ];

  nativeCheckInputs = [ git ];

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru.updateScript = nix-update-script { };

  meta = {
    mainProgram = "cibox";
    description = "Control your CI/CD";
    homepage = "https://github.com/fossable/cibox";
    license = lib.licenses.unlicense;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ cilki ];
  };
})
