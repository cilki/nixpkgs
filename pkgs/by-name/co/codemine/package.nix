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
    rev = "bb0452d80a28a94e8d8b739664fb060403451be7";
    hash = "sha256-JbdAM3hPWpt+xYDVeY00w5pRUuELyUtCmKkJIAtjY58=";
  };

  cargoHash = "sha256-uglL5leMEYC+QPtzbl/RqtVuCh3xRZrJMrTzGqJTfOE=";

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
