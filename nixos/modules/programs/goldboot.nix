{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.goldboot;
in
{
  options.programs.goldboot = {
    enable = lib.mkEnableOption "goldboot, immutable infrastructure for bare metal";

    package = lib.mkPackageOption pkgs "goldboot" { };

    uki = {
      enable = lib.mkEnableOption ''
        installing the goldboot unified kernel image to
        {file}`/var/lib/goldboot/goldboot.efi`, where `goldboot build`
        looks for it when embedding a chain-loader into multiboot images
      '';

      package = lib.mkPackageOption pkgs "goldboot-uki" { };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.tmpfiles.settings."10-goldboot" = lib.mkIf cfg.uki.enable {
      "/var/lib/goldboot".d = { };
      "/var/lib/goldboot/goldboot.efi"."L+".argument = "${cfg.uki.package}/goldboot.efi";
    };
  };

  meta.maintainers = with lib.maintainers; [ cilki ];
}
