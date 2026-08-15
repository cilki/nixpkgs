{ lib, rustPlatform, fetchFromGitHub, pkg-config, cmake, udev, openssl, mold, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "sandpolis-server";
  version = "8.0.0-unstable-2026-08-15";

  src = fetchFromGitHub {
    owner = "fossable";
    repo = "sandpolis";
    rev = "40cd0a6a3aa1d8ee0e011fc47ff27bae4676d284";
    hash = "sha256-duVIwsf8t/FUuIhpk6DSTy/ZIh+dpjTDIGQS8a39ST0=";
  };

  cargoHash = "sha256-y9S7/HodGPLLpiBcDvhLfNnFTcazf9AUrsdd9/+oA20=";

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
