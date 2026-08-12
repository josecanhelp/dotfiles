# Adding and removing things

Worked examples, end to end, using real attributes and tokens. Eight of them,
one per kind of thing this repo declares.

For the reasoning behind the rules, see
[nix-conventions.md](nix-conventions.md). The short version of where things go
is in the README.

Activation commands, referenced throughout:

```sh
sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1   # the Mac
home-manager switch --flake ~/dotfiles#jose@RockemSockem       # the WSL box
```

---

## 1. A CLI tool on both machines: `bat`

The example that shows the asymmetry, because the same tool needs two edits in
two files. `nix/packages.nix` is a nix-darwin file and cannot serve the WSL box.

Check it exists for both platforms first. Not everything in nixpkgs is built for
every system:

```sh
nix eval --raw nixpkgs#legacyPackages.aarch64-darwin.bat.version   # 0.26.1
nix eval --raw nixpkgs#legacyPackages.x86_64-linux.bat.version     # 0.26.1
```

The Mac, in `nix/packages.nix`, in the `cli` group:

```diff
   cli = with pkgs; [
     actionlint
+    bat
     btop
```

The WSL box, in `nix/home/linux/default.nix`, in `home.packages`:

```diff
   home.packages = with pkgs; [
     actionlint
+    bat
     btop
```

Optionally assert it resolves from Nix rather than Homebrew, in
`nix/verify.sh`. This list takes the **binary** name, which for `bat` happens to
match the attribute:

```diff
-batch1=(rg fzf jq tree htop wget pstree watchexec nmap pandoc typst
+batch1=(rg bat fzf jq tree htop wget pstree watchexec nmap pandoc typst
```

Then activate on each machine separately. There is no single edit that covers
both.

**To remove:** reverse all three edits and activate again. Do not forget
`verify.sh`, or the next run reports `MISSING bat`, which reads like a broken
system rather than a stale assertion. Both Nix paths genuinely uninstall, so the
binary leaves `PATH` after activation.

---

## 2. A program with a home-manager module: `direnv`

Prefer this over adding a package plus a hand-written config file. The module
generates the config and the shell hook, and type-checks the options.

Confirm a module exists before writing anything:

```sh
nix eval .#darwinConfigurations.REM-JoseS-MBP1.config.home-manager.users.jose.programs \
  --apply 'p: p ? direnv'      # true
```

`direnv` is portable, so it belongs in `nix/home/shared/`. Create
`nix/home/shared/direnv.nix`:

```nix
{ ... }:

{
  programs.direnv = {
    enable = true;
    # Writes the hook into the .zshrc that programs.zsh generates. Without
    # this, direnv is installed but never activates in a shell.
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
```

Then import it from **both** platform files, since `shared/` is not
automatically included. In `nix/home/darwin/default.nix` and
`nix/home/linux/default.nix`:

```diff
     ../shared/git.nix
     ../shared/shell.nix
+    ../shared/direnv.nix
```

```sh
git add nix/home/shared/direnv.nix      # Nix only reads tracked files
```

Do not also add `direnv` to `nix/packages.nix`. The module already installs the
package, and listing it twice is how you end up unsure which one is on `PATH`.

**To remove:** delete the file, remove both imports, `git rm` it, and activate.

---

## 3. A GUI app on the Mac: Zed

Find the real token first. A wrong token does not fail the build, it fails at
activation, which is a slower way to find out:

```sh
brew search --cask zed
brew info --cask zed        # prints the token it actually resolved to
```

`brew info` is how you catch an alias. `handbrake` is both a formula (the CLI)
and a cask alias for `handbrake-app` (the GUI), so the two install different
software.

`nix/configuration.nix`, in `casks`, alphabetically:

```diff
       "wireshark-app"              # token is wireshark-app for the GUI
+      "zed"
       "zoom"                       # token is zoom, not zoom.us
```

```sh
nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths
sudo darwin-rebuild switch --flake ~/dotfiles#REM-JoseS-MBP1
```

Homebrew downloads and installs it, because nothing is there to adopt.

**If the app is already installed by direct download, expect the first rebuild
to fail on it.** Homebrew tries to adopt the existing bundle and refuses when
the version differs, which is the normal state for anything that self-updates:

```
Error: It seems the existing App is different from the one being installed.
```

Hand it over once, then rebuild:

```sh
brew install --cask --force zed
```

Do that deliberately. Adoption can be destructive: it may remove the app before
failing, which is what happened to Obsidian here.

**To remove** (Minecraft, as a real example):

```diff
       "microsoft-teams"
-      "minecraft"
       "monologue"
```

After activation **Minecraft is still installed.** `cleanup = "none"` means
Homebrew leaves undeclared things alone. That is enough if the goal is "a fresh
machine should not get this". To actually remove it:

```sh
brew uninstall --cask minecraft
brew uninstall --cask --force minecraft   # if you already deleted the app by hand
```

The `--force` variant matters because Homebrew keeps a record, and a plain
uninstall errors with "It seems the App source is not there."

---

## 4. A CLI tool not in nixpkgs: a brew formula

Last resort. A brew records *that* something is installed, not which version, so
two machines built from this repo on different days can differ.

Check nixpkgs properly first, including whether it merely fails on this
platform:

```sh
nix search nixpkgs <name>
nix eval --raw nixpkgs#legacyPackages.aarch64-darwin.<attr>.version
```

`nix/configuration.nix`, in `brews`. **The comment saying why nixpkgs was not
used is required**, not decoration:

```diff
   brews = [
     "themekit"      # shopify/shopify
+    "somecli"       # not in nixpkgs at all
     "ant"           # apacheAnt evaluates unavailable on aarch64-darwin
```

**If it comes from a third-party tap, add the tap in two places.** Homebrew
refuses to load formulae from untrusted taps, which aborts `brew bundle`
mid-activation. In `nix/configuration.nix`:

```diff
   taps = [
     "shopify/shopify"
+    "someorg/tap"
```

and in `flake.nix`, under `nix-homebrew`:

```diff
     trust.taps = [
       "shopify/shopify"
+      "someorg/tap"
```

**To remove:** delete the line, activate, then `brew uninstall <name>` by hand.
As with casks, undeclaring does not uninstall.

---

## 5. An App Store app: `masApps`

Read the id off the installed bundle. Never guess it: a wrong id does not error,
it installs a different app.

```sh
mdls -name kMDItemAppStoreAdamID /Applications/Pixelmator\ Pro.app
```

`nix/configuration.nix`, in `masApps`:

```diff
   masApps = {
     "Keynote" = 409183694;
+    "Pixelmator Pro" = 1289583905;
     "TestFlight" = 899247664;
   };
```

No `mas` entry is needed in `brews`: nix-darwin puts `pkgs.mas` on `PATH` itself
when it runs `brew bundle`.

Know what this does and does not buy. `mas` can only download what is already
tied to the Apple ID, so this automates reinstall rather than capturing state;
it pins no version; and a fresh machine must be signed into the App Store first
or `brew bundle` reports these as failures.

**To remove:** delete the line. Nothing is uninstalled; drag the app to the
Trash yourself.

---

## 6. A VS Code extension

`nix/home/darwin/vscode.nix`, in the group it belongs to. Find the exact id from
the marketplace URL or from `code --list-extensions`:

```diff
       # Web and JS
       dbaeumer.vscode-eslint
+      esbenp.prettier-vscode
```

Confirm the id resolves before building, since a typo produces a long
evaluation error:

```sh
nix eval --raw .#darwinConfigurations.REM-JoseS-MBP1.pkgs.vscode-marketplace-release \
  --apply 'm: m.esbenp.prettier-vscode.version'
```

Note `-release`. The plain `vscode-marketplace` set serves pre-release builds.

After activation the marker file's `onChange` rebuilds VS Code's
`extensions.json`, then **reload the VS Code window** (Cmd+Shift+P, "Reload
Window") for it to be picked up.

**To remove:** delete the line and activate. The extension stops loading
immediately, because VS Code's cache is rebuilt from the declared list, but its
directory stays on disk:

```sh
code --uninstall-extension esbenp.prettier-vscode
```

**One caveat.** VS Code's own auto-update is on, so a fast-moving extension can
install a newer build into the mutable extensions directory and shadow the
declared copy. Two of the 47 do this. The declaration is a floor, not a lock.

---

## 7. A macOS setting

Read the current value first. **`system.defaults` is enforced, so declaring a
value that does not match silently changes the machine** rather than erroring.
Two Dock values in the original audit were recorded wrongly, and declaring them
would have reconfigured the Dock.

```sh
defaults read com.apple.dock autohide          # 0 or 1
defaults read com.apple.dock showhidden
```

`nix/configuration.nix`, under `system.defaults`:

```diff
     dock = {
       autohide = true;
+      showhidden = true;
```

Types matter and are checked: booleans are `true`/`false`, not `1`/`0`, and
nix-darwin maps some enums to the integers macOS stores, so you write the word.
`dock.mineffect` takes `genie`/`scale`/`suck`, and the `showas` inside a
`persistent-others` folder entry takes `automatic`/`fan`/`grid`/`list`.

Confirm an option exists before guessing at it, because a name that is not an
option is an evaluation error rather than a silent no-op:

```sh
nix eval .#darwinConfigurations.REM-JoseS-MBP1.config.system.defaults.dock \
  --apply 'd: d ? showhidden'      # true
```

If there is no nix-darwin option for the setting, use
`system.defaults.CustomUserPreferences`, which writes an arbitrary domain and
key.

**To remove:** deleting the line does **not** restore the old value. It stops
being enforced, leaving whatever is currently set. Change it back in System
Settings, or declare the value you want.

---

## 8. A background job

macOS only. `launchd.agents` in a `nix/home/darwin/` module, which home-manager
labels `org.nix-community.home.<name>`.

Reference every binary by **absolute store path**. A launchd agent does not get
your interactive `PATH`, and this repo has already had an agent that ran for
weeks showing a live PID while being unable to find the binary it was calling:

```nix
launchd.agents.my-watcher = {
  enable = true;
  config = {
    ProgramArguments = [
      "${pkgs.watchexec}/bin/watchexec"
      "--"
      "${pkgs.goku}/bin/goku"
    ];
    RunAtLoad = true;
    StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/my-watcher.log";
  };
};
```

If it writes a log, rotate it. An unrotated Homebridge log here reached 529 MB.
Add a `newsyslog.d` entry via `environment.etc` in `nix/configuration.nix`, as
`goku.conf` does.

Add it to the `agents` array in `nix/verify.sh` so it is asserted to be
registered and to have existing store paths:

```sh
nix/verify.sh agents
```

Note `verify.sh` deliberately does not assert `state = running`, because an
agent with `RunAtLoad` and no `KeepAlive` exits after doing its work and that is
correct.

**To remove:** delete the block and activate. home-manager does a real teardown,
booting the agent out and deleting the plist, so this one genuinely uninstalls.
Remove it from `verify.sh` too.

---

## Checking before you commit

```sh
# Builds? No sudo, changes nothing.
nix build .#darwinConfigurations.REM-JoseS-MBP1.system --no-link --print-out-paths

# Declared binaries, symlinks and agents all resolve?
nix/verify.sh all

# The WSL box cannot be built from the Mac; evaluation is the available check.
nix eval '.#homeConfigurations."jose@RockemSockem".config.home.packages' --apply 'builtins.length'
```

Two habits worth keeping:

**`git add` new files before building.** Nix only reads git-tracked files, and
an untracked one fails with "path does not exist" while you are looking at it.

**Read the generated file rather than trusting the module.** It catches what
reasoning does not:

```sh
nix eval .#darwinConfigurations.REM-JoseS-MBP1.config.home-manager.users.jose.home.file \
  --apply 'f: f."./.zshrc".text' --raw | diff ~/.zshrc -
```
