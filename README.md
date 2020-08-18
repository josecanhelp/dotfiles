# Jose's Dotfiles

## Framework

I use the [dotbot](https://github.com/anishathalye/dotbot) framework to manage symlinks and new system initialization. I highly recommned using this framework because it mostly stays out of my way, provides an easy to understand yaml config file, and I don't have to maintain my own scripts.

## Brew

New `brewfile` is generated using `brew bundle dump`. However, I do need to manualy enter the `mas`-related apps since they were not originally installed via brew bundle.

## Vim

### Managing Plugins

I am using [vim-plug](https://github.com/junegunn/vim-plug) to manage my Vim plugins. You can watch [my video](https://www.youtube.com/watch?v=gRxGH2HA2_8) to see how easy it is to use.

## Terminal

- iTerm
- tmux
- zsh shell
- [Pure Prompt](https://github.com/sindresorhus/pure)

## Keyboard Mapping

[Karabiner](https://karabiner-elements.pqrs.org/) and [Hammerspoon](https://www.hammerspoon.org/) are used heavily to completely re-bind modifier+keys across applications. I also make use of [modals](https://www.hammerspoon.org/docs/hs.hotkey.modal.html) to add multiple layers to my keyboard beyond modifiers.

