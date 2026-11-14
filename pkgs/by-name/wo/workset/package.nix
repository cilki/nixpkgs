{ fetchFromGitHub, rustPlatform, lib, versionCheckHook, pkg-config
, nix-update-script, git, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "workset";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "workset";
    rev = "6532b68c60fe437801cbb052e9d37abfddcd0702";
    hash = "sha256-kkqGroAGJDzjBL9FJFs9GqLts9q+RaP/pxYVYV9dKxA=";
  };

  cargoHash = "sha256-RvBuH7TNyvqUWopBq1ySC2fK36CSgqwm/e21pCD5fRs=";

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
