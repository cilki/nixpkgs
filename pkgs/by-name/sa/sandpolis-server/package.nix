{ lib, rustPlatform, fetchFromGitHub, pkg-config, cmake, udev, openssl, mold, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "sandpolis-server";
  version = "8.0.0";

  src = fetchFromGitHub {
    owner = "fossable";
    repo = "sandpolis";
    rev = "23bbf8660cee9a8e38709d98d853c22202da544d";
    hash = "sha256-Y+lgjOUdR1uVJClzSSNwQAeBGEHbxys739dDjoZ+H3Y=";
  };

  cargoHash = "sha256-euz0poG3snDwne4L7ndMbAmgTYmyi4YWPOufu8A0/WU=";

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
