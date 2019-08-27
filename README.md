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


### Removing a Package v2

If the above steps don't work for whatever reason, you can use these steps:


Delete the relevant section from the .gitmodules file.  The section would look similar to:

[submodule "vendor"]
    path = vendor
    url = git://github.com/some-user/some-repo.git

Stage the .gitmodules changes via command line using:git add .gitmodules
Delete the relevant section from .git/config, which will look like:

[submodule "vendor"]
    url = git://github.com/some-user/some-repo.git

Run git rm --cached path/to/submodule .  Don't include a trailing slash -- that will lead to an error.
Run rm -rf .git/modules/submodule_name
Commit the change:
Delete the now untracked submodule files rm -rf path/to/submodule

