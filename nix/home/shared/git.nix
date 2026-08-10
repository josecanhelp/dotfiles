{ ... }:

{
  programs.git = {
    enable = true;
    # Generates the entire [filter "lfs"] block.
    lfs.enable = true;
    # Writes ~/.config/git/ignore, which git reads via XDG. This replaces
    # ~/.gitignore_global, which was never tracked in this repo and would
    # be missing on a new machine. core.excludesfile is dropped, not
    # repointed, because it hardcoded /Users/jose.
    ignores = [
      ".DS_Store"
      ".vscode/*"
      ".secrets"
      "CLAUDE.md"
      "scratch*.md"
      "**/.claude/settings.local.json"
    ];
    # `settings` is the current option. userName, userEmail and extraConfig
    # were renamed into it; the compatibility shims still work but emit a
    # deprecation trace on every rebuild.
    settings = {
      user = {
        name = "Jose Soto";
        email = "josecanhelp@gmail.com";
      };
      github.user = "josecanhelp";
      init.defaultBranch = "main";
      pull.rebase = false;
      color.ui = "auto";
      status.short = true;
      help.autocorrect = 1;
      core.editor = "vim";
      credential.helper = "osxkeychain";
      mergetool = {
        prompt = false;
        keepBackup = false;
      };
      # Percent signs are literal in Nix, but keep this on one line so the
      # colour codes are not broken by wrapping.
      format.pretty = "format:%Cblue%h%Creset %Creset%Cgreen%cn, %cr%Creset : %s%Creset%C(red)%d%Creset";
    };
  };
}
