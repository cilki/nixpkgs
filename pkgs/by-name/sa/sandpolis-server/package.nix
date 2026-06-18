{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  cmake,
  udev,
  openssl,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "sandpolis-server";
  version = "8.0.0-unstable-2026-06-17";

  src = fetchFromGitHub {
    owner = "fossable";
    repo = "sandpolis";
    rev = "993dc0dda3d046ab35784a02e8d9d9c379bc55eb";
    hash = "sha256-3ZixSPeOxR7wrFrPJ2Esj4kwep8J6Bb9T7s0ZM6I+B4=";
  };

  cargoHash = "sha256-zAwkrFlIZZOFYbIuF+XccG+BMkf65NetSpR5/s1QTXE=";

  buildAndTestSubdir = "sandpolis";
  buildFeatures = [ "server" ];

  nativeBuildInputs = [
    pkg-config
    cmake
  ];

  buildInputs = [
    udev
    openssl
  ];

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
    license = lib.licenses.agpl3Plus;
    mainProgram = "sandpolis-server";
    maintainers = with lib.maintainers; [ cilki ];
    platforms = lib.platforms.linux;
  };
})
