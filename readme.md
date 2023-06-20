# Dotfiles

## Installer

Automated installation of a fresh linux system inside the `installer` directory.

- `./install.sh [-ni|--nointeractive] [--sync] [--essentials] [--tools]` - installing dependencies, setup configurations and symlinks
  - nointeractive - skip any user input questions
  - essentials - install essentials when they dont exist like git, zsh, fonts
  - sync - renew symlinks (scripts and configs) and setup configurations
  - tools - install tools if they font exist like exa or bat

`./sync.sh`, `./essentials.sh`, `./tools.sh` can be called individually.

### after installation

Paths to find executable scripts:  
`/usr/local/bin`: system wide scripts  
`~/bin`: custom user scripts
`~/bin/scripts`: custom user scripts (gets recreated on sync)

## Directories

**installer**  
Files starting with an \_underscore are includes only.
The `install.sh` file sets up a new linux machine which includes the `_functions.sh`. `sync.sh` however can be executed individually to update symlinks.

**template**  
These files receive custom changes and get copied into the main .dotfiles directory. The copied files are excluded from git (.gitignore) because now they may receive individual changes like ssh configs which shouldn't be tracked.

**bin**  
Usefull bash scripts which get symlinked to `~/bin/scripts`. Scripts which should only be used on the current machine and are located in `bin/local`.  
Be careful when removing files from here since they are not tracked by git.  
Adding new scripts requires to execute `installer/sync.sh`.

**configs**  
Various config files for different frameworks or libraries.

**scripts**  
A repository for bash utility functions.
