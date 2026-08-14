{ ... }:

{
  # macOS keychain. Does not exist on Linux, where git will prompt instead.
  programs.git.settings.credential.helper = "osxkeychain";
}
