# Trying to rebuild Emacs

See https://github.com/msys2/MINGW-packages/issues/16190

You need to set up everything and run the test for each MINGW environment separately.

## Setup

Install Emacs with its optional and build dependencies:

```
pacman -S $MINGW_PACKAGE_PREFIX-{emacs,giflib,libjpeg-turbo,libpng,librsvg,libtiff,libxml2,toolchain,autotools}
```

Then, set up a local mirror for tarballs. In a `.env` file in this repo set its location as `MSYS2_REPO` and sync required packages with `sync_repo.sh` from the directory of the main repo in a shell of a MINGW environment you want to test. You might need to run it on previous revisions as well because dependencies changed over time. We will also sync a lot of unnecessary packages (especially Python packages) because we can't use regular expressions in `rsync` filters.

## Run a git bisect

Then run a git bisect in the main repo with `bisect.sh` from this repo (this calls `test.el` in this repo):

``` shell
git bisect start 0b8134337 dbe8d4aa9 -- $(../MINGW-packages-16190/bisect-paths.sh)
git bisect run ../MINGW-packages-16190/bisect.sh
```
