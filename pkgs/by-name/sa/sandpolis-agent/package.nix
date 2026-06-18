{
  lib,
  rustPlatform,
  sandpolis-server,
  pkg-config,
  cmake,
  udev,
  openssl,
}:

# Every instance is built from the same `sandpolis` crate, so the source and
# vendored dependencies are shared with sandpolis-server; only the enabled
# Cargo feature differs.
rustPlatform.buildRustPackage {
  pname = "sandpolis-agent";
  inherit (sandpolis-server) version src cargoDeps;

  buildAndTestSubdir = "sandpolis";
  buildFeatures = [ "agent" ];

  nativeBuildInputs = [
    pkg-config
    cmake
  ];

  buildInputs = [
    udev
    openssl
  ];

  doCheck = false;

  postInstall = ''
    mv $out/bin/sandpolis $out/bin/sandpolis-agent
  '';

  meta = {
    description = "Agent instance for the Sandpolis virtual estate manager";
    homepage = "https://github.com/fossable/sandpolis";
    license = lib.licenses.agpl3Plus;
    mainProgram = "sandpolis-agent";
    maintainers = with lib.maintainers; [ cilki ];
    platforms = lib.platforms.linux;
  };
}
