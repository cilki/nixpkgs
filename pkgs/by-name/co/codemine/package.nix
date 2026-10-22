{ lib, rustPlatform, fetchFromGitHub, bash, coreutils, diffutils, gawk, which
, gnugrep, gnused, findutils, git, jq, curl, ripgrep, util-linux, tea, gh, glab
, opencode, codegraph, cargo, rustc, clippy, rustfmt, gcc, gnumake, python3
, hyperfine, rtk, }:

rustPlatform.buildRustPackage {
  pname = "codemine";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "codemine";
    rev = "894bbf8d40df6f3c5cc4a3f92e054c6c1d8b9ad3";
    hash = "sha256-fjbCzSLfrwSVBhrEAmj+GZygCENky8yW4YGEBcgEdL8=";
  };

  cargoHash = "sha256-3X2ijVBXE4MGlYemn3d6XymvLUv4+HvlYM2zaGiWp54=";

  nativeCheckInputs = [ git ];

  # Tools available to the agent at runtime, used by the NixOS module.
  # Keep in sync with upstream's nix/runtime.nix when bumping `rev`
  # (cliproxyapi is omitted: the module expects services.cliproxyapi).
  passthru.runtimeDeps = [
    bash
    coreutils
    diffutils
    gawk
    which
    gnugrep
    gnused
    findutils
    git
    jq
    curl
    ripgrep
    util-linux
    tea
    gh
    glab
    opencode
    codegraph
    cargo
    rustc
    clippy
    rustfmt
    gcc
    gnumake
    python3
    hyperfine
    rtk
  ];

  meta = {
    description = "Turn AI agents into code-mining bots";
    homepage = "https://github.com/cilki/codemine";
    license = lib.licenses.unlicense;
    maintainers = with lib.maintainers; [ cilki ];
    mainProgram = "codemine";
    platforms = lib.platforms.linux;
  };
}
