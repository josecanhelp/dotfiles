{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;

    # These replace hand-written settings in shell.nix: EDITOR in
    # sessionVariables and the `vim` shellAlias. Step 5 removes those, or
    # there would be two sources of truth for the same thing.
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      gruvbox-nvim

      # Grammars come from nixpkgs, so nothing compiles at runtime and
      # :TSInstall is never needed. Chosen for what this editor actually
      # opens: git's editor buffers, this dotfiles repo, karabiner.edn.
      # The web stack is deliberately excluded; that is IDE territory.
      #
      # Note on how this works: withPlugins does NOT copy parsers into the
      # nvim-treesitter output. It attaches each grammar as a separate
      # `dependencies` entry (vimplugin-nvim-treesitter-grammar-nix and a
      # matching -queries-nix), which the neovim wrapper resolves onto the
      # runtime path. Inspecting the nvim-treesitter store path alone shows
      # an empty parser directory; that is expected, not a failure. Verify
      # grammars with vim.treesitter.language.add() inside nvim instead.
      (nvim-treesitter.withPlugins (g: with g; [
        bash
        clojure          # karabiner/karabiner.edn is EDN
        diff
        git_rebase
        gitcommit        # nvim is $EDITOR, so this is its most frequent job
        json
        lua
        markdown
        markdown_inline
        nix
        php
        query
        toml
        vim
        vimdoc
        yaml
      ]))

      telescope-nvim
      plenary-nvim
      telescope-fzf-native-nvim

      vim-surround
      vim-commentary

      # Required, not optional. The tmux config's inline is_vim snippet
      # sends C-h/j/k/l into nvim when nvim is focused, expecting the nvim
      # side to handle pane switching. Without this those keys do nothing.
      vim-tmux-navigator

      guess-indent-nvim
    ];

    # initLua, not extraLuaConfig. The latter was renamed via
    # mkRenamedOptionModule (modules/programs/neovim/default.nix:54); the
    # shim still works but emits a deprecation trace on every rebuild, the
    # same way programs.git.userName did before it was migrated.
    initLua = builtins.readFile ../../nvim/init.lua;
  };
}
