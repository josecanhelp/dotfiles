#!/usr/bin/env bash

# Install Homebrew
# ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Homebrew
#
# This installs some of the common dependencies needed (or at least desired)
# using Homebrew.

# Check for Homebrew
if test ! $(which brew)
then
  echo "  Installing Homebrew for you."

  # Install the correct homebrew for each OS type
  if test "$(uname)" = "Darwin"
  then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  elif test "$(expr substr $(uname -s) 1 5)" = "Linux"
  then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)"
  fi

fi

brew install caskroom/cask/brew-cask
brew cask install virtualbox
brew cask install vagrant
brew cask install vagrant-manager
brew install git tmux tree htop screenfetch

brew tap caskroom/unofficial
brew cask install iterm2-borderless


# Install before using the hhvm composer alias
brew tap homebrew/dupes
brew tap homebrew/versions
