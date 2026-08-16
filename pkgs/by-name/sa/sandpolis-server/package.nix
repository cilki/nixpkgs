{ lib, rustPlatform, fetchFromGitHub, pkg-config, cmake, udev, openssl, mold, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "sandpolis-server";
  version = "8.0.0-unstable-2026-08-15";

  src = fetchFromGitHub {
    owner = "fossable";
    repo = "sandpolis";
    rev = "1dd5dead744250dc986fee5e233f821d7f86f1ef";
    hash = "sha256-jpiieKH85ONwKE6J1F1cw4j6DEJUCaGc44mCeSIoaF4=";
  };

  cargoHash = "sha256-mtQiv2+FLty9McMI4txqQgHm3L8e5LUryoiiuj0Hj3c=";

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
