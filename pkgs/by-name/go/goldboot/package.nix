{ fetchFromGitHub, rustPlatform, pkgs, lib }:

rustPlatform.buildRustPackage rec {
  pname = "goldboot";
  version = "0.0.9";

  meta = { mainProgram = "goldboot"; };
  nativeBuildInputs = with pkgs; [ pkg-config ];
  buildInputs = with pkgs; [ zstd OVMF qemu qemu-utils gtk4 ];

  src = fetchFromGitHub {
    owner = "fossable";
    repo = "goldboot";
    # rev = version;
    rev = "master";
    hash = "sha256-V0VhiwAizsIVAnrl2MpcwZLgvGWWIlXPeuRnjywyXiw=";
  };

  # sourceRoot = "goldboot";

  useFetchCargoVendor = true;
  cargoHash = "sha256-BN+5tosuU93Ak/jt4kizZzxoyslHNavOP6Yc9SwiPVU=";

  passthru.updateScript = ./update.sh;
}

