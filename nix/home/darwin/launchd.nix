{ pkgs, ... }:

{
  # Open Alacritty fullscreen with the restored session at login.
  launchd.agents.tmux-boot = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/scripts/handle_tmux_automatic_start/osx_alacritty_start_tmux.sh"
        "fullscreen"
      ];
      RunAtLoad = true;
    };
  };
}
