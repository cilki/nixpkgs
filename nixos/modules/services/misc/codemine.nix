{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.codemine;
in
{
  options.services.codemine = {
    enable = lib.mkEnableOption "codemine, an unattended agent runner sweeping your repositories";

    package = lib.mkPackageOption pkgs "codemine" { } // {
      description = "The codemine package to use; ignored when {option}`services.codemine.image` is set.";
    };

    image = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      example = "ghcr.io/cilki/codemine:latest";
      description = ''
        Container image to run codemine in via
        {option}`virtualisation.oci-containers.containers`. Codemine must
        already be installed in the image. When null (the default), codemine
        runs natively as a systemd service using
        {option}`services.codemine.package`.
      '';
    };

    listen = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0:8080";
      description = ''
        Bind address for the web UI (`--listen`), where all runtime
        configuration happens and is persisted into the workspace. Ignored
        when {option}`services.codemine.image` is set: the containerized
        codemine binds its own default inside the container, so publish it
        with the container's `ports` instead.
      '';
    };

    extraPackages = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.nodejs ]";
      description = ''
        Extra packages available to the agent at runtime; ignored when
        {option}`services.codemine.image` is set.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf (cfg.image == null) {
        systemd.services.codemine = {
          description = "codemine agent runner";
          wantedBy = [ "multi-user.target" ];
          wants = [
            "network-online.target"
          ]
          ++ lib.optional (config.services ? cliproxyapi && config.services.cliproxyapi.enable) "cliproxyapi.service";
          after = [
            "network-online.target"
          ]
          ++ lib.optional (config.services ? cliproxyapi && config.services.cliproxyapi.enable) "cliproxyapi.service";

          # codemine runs `git config --system`, which would otherwise try to
          # write to the read-only nix store (or clobber /etc/gitconfig).
          environment.GIT_CONFIG_SYSTEM = "/var/lib/codemine/gitconfig";

          # Mirrors the tool set of the project's Docker image (nix/runtime.nix).
          path =
            (with pkgs; [
              bash
              coreutils
              gnugrep
              gnused
              findutils
              git
              jq
              curl
              ripgrep
              util-linux
              tea
              gh
              glab
              opencode
              codegraph
              cargo
              rustc
              clippy
              rustfmt
              gnumake
            ])
            ++ cfg.extraPackages;

          serviceConfig = {
            ExecStart = "${lib.getExe cfg.package} --listen ${cfg.listen} --workspace /var/lib/codemine";
            WorkingDirectory = "/root";
            StateDirectory = "codemine";
            Restart = "always";
            RestartSec = 60;
          };
        };
      })

      (lib.mkIf (cfg.image != null) {
        virtualisation.oci-containers.containers.codemine.image = cfg.image;
      })
    ]
  );

  meta.maintainers = with lib.maintainers; [ cilki ];
}
