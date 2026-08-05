{
  lib,
  stdenvNoCC,
  runCommand,
  writeText,
  goldboot,
  makeInitrd,
  makeModulesClosure,
  linuxPackages_latest,
  linux-firmware,
  systemdUkify,
  busybox,
  cage,
  wlroots_0_20,
  eudev,
  libinput,
  kmod,
  iproute2,
  mesa,
  wayland,
  libxkbcommon,
  libGL,
  xz,
  zstd,
}:

let
  kernel = linuxPackages_latest.kernel;

  # The UKI runs the fullscreen GUI and reboots when it exits; the "cli" and
  # "uki" cargo features are mutually exclusive upstream.
  goldbootUki = goldboot.overrideAttrs (_: {
    pname = "goldboot-uki-bin";
    buildAndTestSubdir = null;
    cargoBuildFlags = [
      "-p"
      "goldboot"
      "--no-default-features"
      "--features"
      "uki"
    ];
    WINIT_UNIX_BACKEND = "wayland";
    # There is no CLI to ask for --version
    doInstallCheck = false;
  });

  # The initramfs boots straight into a kiosk compositor, so neither X11 nor
  # XWayland is ever used; dropping them keeps them out of the image.
  cageNoXwayland = cage.override {
    wlroots_0_20 = wlroots_0_20.override { enableXWayland = false; };
    xwayland = null;
  };

  # Copied out of the source tree rather than referenced in place: makeInitrd
  # copies the whole store path of every object into the image, and that would
  # pull in all of goldboot's sources.
  ukiScripts = runCommand "goldboot-uki-scripts" { } ''
    install -Dm755 ${goldbootUki.src}/goldboot/uki/init $out/init
    install -Dm755 ${goldbootUki.src}/goldboot/uki/goldboot-launch $out/goldboot-launch
    install -Dm755 ${goldbootUki.src}/goldboot/uki/udhcpc.script $out/udhcpc.script
  '';

  # eudev looks for rules in /etc/udev/rules.d, not /lib/udev/rules.d
  udevRules = runCommand "goldboot-uki-udev-rules" { } ''
    mkdir -p $out/rules.d
    cp ${eudev}/var/lib/udev/rules.d/*.rules $out/rules.d/

    # libinput's rules refer to its helpers by absolute store path, which is
    # not where they live inside the initramfs
    for rule in ${libinput.out}/lib/udev/rules.d/*.rules; do
      sed 's|${libinput.out}/lib/udev/|/lib/udev/libinput/|g' "$rule" > "$out/rules.d/$(basename "$rule")"
    done
  '';

  modulesClosure = makeModulesClosure {
    kernel = linuxPackages_latest.kernel.modules;
    firmware = linux-firmware;
    allowMissing = false;
    rootModules = [
      # Virtual hardware
      "virtio_gpu"
      "virtio_pci"
      "virtio_input"
      "virtio_net"
      "virtio_blk"
      # Graphics
      "drm"
      "drm_kms_helper"
      # Input
      "evdev"
      "hid"
      "usbhid"
      "hid_generic"
      "ehci_pci"
      "xhci_pci"
      # Networking (af_packet is required by udhcpc's raw socket)
      "af_packet"
      "r8169"
      "r8152"
      "8139cp"
      "e1000"
      "e1000e"
      "igb"
      "igc"
      "tg3"
      "bnxt_en"
      # Storage
      "ahci"
      "sd_mod"
      "nvme"
      "usb_storage"
      # Filesystems
      "vfat"
      "ext4"
      "btrfs"
      "xfs"
      "ntfs3"
      "iso9660"
      "nls_cp437"
      "nls_iso8859_1"
      # EFI variables, for Boot####/BootNext chain-loading
      "efivarfs"
    ]
    ++ lib.optionals stdenvNoCC.hostPlatform.isx86 [
      # PS/2 keyboards (most laptop integrated keyboards)
      "i8042"
      "atkbd"
      # I2C HID (newer laptops)
      "i2c_hid"
      "i2c_hid_acpi"
    ];
  };

  initrd = makeInitrd {
    name = "goldboot-initramfs";

    compressor = "${zstd}/bin/zstd --ultra -22";

    contents = [
      {
        object = "${ukiScripts}/init";
        symlink = "/init";
        mode = "0755";
      }
      {
        object = "${ukiScripts}/goldboot-launch";
        symlink = "/sbin/goldboot-launch";
        mode = "0755";
      }
      {
        object = "${ukiScripts}/udhcpc.script";
        symlink = "/etc/udhcpc.script";
        mode = "0755";
      }
      {
        object = lib.getExe goldbootUki;
        symlink = "/sbin/goldboot";
        mode = "0755";
      }
      {
        object = "${busybox}/bin/busybox";
        symlink = "/bin/busybox";
        mode = "0755";
      }
      {
        object = "${cageNoXwayland}/bin/cage";
        symlink = "/sbin/cage";
        mode = "0755";
      }
      {
        object = "${iproute2}/bin/ip";
        symlink = "/bin/ip";
      }
      {
        object = "${kmod}/bin/kmod";
        symlink = "/bin/kmod";
        mode = "0755";
      }
      {
        object = "${kmod}/bin/kmod";
        symlink = "/bin/modprobe";
        mode = "0755";
      }
      {
        object = "${kmod}/bin/kmod";
        symlink = "/bin/insmod";
        mode = "0755";
      }
      {
        object = "${xz}/lib";
        symlink = "/lib/xz";
      }
      {
        object = mesa;
        symlink = "/run/opengl-driver";
      }
      {
        object = "${modulesClosure}/lib/modules";
        symlink = "/lib/modules";
      }
      # winit and glutin dlopen these, so they are not in the binary's RUNPATH
      {
        object = "${wayland}/lib";
        symlink = "/lib/wayland";
      }
      {
        object = "${libxkbcommon}/lib";
        symlink = "/lib/xkbcommon";
      }
      {
        object = "${libGL}/lib";
        symlink = "/lib/libgl";
      }
      # eudev assigns the device properties libinput needs
      {
        object = "${eudev}/bin/udevd";
        symlink = "/sbin/udevd";
      }
      {
        object = "${eudev}/bin/udevadm";
        symlink = "/sbin/udevadm";
      }
      {
        object = "${eudev}/var/lib/udev/hwdb.d";
        symlink = "/lib/udev/hwdb.d";
      }
      {
        object = "${udevRules}/rules.d";
        symlink = "/etc/udev/rules.d";
      }
      {
        object = "${eudev}/lib/udev/ata_id";
        symlink = "/lib/udev/ata_id";
      }
      {
        object = "${eudev}/lib/udev/scsi_id";
        symlink = "/lib/udev/scsi_id";
      }
      {
        object = "${eudev}/lib/udev/mtd_probe";
        symlink = "/lib/udev/mtd_probe";
      }
      {
        object = "${libinput.out}/lib";
        symlink = "/lib/libinput";
      }
      {
        object = "${libinput.out}/lib/udev/libinput-device-group";
        symlink = "/lib/udev/libinput/libinput-device-group";
      }
      {
        object = "${libinput.out}/lib/udev/libinput-fuzz-extract";
        symlink = "/lib/udev/libinput/libinput-fuzz-extract";
      }
      {
        object = "${libinput.out}/lib/udev/libinput-fuzz-to-zero";
        symlink = "/lib/udev/libinput/libinput-fuzz-to-zero";
      }
    ];
  };

  osRelease = writeText "goldboot-os-release" ''
    NAME="Goldboot"
    ID=goldboot
    VERSION="${goldboot.version}"
  '';
in
stdenvNoCC.mkDerivation {
  pname = "goldboot-uki";
  inherit (goldboot) version;

  nativeBuildInputs = [ systemdUkify ];

  # Intentionally not installed to $out/bin: the UKI is a bootable EFI image
  # consumed by the goldboot CLI (which looks for it at
  # /var/lib/goldboot/goldboot.efi), not a host executable.
  buildCommand = ''
    mkdir -p $out
    ukify build \
      --linux=${kernel}/${stdenvNoCC.hostPlatform.linux-kernel.target} \
      --initrd=${initrd}/initrd \
      --os-release=@${osRelease} \
      --cmdline="quiet loglevel=0 rd.systemd.show_status=false rd.udev.log_level=0 vt.global_cursor_default=0" \
      --output=$out/goldboot.efi
  '';

  passthru = {
    inherit initrd;
    goldboot = goldbootUki;
  };

  meta = {
    description = "Unified kernel image for deploying goldboot images to bare metal";
    longDescription = ''
      A bootable EFI image pairing the Linux kernel with an initramfs that runs
      the goldboot deployment UI, for writing goldboot images to bare metal.
      The goldboot CLI embeds it as a chain-loader when building multiboot
      images, and it can also be booted directly from an EFI system partition.
    '';
    homepage = "https://github.com/fossable/goldboot";
    # The image bundles the Linux kernel and busybox alongside goldboot
    license = with lib.licenses; [
      agpl3Plus
      gpl2Only
    ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    maintainers = with lib.maintainers; [ cilki ];
  };
}
