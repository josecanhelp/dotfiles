# Nix packages migration (sub-project 1 of 4)

**Date:** 2026-08-08
**Status:** Approved, not yet implemented
**Repo:** `~/dotfiles`, branch `nix-darwin`

## Goal

Move the 55 explicitly installed Homebrew formulae and the 734 MB of vendored
binaries in `bin/` into nixpkgs, declared in the existing nix-darwin flake.

## Context

nix-darwin is already live (generation 2). nix-homebrew manages the Homebrew
installation itself, and 13 casks are declared in `nix/configuration.nix`.
Formulae remain imperative. This sub-project changes that.

`brew list --formula` reports 243, but only 55 are `brew leaves`. The other 188
are transitive dependencies and will be swept with `brew autoremove` at the end.

## Decomposition

This spec covers sub-project 1 only. The full migration is four independent
pieces:

| # | Sub-project | Size | Depends on |
|---|---|---|---|
| 1 | Packages: 55 formulae + vendored bins | Medium | nothing |
| 2 | home-manager in, dotbot out | Medium | nothing |
| 3 | tmux declarative (`programs.tmux`) | Small | 2 |
| 4 | nvim declarative (`programs.neovim`) | Large | 2 |

Each gets its own spec, plan, and implementation cycle.

## Decisions

**Packages go in `environment.systemPackages`,** not home-manager. home-manager
does not exist yet (sub-project 2). Moving the list later is a file move, not a
rewrite.

**One global version per runtime.** `php83`, `python312`, `nodejs`, `ruby`.
Per-project version pinning moves to devshells or direnv when actually needed.
This collapses `php` + `php@8.3` into `php83` and `python@3.10` + `@3.11` +
`@3.12` into `python312`.

**PATH is fixed before any package moves.** Homebrew currently shadows Nix, so
migrating a package without this produces a silent no-op that cannot be tested.

**Batched, with `brew uninstall` per batch.** Brew copies remain installed until
the explicit uninstall step, giving each batch a real rollback window.

**`homebrew.onActivation.cleanup` stays `"none"`** throughout. Casks are
untouched by this work.

## Architecture

```
~/dotfiles/
  flake.nix                 unchanged
  nix/
    configuration.nix       thin entry point: imports, host settings, casks
    packages.nix            NEW
    verify.sh               NEW
```

`configuration.nix` gains `imports = [ ./packages.nix ];` and is otherwise
unchanged.

`packages.nix` is a standard nix-darwin module. Packages are grouped into named
lists and concatenated, so `configuration.nix` stays a wiring file. Shape only,
with the contents of each group drawn from the mapping table below:

```nix
{ pkgs, ... }:

let
  cli       = with pkgs; [ ... ];
  languages = with pkgs; [ ... ];
  media     = with pkgs; [ ... ];
  data      = with pkgs; [ ... ];
  cloud     = with pkgs; [ ... ];
in
{
  environment.systemPackages = cli ++ languages ++ media ++ data ++ cloud;
}
```

`with pkgs;` is scoped per group rather than once around the whole list, so a
typo in one group cannot silently resolve against another.

## The PATH fix

### Problem

nix-darwin's `set-environment` sets a correct nix-first PATH. Then
`~/.zprofile` runs `eval "$(/opt/homebrew/bin/brew shellenv)"`, which prepends
Homebrew and jumps it ahead of Nix. Measured clean login PATH:

```
 1  ~/.yarn/bin
 2  ~/.config/yarn/global/node_modules/.bin
 3  ~/dotfiles/bin/google-cloud-sdk/bin
 4  ~/.nvm/versions/node/v20.19.1/bin
 5  /opt/homebrew/opt/php@8.3/bin
 6  /opt/homebrew/bin            <- brew wins
 7  /opt/homebrew/sbin
 8  ~/.nix-profile/bin
 9  /run/current-system/sw/bin   <- systemPackages land here
10  /nix/var/nix/profiles/default/bin
```

`which -a rg` returns `/opt/homebrew/bin/rg`.

### Fix

One line at the **bottom** of `zsh/zshrc`:

```zsh
# Nix must win over Homebrew. brew shellenv in ~/.zprofile prepends
# /opt/homebrew/bin, so re-assert precedence here, last.
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"
```

Not `~/.zprofile`. That file is untracked, lives in `$HOME`, and is bracketed by
Amazon Q blocks marked "keep at the top" and "keep at the bottom".

### Cleanup included in this step

- `zshrc:21-30` re-append `/bin`, `/sbin`, `/usr/bin`, `/usr/sbin`,
  `/usr/local/bin`, all already present from `set-environment`
- `~/nvim-osx64/bin`, `~/.rbenv/versions/bin`, and
  `~/.dotfiles/bin/jdt-java-lang-server/bin` are dead directories
- `zshrc:141` sources zsh-syntax-highlighting from
  `/usr/local/share/zsh-syntax-highlighting`, an Intel Homebrew path that does
  not exist on this machine. It fails silently because the line ends in
  `2>/dev/null`. Both plugin `source` lines change to nix store paths in
  batch 2 regardless, since both plugins are being migrated.

### Verification

```bash
env -i HOME="$HOME" USER="$USER" TERM=dumb /bin/zsh -lic 'print -l $path'
```

The two nix entries must appear above `/opt/homebrew/bin`. No package has moved
yet, so `which -a rg` should still return the brew path. This proves the
mechanism in isolation.

## Package mapping

Verified against nixpkgs 26.05 on `aarch64-darwin`. The 55 leaves break down as
47 direct one-to-one mappings, 2 collapsed by the one-version-per-runtime
decision, and 6 requiring a judgment call.

### Direct

| Brew | nixpkgs |
|---|---|
| actionlint | `actionlint` |
| azure-cli | `azure-cli` |
| dotnet | `dotnet-sdk` |
| ffmpeg | `ffmpeg` |
| fonttools | `python3Packages.fonttools` |
| fzf | `fzf` |
| gh | `gh` |
| git | `git` |
| git-filter-repo | `git-filter-repo` |
| helm | `kubernetes-helm` |
| htop | `htop` |
| imagemagick | `imagemagick` |
| jadx | `jadx` |
| joker | `joker` |
| jpeg | `libjpeg` |
| jq | `jq` |
| librsvg | `librsvg` |
| mariadb | `mariadb` |
| minikube | `minikube` |
| nmap | `nmap` |
| node | `nodejs` |
| pandoc | `pandoc` |
| php@8.3 | `php83` |
| pipx | `pipx` |
| pkgconf | `pkgconf` |
| poppler | `poppler-utils` (plain `poppler` ships no `bin/`) |
| pstree | `pstree` |
| python@3.12 | `python312` |
| qemu | `qemu` |
| ranger | `ranger` |
| redis | `redis` |
| ripgrep | `ripgrep` |
| ruby | `ruby` |
| starship | `starship` |
| subversion | `subversion` |
| telnet | `inetutils` |
| tmux | `tmux` |
| tree | `tree` |
| typst | `typst` |
| watchexec | `watchexec` |
| wget | `wget` |
| woff2 | `woff2` |
| yarn | `yarn` |
| yt-dlp | `yt-dlp` |
| z.lua | `z-lua` |
| zsh-autosuggestions | `zsh-autosuggestions` |
| zsh-syntax-highlighting | `zsh-syntax-highlighting` |

### Collapsed by the one-version-per-runtime decision

| Brew | Resolution |
|---|---|
| php | Superseded by `php83` |
| python@3.11 | Superseded by `python312` |

### Exceptions

Each gets an entry in an `# exceptions` block at the bottom of `packages.nix`
with its reason. Silent omission is the failure mode to avoid.

| Brew | Resolution |
|---|---|
| ant | `apacheAnt` evaluates unavailable on darwin. Stays in brew |
| nvm | No nixpkgs equivalent by design. Dropped, `nodejs` global |
| python@3.10 | Removed from nixpkgs 26.05. Dropped, devshell if needed |
| sha2 | Not packaged. `coreutils` provides `sha256sum` and friends |
| bpytop | Not packaged. `btop` is the maintained successor |
| pytorch | `python3Packages.torch` exists but is heavy. Recommend a devshell rather than a global install |

### Vendored binaries

| Path | Size | Replacement |
|---|---|---|
| `bin/google-cloud-sdk` | 689 MB | `google-cloud-sdk.withExtraComponents` |
| `bin/nvim-macos-arm64` | 35 MB | `neovim` |
| `bin/apache-maven-3.9.9` | 10 MB | `maven` |

Total reclaimed: roughly 734 MB.

The vendored gcloud has `bq`, `gsutil`, and `docker-credential-gcloud`
installed as components. Nix cannot `gcloud components install` into a
read-only store, so these must be declared via `withExtraComponents`.

`bin/git-wtf` and `bin/zsh-colors` are tracked in git and stay where they are.

## Batches

| # | Contents | Rationale |
|---|---|---|
| 0 | PATH fix only, zero packages | Proves the mechanism before anything moves |
| 1 | ~25 standalone CLI tools | No daemons, no version coupling |
| 2 | git, tmux, starship, zsh plugins | Load-bearing for the shell. Both plugin `source` lines change here |
| 3 | Vendored bins: gcloud, maven, neovim | Deletes 734 MB and 3 PATH entries |
| 4 | Runtimes: php83, python312, nodejs, ruby, dotnet-sdk, yarn, pipx | Touches every project. nvm removal lands here |
| 5 | Services and heavy: mariadb, redis, minikube, kubernetes-helm, azure-cli, qemu, subversion | Most likely to need config attention |

Each batch is one commit and follows the same loop:

1. Add the batch to `packages.nix`
2. `darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1`
3. `nix/verify.sh` over the batch, confirming each binary resolves into `/nix/store`
4. `brew uninstall` the batch
5. Re-run `nix/verify.sh`
6. Commit

## Verification

`nix/verify.sh` holds an explicit list of **binary names** (not nixpkgs
attribute names) and asserts that each resolves into `/nix/store` via
`command -v`. The list is maintained alongside `packages.nix` and grows one
batch at a time.

Binary names rather than attribute names, because the two diverge often enough
to matter: `inetutils` provides `telnet`, `kubernetes-helm` provides `helm`,
`libjpeg` provides `cjpeg` and `djpeg`. Checking attribute names would assert
that Nix evaluated, which we already know, rather than that the binary you
actually type now comes from Nix.

It runs after every batch. This is the substitute for tests, since the work is
configuration rather than code.

Failure modes it catches:

- A package declared in Nix but still shadowed by brew on PATH
- A package whose nixpkgs attribute name does not produce the binary expected
  (for example `inetutils` providing `telnet`)
- A brew uninstall that removed a binary Nix did not actually replace

## Rollback

Per batch. Brew copies stay installed through step 3, so any failure before
step 4 costs nothing but a rebuild.

After step 4, recovery is `brew install <formula>` plus `git revert` of the
batch commit and a rebuild.

## Done

- Every one of the 55 leaves is either declared in `packages.nix` or documented
  in the exceptions block
- `brew leaves` returns only the exception list
- `brew autoremove` has swept the ~188 orphaned dependencies
- Clean login PATH shows nix above `/opt/homebrew/bin`
- Roughly 734 MB reclaimed from `bin/`
- `darwin-rebuild switch` succeeds from a clean checkout

## Out of scope

- home-manager and dotbot retirement (sub-project 2)
- tmux and nvim declarative rewrites (sub-projects 3 and 4)
- Cask changes
- Devshell or direnv setup. Named as the future home for per-project runtime
  pinning, but not built here
- The `~/.zprofile` Amazon Q blocks and `brew shellenv` line, which stay as they
  are
