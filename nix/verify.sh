#!/usr/bin/env bash
# Assert that each expected binary resolves from Nix, not Homebrew.
# Usage: nix/verify.sh <0|1|2|3|4|5|all>
#
# Checks BINARY names, not nixpkgs attribute names. The two diverge:
# inetutils provides telnet, kubernetes-helm provides helm, coreutils
# provides sha256sum.
set -uo pipefail

batch0=()
batch1=(rg fzf jq tree htop wget pstree watchexec nmap pandoc typst
        actionlint git-filter-repo joker yt-dlp ranger jadx gh telnet
        sha256sum btop pkgconf ffmpeg magick pdfinfo pdftotext
        rsvg-convert woff2_compress cjpeg)
batch2=(git tmux starship z.lua)
batch3=(gcloud bq gsutil mvn nvim)
# ruby intentionally absent: stays as system /usr/bin/ruby 2.6.10.
# pipx intentionally absent: fails to build in nixpkgs, stays on Homebrew.
batch4=(php python3 node dotnet yarn ttx)
batch5=(mariadb redis-server minikube helm az svn qemu-system-aarch64)

fail=0

check() {
  local bin="$1" path
  if ! path="$(command -v "$bin" 2>/dev/null)"; then
    printf 'MISSING   %s\n' "$bin"
    fail=1
    return
  fi
  case "$path" in
    /nix/store/*|/run/current-system/sw/bin/*|"$HOME"/.nix-profile/bin/*)
      printf 'OK        %-18s %s\n' "$bin" "$path"
      ;;
    *)
      printf 'NOT NIX   %-18s %s\n' "$bin" "$path"
      fail=1
      ;;
  esac
}

run_batch() {
  local n="$1"
  local ref="batch${n}[@]"
  local list=()
  # Guard against empty arrays under `set -u` on bash 3.2.
  eval "if [ \${#batch${n}[@]} -gt 0 ]; then list=(\"\${${ref}}\"); fi"
  if [ ${#list[@]} -eq 0 ]; then
    printf '=== batch %s === (nothing to check)\n' "$n"
    return
  fi
  printf '=== batch %s ===\n' "$n"
  local b
  for b in "${list[@]}"; do check "$b"; done
}

if [ "${1:-all}" = all ]; then
  for i in 0 1 2 3 4 5; do run_batch "$i"; done
else
  run_batch "$1"
fi

if [ "$fail" -ne 0 ]; then
  printf '\nFAILED\n'
  exit 1
fi
printf '\nPASSED\n'
