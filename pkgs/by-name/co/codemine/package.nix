{
  lib,
  rustPlatform,
  fetchFromGitHub,
  bash,
  coreutils,
  diffutils,
  gawk,
  which,
  gnugrep,
  gnused,
  findutils,
  git,
  jq,
  curl,
  ripgrep,
  util-linux,
  tea,
  gh,
  glab,
  opencode,
  codegraph,
  cargo,
  rustc,
  clippy,
  rustfmt,
  gcc,
  gnumake,
  python3,
  hyperfine,
  rtk,
}:

rustPlatform.buildRustPackage {
  pname = "codemine";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "codemine";
    rev = "aac84c30d1bb5ed7b9a9c15236a664eb952ffa2d";
    hash = "sha256-Ega+Ox4/bOO8mcY74+K+TaK9LuOze3FFT7pbzVm7HAA=";
  };

  cargoHash = "sha256-Bjt0wmtexWuTGKi+Hnr2wFfle68koh0o4ySs3JJMhHc=";

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
