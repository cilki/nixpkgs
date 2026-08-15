{ lib, rustPlatform, sandpolis-server, pkg-config, cmake, makeBinaryWrapper
, udev, openssl, alsa-lib, fontconfig, freetype, libxkbcommon, vulkan-loader
, wayland, fuse3, libx11, libxcursor, libxi, libxrandr, libGL, mold, }:

let
  # Libraries Bevy (winit / wgpu) loads at runtime via dlopen. They can't be
  # added to the binary's rpath because the patchelf setup hook shrinks away
  # rpath entries that no DT_NEEDED entry refers to, so hand them to the binary
  # through LD_LIBRARY_PATH instead.
  runtimeLibs = [
    vulkan-loader
    wayland
    libxkbcommon
    libx11
    libxcursor
    libxi
    libxrandr
    libGL
  ];
  # Every instance is built from the same `sandpolis` crate, so the source and
  # vendored dependencies are shared with sandpolis-server; the client enables the
  # Bevy-based GUI.
in rustPlatform.buildRustPackage {
  pname = "sandpolis-client";
  inherit (sandpolis-server) version src cargoDeps;

  buildAndTestSubdir = "sandpolis";
  buildFeatures = [ "client" ];

  nativeBuildInputs =
    [ pkg-config cmake rustPlatform.bindgenHook makeBinaryWrapper mold ];

  buildInputs = [ udev openssl alsa-lib fontconfig freetype fuse3 libxkbcommon ]
    ++ runtimeLibs;

  doCheck = false;

  postInstall = ''
    wrapProgram $out/bin/sandpolis \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}
  '';

  meta = {
    description = "Client instance for the Sandpolis virtual estate manager";
    homepage = "https://github.com/fossable/sandpolis";
    license = lib.licenses.unlicense;
    mainProgram = "sandpolis";
    maintainers = with lib.maintainers; [ cilki ];
    platforms = lib.platforms.linux;
  };
}
