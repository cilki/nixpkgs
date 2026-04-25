{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  onnxruntime,
  stdenv,
  autoPatchelfHook,
}:

buildNpmPackage (finalAttrs: {
  pname = "redact-mcp";
  version = "2.0.4";

  src = fetchFromGitHub {
    owner = "r3352";
    repo = "redact-mcp";
    rev = "v${finalAttrs.version}";
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
    local onnxDir=$out/lib/node_modules/@mattzam/redact-mcp/node_modules/onnxruntime-node/bin/napi-v3/linux/x64
    mkdir -p "$onnxDir"
    ln -sf ${lib.getLib onnxruntime}/lib/libonnxruntime.so "$onnxDir"/libonnxruntime.so.1.21.0
  '';

  meta = { mainProgram = "redact-mcp"; };
})
