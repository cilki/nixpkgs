{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.codemine;

  environment =
    lib.filterAttrs (_: v: v != null) {
      CODEMINE_MODEL = cfg.model;
      CODEMINE_COMMAND = cfg.command;
      CODEMINE_TASKS = if cfg.tasks == [ ] then null else lib.concatStringsSep " " cfg.tasks;
      CODEMINE_DAILY_LIMIT = lib.mapNullable toString cfg.dailyLimit;
      CODEMINE_TIMEOUT = lib.mapNullable toString cfg.timeout;
      CODEMINE_NICE = lib.mapNullable toString cfg.nice;
      CODEMINE_IONICE = cfg.ionice;
      CODEMINE_WEBUI = cfg.webui;
      GIT_AUTHOR_NAME = cfg.gitAuthorName;
      GIT_AUTHOR_EMAIL = cfg.gitAuthorEmail;
      GITEA_USER = cfg.gitea.user;
      GITEA_URL = cfg.gitea.url;
      GITHUB_URL = cfg.github.url;
      GITLAB_URL = cfg.gitlab.url;
      # codemine runs `git config --system`, which would otherwise try to
      # write to the read-only nix store (or clobber /etc/gitconfig).
      GIT_CONFIG_SYSTEM = "/var/lib/codemine/gitconfig";
    }
    // cfg.extraEnvironment;
in
{
  options.services.codemine = {
    enable = lib.mkEnableOption "codemine, an unattended agent runner sweeping your repositories";

    package = lib.mkPackageOption pkgs "codemine" { };

    model = lib.mkOption {
      type = lib.types.str;
      example = "anthropic/claude-sonnet-5";
      description = "Model to run turns with, as provider/model (`CODEMINE_MODEL`).";
    };

    command = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = "The opencode command to run each turn (`CODEMINE_COMMAND`, default `sweep`).";
    };

    tasks = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      example = [
        "feedback"
        "bump-deps"
      ];
      description = "Task pool the runner draws from (`CODEMINE_TASKS`); empty means all tasks.";
    };

    dailyLimit = lib.mkOption {
      type = with lib.types; nullOr ints.unsigned;
      default = null;
      description = "Maximum completed tasks per local day (`CODEMINE_DAILY_LIMIT`); null is unlimited.";
    };

    timeout = lib.mkOption {
      type = with lib.types; nullOr ints.unsigned;
      default = null;
      description = "Seconds before a turn is cut off (`CODEMINE_TIMEOUT`, default 21600).";
    };

    nice = lib.mkOption {
      type = with lib.types; nullOr (ints.between 1 19);
      default = null;
      description = "CPU niceness applied to the agent process tree (`CODEMINE_NICE`).";
    };

    ionice = lib.mkOption {
      type =
        with lib.types;
        nullOr (enum [
          "best-effort"
          "idle"
        ]);
      default = null;
      description = "I/O scheduling class applied to the agent process tree (`CODEMINE_IONICE`).";
    };

    webui = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      example = "0.0.0.0:8080";
      description = "Bind address for the read-only status web UI (`CODEMINE_WEBUI`); null disables it.";
    };

    gitAuthorName = lib.mkOption {
      type = lib.types.str;
      description = "Name commits are authored and committed as (`GIT_AUTHOR_NAME`).";
    };

    gitAuthorEmail = lib.mkOption {
      type = lib.types.str;
      description = "Email commits are authored and committed as (`GIT_AUTHOR_EMAIL`).";
    };

    gitea = {
      user = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = "The bot account's Gitea username (`GITEA_USER`).";
      };

      url = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        example = "https://git.example.com";
        description = "Gitea base URL (`GITEA_URL`).";
      };
    };

    github.url = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = "GitHub base URL (`GITHUB_URL`, default `https://github.com`).";
    };

    gitlab.url = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = "GitLab base URL (`GITLAB_URL`, default `https://gitlab.com`).";
    };

    environmentFiles = lib.mkOption {
      type = with lib.types; listOf path;
      default = [ ];
      example = [ "/run/secrets/codemine" ];
      description = ''
        Environment files (systemd `EnvironmentFile` format) holding the
        secret variables: the forge tokens (`GITEA_TOKEN`, `GITHUB_TOKEN`,
        `GITLAB_TOKEN`), of which at least one must be set. Keeping them here
        rather than in {option}`services.codemine.extraEnvironment` keeps
        them out of the nix store.
      '';
    };

    extraEnvironment = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = { };
      example = {
        GH_HOST = "github.example.com";
      };
      description = "Extra environment variables passed to the runner and the agent.";
    };

    extraPackages = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.nodejs ]";
      description = "Extra packages available to the agent at runtime.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.codemine = {
      description = "codemine agent runner";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      inherit environment;

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
          cargo
          rustc
          clippy
          rustfmt
          gnumake
        ])
        ++ cfg.extraPackages;

      # Load the Claude OAuth plugin from the nix store so opencode never has
      # to fetch it from npm at startup.
      preStart = ''
        pkg=${pkgs.opencode-claude-auth}/lib/node_modules/opencode-claude-auth
        main=$(${lib.getExe pkgs.jq} -r '.main // "index.js"' "$pkg/package.json")
        mkdir -p /root/.config/opencode/plugins
        ln -sf "$pkg/$main" /root/.config/opencode/plugins/opencode-claude-auth.js
      '';

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        EnvironmentFile = cfg.environmentFiles;
        # codemine expects to run as root: it validates the Claude OAuth
        # credentials at /root/.claude/.credentials.json and creates its
        # workspaces under /root.
        WorkingDirectory = "/root";
        StateDirectory = "codemine";
        Restart = "always";
        RestartSec = 60;
      };
    };
  };

  meta.maintainers = with lib.maintainers; [ cilki ];
}
