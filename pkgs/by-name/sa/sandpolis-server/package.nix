{ lib, rustPlatform, fetchFromGitHub, pkg-config, cmake, udev, openssl, mold, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "sandpolis-server";
  version = "8.0.0";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "sandpolis";
    rev = "7d0fa3d23fde43d968c58d541deaebd32997a8ac";
    hash = "sha256-tBQ6MfgYPR9naYB/vnzcsIqqYfN5i5VTwG5kZXbvKKQ=";
  };

  cargoHash = "sha256-DK5UjgR9lQfhscaaDXdR70VCRamY7U1Yw3DAJsnPCXQ=";

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
