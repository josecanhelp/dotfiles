{ pkgs, ... }:

# VS Code extensions, declared. 47 of the 55 that were installed; the other 8
# were cut deliberately (see below).
#
# Three things about this module are load-bearing and easy to undo by accident:
#
#   1. `package = null`. VS Code itself is the `visual-studio-code` cask in
#      nix/configuration.nix. The module's default would install a SECOND copy
#      from nixpkgs, since `home.packages` is gated on this being non-null.
#      Removing this line gets you two VS Codes.
#
#   2. `userSettings` is deliberately absent. The module only writes
#      settings.json when the merged settings are non-empty, and
#      enableUpdateCheck / enableExtensionUpdateCheck both default to null so
#      they contribute nothing. The hand-maintained 743-line settings.json is
#      therefore untouched. Setting ANY value here takes ownership of that whole
#      file, so do not add one casually.
#
#   3. `mutableExtensionsDir` is left at its default of true. Extensions are
#      linked individually into ~/.vscode/extensions rather than the directory
#      being replaced wholesale, which means installing one by hand still works.
#      It also means this list does NOT uninstall anything: the 8 cut below are
#      still on disk and need `code --uninstall-extension <id>` to go.
#
# Extensions come from two places. Most are in the pinned nixpkgs. The 12 marked
# "marketplace" below are not packaged there at all, and come from the
# nix-vscode-extensions flake via the overlay wired up in flake.nix. Those 12
# track the live marketplace rather than the nixpkgs pin, so they move when
# `nix flake update` runs.
#
# Cut on 2026-08-12, and NOT removed from disk by this file:
#   ibm.zopeneditor, zowe.vscode-extension-for-zowe   mainframe work, done
#   formulahendry.auto-rename-tag                     no update since 2023-02
#   zengxingxin.sort-js-object-keys                   no update since 2023-02
#   mohsen1.prettify-json                             no update since 2023-02
#   shakram02.bash-beautify                           no update since 2023-02
#   uloco.theme-bluloco-dark                          unused theme
#   ghiblistuff.ghibli-theme                          unused theme
#
# The two themes kept are the ones actually selected in settings.json:
# workbench.colorTheme is "Dark Macchiato" (geek-tics.theme-macchiato) and
# workbench.iconTheme is material-icon-theme. Peacock stays because the
# Archive-Converge repos carry per-workspace peacock colours.

let
  nixpkgsExts = with pkgs.vscode-extensions; [
    # Java and Spring
    redhat.java
    vscjava.vscode-java-pack
    vscjava.vscode-java-debug
    vscjava.vscode-java-dependency
    vscjava.vscode-java-test
    vscjava.vscode-maven
    vscjava.vscode-spring-initializr
    redhat.vscode-xml
    dotjoshjohnson.xml

    # .NET
    ms-dotnettools.vscode-dotnet-runtime

    # Data
    mechatroner.rainbow-csv

    # Python
    ms-python.python
    ms-python.vscode-pylance
    ms-python.debugpy
    ms-python.black-formatter
    ms-python.vscode-python-envs

    # Web and JS
    dbaeumer.vscode-eslint
    esbenp.prettier-vscode
    bradlc.vscode-tailwindcss
    christian-kohler.npm-intellisense

    # Themes and window tinting
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

    # Collaboration
    ms-vsliveshare.vsliveshare
  ];

  # marketplace: absent from nixpkgs, so these come from the overlay.
  marketplaceExts = with pkgs.vscode-marketplace; [
    # Java and Spring
    vscjava.vscode-spring-boot-dashboard
    vmware.vscode-spring-boot
    vmware.vscode-boot-dev-pack
    madhavd1.javadoc-tools

    # .NET
    jmrog.vscode-nuget-package-manager

    # SQL Server and SQL formatting
    ms-mssql.mssql
    ms-mssql.sql-bindings-vscode
    adpyke.vscode-sql-formatter
    inferrinizzard.prettier-sql-vscode

    # Python
    kevinrose.vsc-python-indent

    # The active colour theme
    geek-tics.theme-macchiato

    # Testing
    ms-playwright.playwright
  ];
in
{
  programs.vscode = {
    enable = true;
    package = null;
    profiles.default.extensions = nixpkgsExts ++ marketplaceExts;
  };
}
