# Dotfiles

## Installer

Automated installation of a fresh linux system inside the `installer` directory.

- `./install.sh [-ni|--nointeractive] [-nd|--nodocker]` - installing programs and setup configurations
  - nointeractive - skip any user input questions
  - nodocker - don't install docker
- `./config.sh` - to renew symlinks and setup configurations

## Directories

**installer**  
Files starting with an \_underscore are includes only.
The `install.sh` file sets up a new linux machine which includes the `_config.sh`. `Config.sh` however can be executed individually to update symlinks.

**template**  
These files receive custom changes and get copied into the main .dotfiles directory. The copied files are excluded from git (.gitignore) because now they may receive individual changes like ssh configs which shouldn't be tracked.

**configs**  
Various config files for different frameworks or libraries.

### after installation

**/usr/local/bin**: additional global programs  
**~/bin**: custom user binaries
**~/bin/scripts**: custom user scripts
