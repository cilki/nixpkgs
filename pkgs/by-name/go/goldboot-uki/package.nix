{
  stdenvNoCC,
  fetchurl,
  lib,
  nix-update-script,
}:

let
  arch =
    {
      x86_64-linux = "x86_64";
      aarch64-linux = "aarch64";
    }
    .${stdenvNoCC.hostPlatform.system} or (throw "goldboot-uki: unsupported system");

  hashes = {
    x86_64-linux = lib.fakeHash;
    aarch64-linux = lib.fakeHash;
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "goldboot-uki";
  version = "0.0.10";

  src = fetchurl {
    url = "https://github.com/fossable/goldboot/releases/download/goldboot-v${finalAttrs.version}/goldboot-uki-${arch}.efi";
    hash = hashes.${stdenvNoCC.hostPlatform.system};
  };

  dontUnpack = true;

  # Intentionally not installed to $out/bin: the UKI is a bootable EFI
  # image consumed by the goldboot CLI (which looks for it at
  # /var/lib/goldboot/goldboot.efi), not a host executable.
  installPhase = ''
    runHook preInstall
    install -Dm444 $src $out/goldboot.efi
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Unified kernel image for deploying goldboot images to bare metal";
    homepage = "https://github.com/fossable/goldboot";
    changelog = "https://github.com/fossable/goldboot/releases/tag/goldboot-v${finalAttrs.version}";
    license = lib.licenses.agpl3Plus;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    maintainers = with lib.maintainers; [ cilki ];
  };
})
