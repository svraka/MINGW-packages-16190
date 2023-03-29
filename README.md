# Trying to rebuild Emacs

See https://github.com/msys2/MINGW-packages/issues/16190

## Installing old versions during a bisect

First, set up a local mirror for tarballs. In `.env` set its location as `MSYS2_REPO` and sync required packages with `sync_repo.sh`

Then run a git bisect in the main repo with `bisect.sh` (this calls `test.el` in this repo):

``` shell
git bisect start 0b8134337 dbe8d4aa9 -- mingw-w64-emacs mingw-w64-crt-git mingw-w64-headers-git mingw-w64-libmangle-git mingw-w64-tools-git mingw-w64-winpthreads-git mingw-w64-winstorecompat-git
git bisect run ../MINGW-packages-16190/bisect.sh
```
