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
in
{
  environment.systemPackages = cli ++ media ++ shell ++ vendored;
}
