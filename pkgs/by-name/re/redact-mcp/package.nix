{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  onnxruntime,
  stdenv,
  autoPatchelfHook,
}:

let
  onnxArch = if stdenv.hostPlatform.isx86_64 then "x64" else "arm64";
in
buildNpmPackage (finalAttrs: {
  pname = "redact-mcp";
  version = "2.0.4";

  src = fetchFromGitHub {
    owner = "r3352";
    repo = "redact-mcp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-S6TyhK5wJSFODldtOHcIJmQAEaWmU55n4TjrpXhScg0=";
  };

  sourceRoot = "${finalAttrs.src.name}/server";

  npmDepsHash = "sha256-JKj7ifyl+b/9sdIVRiqlO2Xc45QjfBqFZGCSSRWy7x8=";

  # onnxruntime-node's install script tries to download native binaries from GitHub
  npmRebuildFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = [
    (lib.getLib stdenv.cc.cc)
    onnxruntime
  ];

  # sharp ships musl-linked binaries that can't be patched on glibc
  autoPatchelfIgnoreMissingDeps = [ "libc.musl-*" ];

  postInstall = ''
    local onnxDir=$out/lib/node_modules/@mattzam/redact-mcp/node_modules/onnxruntime-node/bin/napi-v3/linux/${onnxArch}
    mkdir -p "$onnxDir"
    ln -sf ${lib.getLib onnxruntime}/lib/libonnxruntime.so "$onnxDir"/libonnxruntime.so.1.21.0

    mkdir -p $out/redact
    cp -r ../hooks ../skills ../.claude-plugin $out/redact/

    cp ${
      builtins.toFile "mcp.json" (builtins.toJSON { mcpServers.redact-mcp.command = "redact-mcp"; })
    } $out/redact/.mcp.json
  '';

  meta = {
    description = "MCP server that auto-obfuscates sensitive data so LLMs never see real client data";
    homepage = "https://github.com/r3352/redact-mcp";
    changelog = "https://github.com/r3352/redact-mcp/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "redact-mcp";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
