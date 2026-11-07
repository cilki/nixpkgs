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
    rev = "c527df31fd05d45a8922e3ac7d5c949a84b9562d";
    hash = "sha256-Z4e5xjZF+jH/09+uRz7fl5J5J/x2mevHUwlLF9/gSqs=";
  };

  cargoHash = "sha256-WXd+OTVV9OXfSjLfK3QDQFlhukSYMrkgJcy1pNMVboI=";

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
