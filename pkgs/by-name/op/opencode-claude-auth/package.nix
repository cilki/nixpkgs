{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
}:

# Upstream builds with pnpm, which the nixpkgs npm builders can't drive, but
# the published tarball is a dependency-free bundle (the only peer dependency,
# @opencode-ai/plugin, is provided by the opencode host), so it just needs
# unpacking into a node_modules root opencode can load the plugin from.
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencode-claude-auth";
  version = "2.2.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/opencode-claude-auth/-/opencode-claude-auth-${finalAttrs.version}.tgz";
    hash = "sha512-EYU6hbP9edKQABn5zKMXPdxT5KZLf/0qII7AgahCW2w/FGgJnSE5bbWU5bTGmlHZTAJXixdy94/3WpBgIlHMaA==";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/opencode-claude-auth
    cp -r . $out/lib/node_modules/opencode-claude-auth

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--url"
      "https://github.com/griffinmartin/opencode-claude-auth"
    ];
  };

  meta = {
    description = "OpenCode plugin that uses your existing Claude Code credentials";
    homepage = "https://github.com/griffinmartin/opencode-claude-auth";
    changelog = "https://github.com/griffinmartin/opencode-claude-auth/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ GaetanLepage ];
    platforms = lib.platforms.all;
  };
})
