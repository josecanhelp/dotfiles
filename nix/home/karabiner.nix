{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  xdg.configFile = {
    # Linked to both paths because goku searches both. Dropping either one
    # silently stops the .edn from compiling to karabiner.json.
    "karabiner.edn".source = link "karabiner/karabiner.edn";
    "karabiner/karabiner.edn".source = link "karabiner/karabiner.edn";
  };

  # Recompile karabiner.edn to karabiner.json on save.
  #
  # This deliberately does NOT call goku's own `gokuw` wrapper. gokuw is a
  # two-line shell script that runs `watchexec` and `goku` by bare name, and
  # that bare-name lookup is exactly what broke: the Homebrew LaunchAgent it
  # shipped with handed the job a PATH containing neither binary, so the
  # watcher ran for days unable to compile anything while still showing a
  # live PID. Absolute store paths make that failure mode impossible.
  launchd.agents.goku = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.watchexec}/bin/watchexec"
        "-r"
        "-e"
        "edn"
        "-w"
        "${config.home.homeDirectory}/.config/karabiner.edn"
        "${pkgs.goku}/bin/goku"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/goku.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/goku.log";
    };
  };
}
