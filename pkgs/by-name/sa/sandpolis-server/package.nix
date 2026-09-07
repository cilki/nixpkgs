{ lib, rustPlatform, fetchFromGitHub, pkg-config, cmake, udev, openssl, mold, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "sandpolis-server";
  version = "8.0.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "sandpolis";
    rev = "d2cbb47197ab35168fc36ef72d98509934912405";
    hash = "sha256-FcqdPsBIztVxHtV401L1omVBAynrHyenSfZMLYdRF0E=";
  };

  cargoHash = "sha256-RFbhB3LS2etkaXQwcZ/HF4f9/kZKOziU0WrQGVWuW1c=";

  buildAndTestSubdir = "sandpolis";
  buildFeatures = [ "server" ];

  nativeBuildInputs = [ pkg-config cmake mold ];

  buildInputs = [ udev openssl ];

  # The test suite needs a populated database and network access.
  doCheck = false;

  # All instances are built from the same `sandpolis` crate and install a
  # binary called `sandpolis`; rename it so the three packages don't collide.
  postInstall = ''
    mv $out/bin/sandpolis $out/bin/sandpolis-server
  '';

  meta = {
    description = "Server instance for the Sandpolis virtual estate manager";
    homepage = "https://github.com/fossable/sandpolis";
    license = lib.licenses.unlicense;
    mainProgram = "sandpolis-server";
    maintainers = with lib.maintainers; [ cilki ];
    platforms = lib.platforms.linux;
  };
})
