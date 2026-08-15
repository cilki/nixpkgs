{ lib, rustPlatform, sandpolis-server, pkg-config, mold, udev, cmake, alsa-lib
, vulkan-loader, libyuv, libvpx, libaom, libclang, libgcc, libx11, libxcursor
, libxi, libxrandr, libxkbcommon, libGL, wayland, fuse3, systemd, openssl,
# Required by rustdesk's scrap (X11 screen capture) and enigo (input)
libxcb, libxtst, xdotool,
# Required by scrap's `wayland` feature (GStreamer-based capture)
glib, dbus, gst_all_1,
# Kernel uapi headers for v4l2-sys (pulled in by scrap via nokhwa)
linuxHeaders, }:

# Every instance is built from the same `sandpolis` crate, so the source and
# vendored dependencies are shared with sandpolis-server; only the enabled
# Cargo feature differs.
rustPlatform.buildRustPackage {
  pname = "sandpolis-agent";
  inherit (sandpolis-server) version src cargoDeps;

  buildAndTestSubdir = "sandpolis";
  buildFeatures = [ "agent" ];

  nativeBuildInputs = [ pkg-config cmake mold ];

  buildInputs = [
    udev
    cmake
    alsa-lib
    vulkan-loader
    libyuv
    libvpx
    libaom
    libclang
    libgcc
    libx11
    libxcursor
    libxi
    libxrandr
    libxkbcommon
    libGL
    wayland
    fuse3
    systemd
    openssl
    # Required by rustdesk's scrap (X11 screen capture) and enigo (input)
    libxcb
    libxtst
    xdotool
    # Required by scrap's `wayland` feature (GStreamer-based capture)
    glib
    dbus
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    # Kernel uapi headers for v4l2-sys (pulled in by scrap via nokhwa)
    linuxHeaders
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
