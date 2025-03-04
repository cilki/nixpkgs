{ fetchFromGitHub, rustPlatform, pkgs, lib }:

rustPlatform.buildRustPackage rec {
  pname = "sandpolis-client";
  version = "8.0.0";

  meta = with lib; {
    mainProgram = "sandpolis-client";
    description = "Ultimate virtual estate monitoring and management!";
    homepage = "https://github.com/fossable/sandpolis";
    license = licenses.agpl3Plus;
    sourceProvenance = with sourceTypes; [ fromSource ];
    platforms = platforms.unix;
    maintainers = with maintainers; [ cilki ];
  };
  nativeBuildInputs = with pkgs; [ pkg-config ];
  buildInputs = with pkgs; [
    udev
    cmake
    alsa-lib
    vulkan-loader
    libyuv
    libvpx
    libclang
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
    libxkbcommon
    wayland
    fuse3
    systemd
    openssl
  ];

  src = fetchFromGitHub {
    owner = "fossable";
    repo = "sandpolis";
    rev = "sandpolis-${version}";
    hash = "sha256-bSxYwQfAEOs/kXvIvsbacZS++kyrTuXpoYBNUy360w4=";
  };

  buildAndTestSubdir = "sandpolis";
  buildFeatures = [ "agent" ];

  useFetchCargoVendor = true;
  cargoHash = "sha256-ELO9Hz8wUX1Fxpu3otahIgfvuSsJaQADnZCLrcEWiyQ=";

  passthru.updateScript = ./update.sh;
}
