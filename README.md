# Jose's Dotfiles


## Vim

### Managing Plugins

With Vim 8.0 there is a new plugin system. A full reference can be found in [this article](https://shapeshed.com/vim-packages/).

Plugins will be stored in `~/dotfiles/vim/pack/plugins/start/`

#### Adding a Package

```
cd ~/dotfiles
git submodule init
git submodule add https://github.com/vim-airline/vim-airline.git vim/pack/shapeshed/start/vim-airline
git add .gitmodules vim/pack/shapeshed/start/vim-airline
git commit
```

#### Updating Packages

```
git submodule update --remote --merge
git commit
```

#### Removing a Package

```
git submodule deinit vim/pack/shapeshed/start/vim-airline
git rm vim/pack/shapeshed/start/vim-airline
rm -Rf .git/modules/vim/pack/shapeshed/start/vim-airline
git commit
```
