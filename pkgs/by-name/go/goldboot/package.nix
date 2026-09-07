{
  fetchFromGitHub,
  rustPlatform,
  lib,
  versionCheckHook,
  pkg-config,
  zstd,
  OVMF,
  qemu,
  qemu-utils,
  openssl,
  udev,
  wayland,
  wayland-protocols,
  libxkbcommon,
  libGL,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "goldboot";
  version = "0.0.10";

  src = fetchFromGitHub {
    owner = "cilki";
    repo = "goldboot";
    rev = "517db6943c13bbfcfa1a111052b805ed561bd7ac";
    hash = "sha256-iPZ6NwU9eLai1cm+z+8+xxtudEA/5anszC0OPGz2i0Q=";
  };

  cargoHash = "sha256-5D2+j9nT0IPige4hx49YnnWZMqw0MbPcD1+3DmUEI+A=";

  buildAndTestSubdir = "goldboot";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    zstd
    OVMF
    qemu
    qemu-utils
    openssl
    # libudev-sys, via block-utils
    udev
    # winit/egui Wayland backend
    wayland
    wayland-protocols
    libxkbcommon
    # glutin/glow
    libGL
  ];

  # Tests require networking, so skip them for now
  doCheck = false;

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  # The binary reports the version in Cargo.toml, which is still the last
  # release; drop this once the pin moves back to a tag.
  preVersionCheck = "export version=0.0.10";

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };

  meta = {
    mainProgram = "goldboot";
    description = "Immutable infrastructure for the desktop";
    homepage = "https://github.com/fossable/goldboot";
    license = lib.licenses.agpl3Plus;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ cilki ];
  };
})
