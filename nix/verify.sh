#!/usr/bin/env bash
# Assert that each expected binary resolves from Nix, not Homebrew, that the
# repo symlinks point where they should, and that the declared launchd agents
# are registered against paths that exist.
# Usage: nix/verify.sh <0|1|2|3|4|5|6|links|agents|all>
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
batch2=(git tmux starship)
batch3=(gcloud bq gsutil mvn nvim)
# ruby intentionally absent: stays as system /usr/bin/ruby 2.6.10.
# pipx intentionally absent: fails to build in nixpkgs, stays on Homebrew.
# php intentionally absent: removed 2026-08-09, no local PHP on this machine.
# The surviving Laravel aliases run through Docker (sail) or ./vendor/bin.
batch4=(python3 node dotnet yarn ttx)
batch5=(mariadb redis-server minikube helm az svn qemu-system-aarch64)
# Tools that were invisible to `brew leaves` because it omits third-party
# tap formulae, plus uv which was an installer-managed ~/.local/bin binary.
batch6=(goku stripe shopify uv uvx)

# Paths home-manager should symlink back into ~/dotfiles.
# ~/.tmux.conf and ~/.tmux are deliberately absent: programs.tmux generates
# ~/.config/tmux/tmux.conf instead, and ~/.tmux is now a real directory
# holding resurrect state rather than a link into the repo.
# ~/.config/nvim is deliberately absent for the same reason: programs.neovim
# generates it as a real directory whose init.lua is a store symlink.
links=("$HOME/.hammerspoon"
       "$HOME/.amethyst.yml" "$HOME/.hushlogin" "$HOME/.bin"
       "$HOME/.config/karabiner.edn"
       "$HOME/.config/karabiner/karabiner.edn")

# launchd agents declared by home-manager, by label.
#
# This batch exists because nothing else on this machine looks. Three broken
# launchd jobs survived an entire four-part migration unnoticed, and the
# reason is that `brew services list` returns empty with exit 0, so no brew
# command ever surfaced them. One of them, the goku watcher, reported a live
# PID the whole time while being unable to execute the command it existed to
# run, because its binary had been deleted underneath it.
agents=("org.nix-community.home.goku"
        "org.nix-community.home.tmux-boot")

fail=0

check() {
  local bin="$1" path
  if ! path="$(command -v "$bin" 2>/dev/null)"; then
    printf 'MISSING   %s\n' "$bin"
    fail=1
    return
  fi
  # ~/.nix-profile/bin is deliberately not accepted here: useUserPackages puts
  # home-manager packages in /etc/profiles/per-user/$USER, so ~/.nix-profile
  # dangles and nothing can ever resolve from it. The branch was unreachable.
  case "$path" in
    /nix/store/*|/run/current-system/sw/bin/*|/etc/profiles/per-user/*)
      printf 'OK        %-18s %s\n' "$bin" "$path"
      ;;
    *)
      printf 'NOT NIX   %-18s %s\n' "$bin" "$path"
      fail=1
      ;;
  esac
}

check_link() {
  local p="$1" target
  if [ ! -L "$p" ]; then
    printf 'NOT LINK  %s\n' "$p"
    fail=1
    return
  fi
  # Resolve the WHOLE chain, not the first hop. mkOutOfStoreSymlink produces
  # ~/.x -> store/home-manager-files/.x -> store/hm_x -> ~/dotfiles/x, so the
  # first hop is always a store path even when it is working correctly. Only
  # the final target tells you whether the file is editable or read-only.
  target="$(readlink -f "$p")"
  case "$target" in
    "$HOME"/dotfiles/*)
      printf 'OK        %-34s -> %s\n' "$p" "$target"
      ;;
    /nix/store/*)
      printf 'IN STORE  %-34s -> %s (read-only: mkOutOfStoreSymlink missed)\n' "$p" "$target"
      fail=1
      ;;
    *)
      printf 'WRONG     %-34s -> %s\n' "$p" "$target"
      fail=1
      ;;
  esac
}

check_agent() {
  local label="$1" out args p missing=0
  if ! out="$(launchctl print "gui/$(id -u)/$label" 2>/dev/null)"; then
    printf 'NOT LOADED %s\n' "$label"
    fail=1
    return
  fi
  # Deliberately NOT asserting `state = running`. goku sets KeepAlive so it
  # stays up, but tmux-boot sets only RunAtLoad: it fires once at login and
  # exits, so it correctly reports "not running" almost always. Asserting a
  # running state would fail forever on a healthy agent.
  #
  # What is worth asserting is what actually broke: every path the job
  # executes must exist. home-manager wraps the command as
  # `/bin/sh -c "/bin/wait4path /nix/store && exec <store path> ..."`, so the
  # real targets live in the arguments block, not in `program`.
  args="$(printf '%s\n' "$out" | sed -n '/arguments = {/,/}/p')"
  case "$args" in
    */opt/homebrew*)
      printf 'HOMEBREW  %-38s still references /opt/homebrew\n' "$label"
      fail=1
      return
      ;;
  esac
  for p in $(printf '%s\n' "$args" | tr ' ' '\n' | grep '^/nix/store/'); do
    if [ ! -e "$p" ]; then
      printf 'DEAD PATH %-38s -> %s\n' "$label" "$p"
      missing=1
    fi
  done
  if [ "$missing" -ne 0 ]; then
    fail=1
    return
  fi
  printf 'OK        %-38s registered, store paths present\n' "$label"
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

if [ "${1:-all}" = links ]; then
  printf '=== links ===\n'
  for p in "${links[@]}"; do check_link "$p"; done
elif [ "${1:-all}" = agents ]; then
  printf '=== agents ===\n'
  for a in "${agents[@]}"; do check_agent "$a"; done
elif [ "${1:-all}" = all ]; then
  for i in 0 1 2 3 4 5 6; do run_batch "$i"; done
  printf '=== links ===\n'
  for p in "${links[@]}"; do check_link "$p"; done
  printf '=== agents ===\n'
  for a in "${agents[@]}"; do check_agent "$a"; done
else
  run_batch "$1"
fi

if [ "$fail" -ne 0 ]; then
  printf '\nFAILED\n'
  exit 1
fi
printf '\nPASSED\n'
