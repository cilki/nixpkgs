{
  lib,
  rustPlatform,
  fetchFromGitLab,
  fetchPnpmDeps,
  cargo-tauri,
  glib,
  glib-networking,
  gtk3,
  jq,
  libsoup_3,
  moreutils,
  nodejs,
  openssl,
  pkg-config,
  pnpmConfigHook,
  pnpm_10,
  webkitgtk_4_1,
  wrapGAppsHook3,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "futo-notes";
  version = "1.6.1";

  src = fetchFromGitLab {
    domain = "gitlab.futo.org";
    owner = "futo-notes";
    repo = "futo-notes";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ILtfrU/Pr+Gmnngt65W2A4NBx93OwfHHAVCA8r7Nm4c=";
  };

  cargoHash = "sha256-ZeCFObDMeI37QqklsqqqWMe0CBsaXoyyrfI7X5IayP4=";

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-yanbyx82Rq5onWXIU+VNVg3T9Ca/5EEVyG/by0D25qQ=";
  };

  nativeBuildInputs = [
    cargo-tauri.hook
    jq
    moreutils
    nodejs
    pkg-config
    pnpmConfigHook
    pnpm_10
    wrapGAppsHook3
  ];

  buildInputs = [
    glib-networking
    gtk3
    libsoup_3
    openssl
    webkitgtk_4_1
  ];

  # - upstream stamps the release version into tauri.conf.json at deploy time
  #   (the in-tree value is a stale placeholder)
  # - the frontend is built in preBuild instead of beforeBuildCommand
  # - the bundle.linux file mappings reference gen/linux/libonnxruntime.so,
  #   which upstream downloads with a helper script and is absent from the
  #   source archive; it is only used for semantic search, which needs a
  #   model that is not bundled on Linux (the app falls back to BM25 search)
  postPatch = ''
    jq '
      .version = "${finalAttrs.version}" |
      del(.build.beforeBuildCommand) |
      del(.bundle.linux)
    ' apps/tauri/src-tauri/tauri.conf.json | sponge apps/tauri/src-tauri/tauri.conf.json
  '';

  preBuild = ''
    pnpm run build
  '';

  buildAndTestSubdir = "apps/tauri/src-tauri";

  env.OPENSSL_NO_VENDOR = 1;

  # The Tauri bundler generates the desktop entry with empty Categories
  postInstall = ''
    substituteInPlace "$out/share/applications/FUTO Notes.desktop" \
      --replace-fail "Categories=" "Categories=Office;TextEditor;"
  '';

  # The app shells out to gdbus to monitor the XDG portal color scheme
  preFixup = ''
    gappsWrapperArgs+=(--prefix PATH : ${lib.makeBinPath [ glib ]})
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Offline-first markdown notes app with optional end-to-end-encrypted sync";
    homepage = "https://gitlab.futo.org/futo-notes/futo-notes";
    # Upstream has not published a license file for the client yet; the
    # companion futo-notes-server ships the Source First License 1.1 and
    # other FUTO projects use the same license.
    license = lib.licenses.sfl;
    maintainers = with lib.maintainers; [ cilki ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "futo-notes-tauri";
  };
})
