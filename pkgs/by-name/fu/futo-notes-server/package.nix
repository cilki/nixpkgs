{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
  bun,
  makeBinaryWrapper,
  writableTmpDirAsHomeHook,
  nix-update-script,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "futo-notes-server";
  version = "0.5.1";

  src = fetchFromGitLab {
    domain = "gitlab.futo.org";
    owner = "futo-notes";
    repo = "futo-notes-server";
    tag = "v${finalAttrs.version}";
    hash = "sha256-NknRhMCz7xKtBinSJ23QKEefAH6kJcAfLy+tToxsXjY=";
  };

  # Production dependencies only (hono, kysely, pg, uuidv7) — all pure JS, so
  # this fixed-output derivation is platform-independent.
  node_modules = stdenvNoCC.mkDerivation {
    pname = "${finalAttrs.pname}-node_modules";
    inherit (finalAttrs) version src;

    impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
      "GIT_PROXY_COMMAND"
      "SOCKS_SERVER"
    ];

    nativeBuildInputs = [
      bun
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      export BUN_INSTALL_CACHE_DIR=$(mktemp -d)

      bun install \
        --production \
        --frozen-lockfile \
        --ignore-scripts \
        --no-progress

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -R ./node_modules $out

      runHook postInstall
    '';

    dontFixup = true;

    outputHash = "sha256-D1k6rrJhoQh4VpUml6460DiLLuZPZRxHvcF5J9iEbGc=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };

  nativeBuildInputs = [ makeBinaryWrapper ];

  # Upstream bundles with esbuild, but the result still requires the bun
  # runtime (the server uses Bun.serve), so run the TypeScript sources
  # directly like upstream's own `start` script does. This also lets kysely
  # discover the migrations directory on disk.
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/futo-notes-server
    cp -R src package.json tsconfig.json $out/lib/futo-notes-server/
    cp -R ${finalAttrs.node_modules}/node_modules $out/lib/futo-notes-server/

    makeBinaryWrapper ${lib.getExe bun} $out/bin/futo-notes-server \
      --add-flags "run $out/lib/futo-notes-server/src/index.ts"

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Self-hosted end-to-end-encrypted sync server for FUTO Notes";
    homepage = "https://gitlab.futo.org/futo-notes/futo-notes-server";
    license = lib.licenses.sfl;
    maintainers = with lib.maintainers; [ cilki ];
    platforms = bun.meta.platforms;
    mainProgram = "futo-notes-server";
  };
})
