{ lib, rustPlatform, fetchFromGitHub, pkg-config, cmake, udev, openssl, mold, }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "sandpolis-server";
  version = "8.0.0";

  src = fetchFromGitHub {
    owner = "fossable";
    repo = "sandpolis";
    rev = "0d8b7bff30a27e14a1135a4fdae9c70668db22e6";
    hash = "sha256-WE0euC49D70/qqssQbWi30j+4GUyBKRP7KjgHpC340o=";
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
