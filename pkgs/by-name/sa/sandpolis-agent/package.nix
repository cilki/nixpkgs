{ lib, stdenv, rustPlatform, sandpolis-server, pkg-config, mold, udev, cmake
, alsa-lib, vulkan-loader, libyuv, libvpx, libaom, libclang, libgcc, libx11
, libxcursor, libxi, libxrandr, libxkbcommon, libGL, wayland, fuse3, systemd
, openssl,
# Required by rustdesk's scrap (X11 screen capture) and enigo (input)
libxcb, libxtst, xdotool,
# Required by scrap's `wayland` feature (GStreamer-based capture)
glib, dbus, gst_all_1,
# Kernel uapi headers for v4l2-sys (pulled in by scrap via nokhwa)
linuxHeaders,
# Required by the boot agent's slint UI (linuxkms backend)
fontconfig, libinput,
# Required to assemble the boot agent's unified kernel image
busybox, linuxPackages_latest, makeInitrd, systemdUkify, }:

# Every instance is built from the same `sandpolis` crate, so the source and
# vendored dependencies are shared with sandpolis-server; only the enabled
# Cargo feature differs.
rustPlatform.buildRustPackage (finalAttrs: {
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

  # The boot agent: the same crate built with the `uki` feature and packed
  # into a unified kernel image that runs before the OS. It shows a fullscreen
  # chainloader UI, answers cold snapshot streams, and boots the real OS by
  # setting the UEFI `BootNext` variable.
  passthru.efi = let
    boot-agent = finalAttrs.finalPackage.overrideAttrs (prev: {
      pname = "sandpolis-boot-agent";
      cargoBuildNoDefaultFeatures = true;
      cargoBuildFeatures = [ "uki" "snapshot" "inventory" ];
      # The slint UI draws straight to the display via the linuxkms backend
      buildInputs = prev.buildInputs ++ [ fontconfig libinput ];
      # Only one instance lives in the image, so no rename is needed
      postInstall = "";
    });

    # The init script comes from the source tree (sandpolis/uki/) so it can
    # evolve with the agent; makeInitrd includes the closure of everything
    # listed, which is what makes the dynamically linked binary work.
    initramfs = makeInitrd {
      name = "sandpolis-initramfs";
      compressor = "gzip";
      contents = [
        {
          object = "${finalAttrs.src}/sandpolis/uki/init.sh";
          symlink = "/init";
        }
        {
          object = "${boot-agent}/bin/sandpolis";
          symlink = "/sbin/sandpolis";
        }
        {
          object = "${busybox}/bin/busybox";
          symlink = "/bin/busybox";
        }
      ];
    };

    kernel = linuxPackages_latest.kernel;
  in stdenv.mkDerivation {
    pname = "sandpolis-uki";
    inherit (finalAttrs) version;

    nativeBuildInputs = [ systemdUkify ];

    buildCommand = ''
      mkdir -p $out

      cat > os-release <<EOF
      NAME="Sandpolis"
      ID=sandpolis
      VERSION="${finalAttrs.version}"
      EOF

      ukify build \
        --linux=${kernel}/${kernel.target} \
        --initrd=${initramfs}/initrd \
        --os-release=@os-release \
        --cmdline="console=ttyS0 console=tty0 quiet" \
        --output=$out/sandpolis.efi
    '';
  };

  meta = {
    description = "Agent instance for the Sandpolis virtual estate manager";
    homepage = "https://github.com/fossable/sandpolis";
    license = lib.licenses.unlicense;
    mainProgram = "sandpolis-agent";
    maintainers = with lib.maintainers; [ cilki ];
    platforms = lib.platforms.linux;
  };
})
