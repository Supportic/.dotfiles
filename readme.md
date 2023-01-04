# Dotfiles

## Installer

Automated installation of a fresh linux system inside the `installer` directory.

- `./install.sh [-ni|--nointeractive] [-nd|--nodocker]` - installing dependencies, setup configurations and symlinks
  - nointeractive - skip any user input questions
  - nodocker - don't install docker
- `./config.sh` - to renew symlinks (scripts and configs) and setup configurations
- `./load_scripts.sh` - to renew script symlinks

## Directories

**installer**  
Files starting with an \_underscore are includes only.
The `install.sh` file sets up a new linux machine which includes the `_config.sh`. `Config.sh` however can be executed individually to update symlinks.

**template**  
These files receive custom changes and get copied into the main .dotfiles directory. The copied files are excluded from git (.gitignore) because now they may receive individual changes like ssh configs which shouldn't be tracked.

**configs**  
Various config files for different frameworks or libraries.

**bin**  
Usefull bash scripts which get symlinked to `~/bin/scripts`. Scripts which should only be used on the current machine are located in `bin/local`. Adding new scripts requires to execute `installer/load_scripts.sh`.

### after installation

Paths to find executable scripts:  
`/usr/local/bin`: system wide scripts  
`~/bin`: custom user scripts
`~/bin/scripts`: custom user scripts (gets recreated on sync)
