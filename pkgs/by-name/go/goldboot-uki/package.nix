# The UKI build logic lives in the goldboot source tree
# (goldboot/uki/package.nix), not here. This imports it out of the fetched
# goldboot source. Upstream nixpkgs forbids this (it is import-from-derivation),
# but this branch is private.
{
  goldboot,
  callPackage,
}:
callPackage "${goldboot.src}/goldboot/uki/package.nix" { }
