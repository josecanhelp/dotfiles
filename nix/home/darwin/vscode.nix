{ config, lib, pkgs, ... }:

# VS Code extensions, declared. 47 of the 55 that were installed; the other 8
# were cut deliberately (listed at the bottom).
#
# All 47 come from `pkgs.vscode-marketplace-release`, supplied by the
# nix-vscode-extensions overlay wired up in flake.nix, rather than from
# `pkgs.vscode-extensions` in the pinned nixpkgs. That is a deliberate choice
# with a real trade-off.
#
# Note the `-release` suffix. The plain `vscode-marketplace` set serves
# pre-release builds, which would have quietly moved about 15 of these onto
# pre-releases with date-stamped versions like 0.59.2026072407. Measured against
# what was actually loaded, the release channel is also simply more accurate:
# 42 of 47 matched exactly, versus 24 from the pre-release set.
#
# The first attempt used nixpkgs for the 35 it carries and the marketplace only
# for the 12 it does not. It half worked. VS Code resolves duplicate extension
# ids by picking the highest version, and because `mutableExtensionsDir` is true
# the previously hand-installed copies were still on disk. For 21 of the 47 the
# nixpkgs pin was OLDER than the installed copy, so the old one kept loading and
# the declaration described something that was not running. gitlens was the
# worst: 17.11.1 declared against 18.3.0 actually loaded.
#
# The two ways out were to accept downgrades on 21 extensions, or to declare
# current versions. This file does the latter, and 4 of the 47 still step back
# slightly: anthropic.claude-code and ms-dotnettools.vscode-dotnet-runtime by a
# little, plus vmware.vscode-spring-boot and vscjava.vscode-spring-boot-dashboard,
# which were both running pre-release builds, so declaring stable there is a
# correction rather than a loss. What it costs:
#
#   - These versions are NOT pinned by nixpkgs. They move when
#     `nix flake update` bumps nix-vscode-extensions, which tracks the live
#     marketplace and republishes daily.
#   - Evaluating the overlay pulls a large marketplace index, so the first
#     build after an update is slow.
#
# What it buys: the declared version is the version that loads, and a fresh
# machine gets extensions that are current rather than however old the nixpkgs
# pin happens to be.
#
# Three settings here are load-bearing and easy to undo by accident:
#
#   1. `package = null`. VS Code itself is the `visual-studio-code` cask in
#      nix/configuration.nix. The module's default would install a SECOND copy
#      from nixpkgs, since `home.packages` is gated on this being non-null.
#
#   2. `userSettings` is deliberately absent. The module writes settings.json
#      only when the merged settings are non-empty, and enableUpdateCheck and
#      enableExtensionUpdateCheck both default to null so they contribute
#      nothing. The hand-maintained 743-line settings.json is therefore
#      untouched. Setting ANY value here takes ownership of that entire file.
#
#   3. `mutableExtensionsDir` is left at its default of true, so extensions are
#      linked individually into ~/.vscode/extensions rather than the directory
#      being replaced, and installing one by hand still works. The cost is the
#      shadowing described above, which is why versions here must not lag.
#
# This file installs; it does not uninstall. The 8 cut below stopped loading as
# soon as the declared set took over, because VS Code rebuilt its extensions.json
# from the declared list, but their directories are still on disk until removed
# by hand.
#
# Cut on 2026-08-12:
#   ibm.zopeneditor, zowe.vscode-extension-for-zowe   mainframe work, done
#   formulahendry.auto-rename-tag                     no release since 2023-02
#   zengxingxin.sort-js-object-keys                   no release since 2023-02
#   mohsen1.prettify-json                             no release since 2023-02
#   shakram02.bash-beautify                           no release since 2023-02
#   uloco.theme-bluloco-dark                          unused theme
#   ghiblistuff.ghibli-theme                          unused theme
#
# The themes kept are the ones settings.json actually selects:
# workbench.colorTheme is "Dark Macchiato" (geek-tics.theme-macchiato) and
# workbench.iconTheme is material-icon-theme. Peacock stays because the
# Archive-Converge repos carry per-workspace peacock colours.

{
  programs.vscode = {
    enable = true;
    package = null;

    profiles.default.extensions = with pkgs.vscode-marketplace-release; [
      # Java and Spring
      redhat.java
      vscjava.vscode-java-pack
      vscjava.vscode-java-debug
      vscjava.vscode-java-dependency
      vscjava.vscode-java-test
      vscjava.vscode-maven
      vscjava.vscode-spring-initializr
      vscjava.vscode-spring-boot-dashboard
      vmware.vscode-spring-boot
      vmware.vscode-boot-dev-pack
      madhavd1.javadoc-tools
      redhat.vscode-xml
      dotjoshjohnson.xml

      # .NET
      ms-dotnettools.vscode-dotnet-runtime
      jmrog.vscode-nuget-package-manager

      # SQL Server and data
      ms-mssql.mssql
      ms-mssql.sql-bindings-vscode
      adpyke.vscode-sql-formatter
      inferrinizzard.prettier-sql-vscode
      mechatroner.rainbow-csv

      # Python
      ms-python.python
      ms-python.vscode-pylance
      ms-python.debugpy
      ms-python.black-formatter
      ms-python.vscode-python-envs
      kevinrose.vsc-python-indent

      # Web and JS
      dbaeumer.vscode-eslint
      esbenp.prettier-vscode
      bradlc.vscode-tailwindcss
      christian-kohler.npm-intellisense

      # Themes and window tinting
      geek-tics.theme-macchiato
      pkief.material-icon-theme
      johnpapa.vscode-peacock

      # Core editing and git
      vscodevim.vim
      eamodio.gitlens
      editorconfig.editorconfig
      streetsidesoftware.code-spell-checker
      alefragnani.project-manager
      aaron-bond.better-comments
      anthropic.claude-code

      # Config formats and containers
      jnoortheen.nix-ide
      tamasfe.even-better-toml
      redhat.vscode-yaml
      ms-azuretools.vscode-containers
      ms-vscode-remote.remote-containers

      # Testing and collaboration
      ms-playwright.playwright
      ms-vsliveshare.vsliveshare
    ];
  };

  # Rebuild VS Code's extension cache whenever the declared set changes.
  #
  # This exists because of `package = null` above. VS Code 1.74+ reads
  # ~/.vscode/extensions/extensions.json rather than scanning the directory, so
  # that file has to be regenerated when extensions move. home-manager's own
  # module does this, but its hook is gated on `cfg.package != null`, so setting
  # package to null to avoid a second VS Code silently disables it.
  #
  # Without this, changing the extension list leaves a cache pointing at
  # directories that no longer exist and every affected extension fails to load
  # with "Unable to resolve nonexistent file .../package.json". That is exactly
  # what happened on 2026-08-12 after the old hand-installed directories were
  # deleted.
  #
  # The marker file's content is the declared id@version list, so it changes
  # precisely when the extension set or any version changes, and not otherwise.
  home.file.".vscode/extensions/.hm-declared-extensions" = {
    text = lib.concatMapStrings (e: "${e.vscodeExtUniqueId}@${e.version}\n") (
      lib.sort (a: b: a.vscodeExtUniqueId < b.vscodeExtUniqueId)
        config.programs.vscode.profiles.default.extensions
    );

    # The cask's own CLI, by absolute path. `code` is not on PATH during
    # activation, and pkgs.vscode is deliberately not installed.
    onChange =
      let
        codeBin = "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code";
      in
      ''
        if [ -x "${codeBin}" ]; then
          run rm -f "$HOME/.vscode/extensions/extensions.json" \
                    "$HOME/.vscode/extensions/.init-default-profile-extensions"
          run "${codeBin}" --list-extensions > /dev/null || true
          echo "VS Code extension cache rebuilt. Reload any open window."
        else
          echo "VS Code cask not found; skipping extension cache rebuild."
        fi
      '';
  };
}
