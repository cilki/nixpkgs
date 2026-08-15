{ lib, rustPlatform, sandpolis-server, pkg-config, cmake, udev, openssl
, alsa-lib, fontconfig, freetype, libxkbcommon, vulkan-loader, wayland, fuse3
, libx11, libxcursor, libxi, libxrandr, mold, }:

let
  # Libraries Bevy loads at runtime via dlopen, which therefore have to be
  # reachable through the binary's rpath.
  runtimeLibs =
    [ vulkan-loader wayland libxkbcommon libx11 libxcursor libxi libxrandr ];
  # Every instance is built from the same `sandpolis` crate, so the source and
  # vendored dependencies are shared with sandpolis-server; the client enables the
  # Bevy-based GUI.
in rustPlatform.buildRustPackage {
  pname = "sandpolis-client";
  inherit (sandpolis-server) version src cargoDeps;

  buildAndTestSubdir = "sandpolis";
  buildFeatures = [ "client" ];

  nativeBuildInputs = [ pkg-config cmake rustPlatform.bindgenHook mold ];

  buildInputs = [ udev openssl alsa-lib fontconfig freetype fuse3 libxkbcommon ]
    ++ runtimeLibs;

  doCheck = false;

  postInstall = ''
    mv $out/bin/sandpolis $out/bin/sandpolis-client
    patchelf --add-rpath ${
      lib.makeLibraryPath runtimeLibs
    } $out/bin/sandpolis-client
  '';

  meta = {
    description = "Client instance for the Sandpolis virtual estate manager";
    homepage = "https://github.com/fossable/sandpolis";
    license = lib.licenses.agpl3Plus;
    mainProgram = "sandpolis-client";
    maintainers = with lib.maintainers; [ cilki ];
    platforms = lib.platforms.linux;
  };
}
