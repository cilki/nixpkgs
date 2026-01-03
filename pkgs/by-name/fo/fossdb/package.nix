{
  lib,
  fetchFromGitHub,
  rustPlatform,
  dioxus-cli,
  wasm-bindgen-cli,
  binaryen,
  pkg-config,
  openssl,
  sqlite,
}:
let
  fossdb-client = rustPlatform.buildRustPackage rec {
    pname = "fossdb-client";
    version = "0.0.1";

    src = fetchFromGitHub {
      owner = "fossable";
      repo = "fossdb";
      rev = "2c7d88b460e09bc63c448b3171ce46794f1a1885";
      hash = "sha256-uLL7R3KvrvF6+ErYEADruV1/AwCXwd6A0zK4egL2KzM=";
    };

    # Build from workspace root to include fossdb dependency
    sourceRoot = "${src.name}";

    cargoHash = "sha256-ab3k+/A5CLHk4JPT+DmAjykUZ+b/9sjzaMittoVGN6c=";

    nativeBuildInputs = [
      dioxus-cli
      wasm-bindgen-cli
      binaryen
    ];

    buildPhase = ''
      runHook preBuild
      cd fossdb-client
      dx build --release --platform web
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r dist $out
      runHook postInstall
    '';

    doCheck = false;
  };
in
rustPlatform.buildRustPackage rec {
  pname = "fossdb";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "fossable";
    repo = "fossdb";
    rev = "2c7d88b460e09bc63c448b3171ce46794f1a1885";
    hash = "sha256-uLL7R3KvrvF6+ErYEADruV1/AwCXwd6A0zK4egL2KzM=";
  };

  sourceRoot = "${src.name}/fossdb";

  cargoHash = "sha256-N09Rpwqy7/GsKnQBm3Zauo8dFrQMiklBTYGMvor/5IM=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
    sqlite
  ];

  preBuild = ''
    # Link the built frontend so it can be served by the backend
    ln -s ${fossdb-client} dist
  '';

  env = {
    OPENSSL_NO_VENDOR = "1";
  };

  doCheck = false;

  meta = {
    description = "Open source software database and discovery platform";
    homepage = "https://github.com/fossable/fossdb";
    license = lib.licenses.unlicense;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "fossdb";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
