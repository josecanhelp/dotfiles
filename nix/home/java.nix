{ pkgs, ... }:

{
  # Java from nixpkgs rather than a manual Oracle installer.
  #
  # This used to be a hardcoded JAVA_HOME in shell.nix pointing at
  # /Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home, a path Nix does
  # not create. It worked here only because that Oracle JDK had been installed
  # by hand in 2023; a fresh machine got a dangling JAVA_HOME and every Java
  # tool failed in a way that did not mention Java.
  #
  # programs.java installs the package and sets JAVA_HOME to its own
  # `home` passthru, so the two can never drift apart. That is the whole
  # argument for using the module rather than setting JAVA_HOME by hand.
  #
  # jdk17, not the unversioned jdk: `jdk` tracks whatever the current default
  # is, and Maven builds are the reason this JDK exists. Pinning the major
  # version keeps a nixpkgs bump from moving Java under those builds.
  # On darwin jdk17 resolves to zulu-ca-jdk, currently 17.0.19, which replaces
  # the Oracle 17.0.7 that was here.
  # Only 17. There is deliberately no second JDK and no version-switching
  # alias: every project here is on 17, and the old `setjava8` alias pointed at
  # a manual Oracle 1.8 install that Nix does not create anyway.
  #
  # Worth knowing if a second JDK is ever wanted: two of them cannot share a
  # profile. buildEnv fails with "two given paths contain a conflicting
  # subpath" because both ship demo/README among much else. Use a devshell
  # for the project that needs the other version instead.
  programs.java = {
    enable = true;
    package = pkgs.jdk17;
  };
}
