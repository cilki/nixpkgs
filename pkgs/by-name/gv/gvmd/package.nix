{
  lib,
  stdenv,
  cjson,
  cmake,
  fetchFromGitHub,
  glib,
  gnutls,
  gpgme,
  gvm-libs,
  libbsd,
  libical,
  libxslt,
  pkg-config,
  postgresql,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gvmd";
  version = "26.31.1";

  src = fetchFromGitHub {
    owner = "greenbone";
    repo = "gvmd";
    tag = "v${finalAttrs.version}";
    hash = "sha256-5s9IWe9tPZcvzbMkgIxKwHHrfgivWFUhO5/aB+gQJGg=";
  };

  postPatch = ''
    # nixpkgs installs the libpq headers directly under include/
    substituteInPlace src/sql_pg.c --replace-fail "postgresql/libpq-fe.h" "libpq-fe.h"
  '';

  nativeBuildInputs = [
    cmake
    libxslt
    pkg-config
    postgresql
  ];

  buildInputs = [
    cjson
    glib
    gnutls
    gpgme
    gvm-libs
    libbsd
    libical
    postgresql
  ];

  cmakeFlags = [
    "-DGVM_RUN_DIR=${placeholder "out"}/run/gvm"
    "-DGVMD_RUN_DIR=${placeholder "out"}/run/gvmd"
    "-DOPENVAS_DEFAULT_SOCKET=/run/ospd/ospd-openvas.sock"
    "-DLOCALSTATEDIR=${placeholder "out"}/var"
    "-DSYSCONFDIR=${placeholder "out"}/etc"
  ];

  meta = {
    description = "Manager daemon of the Greenbone Vulnerability Management Solution";
    homepage = "https://github.com/greenbone/gvmd";
    changelog = "https://github.com/greenbone/gvmd/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.agpl3Plus;
    maintainers = [ ];
    mainProgram = "gvmd";
    platforms = lib.platforms.linux;
  };
})
