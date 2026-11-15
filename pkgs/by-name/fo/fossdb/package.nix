{ lib, fetchFromGitHub, rustPlatform, dioxus-cli, wasm-bindgen-cli, binaryen
, nixosTests, }:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "fossdb";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "fossdb";
    rev = "94c05298f580473588ebe519c67583c84b8445c9";
    hash = "sha256-LFxmODzzkPq4PnJeUkf/NUcsAvfMuOSFb5X10k9kzAk=";
  };

  cargoHash = "sha256-IZSW6JugPLSllSJVsVENJn6pWsBNi5/KvytQ7uTp9rs=";

  # One vendored dependency set, shared with the frontend derivation below, so
  # there is a single hash to maintain for the whole workspace.
  cargoDeps = rustPlatform.fetchCargoVendor {
    name = "${finalAttrs.pname}-cargo-deps";
    inherit (finalAttrs) src;
    hash = finalAttrs.cargoHash;
  };

  # The workspace also contains fossdb-web, which only builds for wasm32 and is
  # handled by passthru.frontend.
  cargoBuildFlags = [
    "-p"
    "fossdb-server"
    "-p"
    "fossdb-cli"
    "-p"
    "fossdb-collector"
    "-p"
    "fossdb-worker"
  ];

  # `admin` gives the `fossdb` CLI its api-key and status subcommands, which
  # talk to the server over its unix socket.
  buildFeatures = [ "fossdb-cli/admin" ];

  cargoTestFlags = finalAttrs.cargoBuildFlags;

  passthru = {
    # Dioxus/wasm single-page app, served by a web server rather than by
    # fossdb-server itself.
    frontend = rustPlatform.buildRustPackage {
      pname = "${finalAttrs.pname}-web";
      inherit (finalAttrs) version src cargoDeps;

      nativeBuildInputs = [ dioxus-cli wasm-bindgen-cli binaryen ];

      buildPhase = ''
        runHook preBuild
        cd fossdb-web
        dx build --release --platform web
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        cp -r target/dx/fossdb-web/release/web/public $out
        runHook postInstall
      '';

      doCheck = false;
    };

    tests = { inherit (nixosTests) fossdb; };
  };

  meta = {
    description = "Free software database and discovery platform";
    longDescription = ''
      FossDB tracks free software packages across registries such as
      crates.io, npm and nixpkgs. It consists of three components: a server
      exposing the public API and RSS/Atom feeds, collectors that ingest
      package metadata from upstream registries, and workers that download
      and analyse releases.

      The `fossdb` command is a client for the public API and, built with the
      `admin` feature, an administrative tool that manages collector and
      worker API keys over the server's unix socket.
    '';
    homepage = "https://github.com/fossable/fossdb";
    license = lib.licenses.unlicense;
    maintainers = with lib.maintainers; [ cilki ];
    mainProgram = "fossdb";
    # The server opens a unix socket and the admin tooling assumes it; no
    # attempt has been made to support anything but Linux.
    platforms = lib.platforms.linux;
  };
})
