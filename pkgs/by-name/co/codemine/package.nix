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
    rev = "4b315300224b13cd3851c37beeb46e52e0138e26";
    hash = "sha256-DIIhT/Ib8jilRuoVUT0/Kjvwg7eXRaMBfSrE77GoIb0=";
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
