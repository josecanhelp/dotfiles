{ pkgs, ... }:

let
  cli = with pkgs; [
    actionlint
    btop            # replaces brew bpytop, which nixpkgs does not package
    coreutils       # replaces brew sha2; provides sha256sum and friends
    fzf
    gh
    git-filter-repo
    htop
    inetutils       # provides telnet
    jadx
    jq
    joker
    nmap
    pandoc
    pkgconf
    pstree
    ranger
    ripgrep
    tree
    typst
    watchexec
    wget
    yt-dlp
  ];

  media = with pkgs; [
    ffmpeg
    imagemagick
    libjpeg         # provides cjpeg, djpeg, jpegtran
    librsvg         # provides rsvg-convert
    poppler-utils   # plain `poppler` ships no bin/
    woff2           # provides woff2_compress, woff2_decompress
  ];

  shell = with pkgs; [
    git
    starship
    tmux
    z-lua                   # provides z and z.lua (currently disabled in zshrc)
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];

  vendored = with pkgs; [
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])
    maven
    neovim
  ];

  languages = with pkgs; [
    # dotnet-sdk_9, not dotnet-sdk: the unversioned attribute is the 8.x
    # LTS (8.0.423), which would downgrade the 9.0.105 installed via brew.
    dotnet-sdk_9
    # nodejs_22 (current LTS line), not bare `nodejs`: that resolves to
    # 24.18.0, four majors past the v20.19.1 nvm had pinned. 22 moves
    # forward without the jump that breaks native modules.
    nodejs_22
    php83
    # pipx omitted: python3.13-pipx-1.8.0 fails to build in this nixpkgs.
    # Its test suite asserts on "black@ https://..." but a newer packaging
    # library normalizes to "black @ https://...", so 7 tests in
    # tests/test_package_specifier.py fail. pipx itself is fine; only the
    # checkPhase breaks. Stays on Homebrew. To pull it in anyway:
    #   (pipx.overridePythonAttrs (_: { doCheck = false; }))
    # python314, not python312: /opt/homebrew/bin/python3 was already
    # 3.14.6 via brew's python@3.14 (installed as a dependency, so it
    # never showed up in `brew leaves`). python312 would have been a
    # silent two-version downgrade.
    python314
    python3Packages.fonttools   # provides ttx, pyftsubset
    yarn
    # ruby deliberately omitted. `ruby` resolves to /usr/bin/ruby (system
    # 2.6.10) because brew's ruby formula is keg-only and was never linked.
    # Adding nix ruby 3.4.9 would change a command that works today.
  ];

  services = with pkgs; [
    azure-cli
    kubernetes-helm   # provides helm
    mariadb
    minikube
    qemu
    redis
    subversion        # provides svn
  ];
in
{
  # Exceptions: deliberately NOT migrated. `brew leaves` should return
  # exactly this list. Recorded here rather than omitted silently, so the
  # reason survives.
  #
  #   ant       apacheAnt evaluates unavailable on aarch64-darwin.
  #             Remains a brew formula.
  #   pipx      python3.13-pipx-1.8.0 fails its checkPhase in this
  #             nixpkgs (7 tests in tests/test_package_specifier.py assert
  #             on "pkg@ url" but a newer packaging library normalizes to
  #             "pkg @ url"). pipx itself is fine. To pull it in anyway:
  #               (pipx.overridePythonAttrs (_: { doCheck = false; }))
  #   pytorch   python3Packages.torch exists and is available on darwin,
  #             but is heavy and rarely wanted globally. Use a devshell.
  #   ruby      `ruby` resolves to /usr/bin/ruby (system 2.6.10) because
  #             brew's ruby is keg-only and was never linked. Adding nix
  #             ruby 3.4.9 would change a command that works today.
  #
  # Also intentionally dropped, with no brew formula left behind:
  #   nvm            No nixpkgs equivalent by design. nodejs_22 is global;
  #                  use devshells for per-project versions. ~/.nvm remains
  #                  on disk, unused.
  #   python@3.10    Removed from nixpkgs 26.05.
  #   bpytop, sha2   Superseded by btop and coreutils respectively.
  environment.systemPackages =
    cli ++ media ++ shell ++ vendored ++ languages ++ services;
}
