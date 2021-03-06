hack-nix
========

Hack-nix is the tool used by [haskell-nix-overley](http://github.com/MarcWeber/haskell-nix-overlay) to get hackage contents putting them into a .nix file which is read by the cabal dependency resolver written in the nix language itself.

HOWTO BOOTSTRAP?
================

Build dependencies of hack-nix using the nix-haskell-overlay system:

make the first line in hack-nix-envs/nix/default.nix point to the nix-haskell-overlay.

Run:

    nix-env -p hack-nix-envs/default -iA env -f hack-nix-envs/nix/default.nix --show-trace
    source hack-nix-envs/default/source-me/haskell-env


ADVANCED USAGE (multiple configurations)
========================================

    hack-nix --write-hack-nix-cabal-config

writes a configuration file. Adjust it to your needs. For example, for hack-nix this file looks like this:

    # generated lines:
    default:[("haskellPackages","haskellPackages"),("flags","")]

Because there are no flags there is only one way to build the package. If you had run this command within the darcs repo (8flags) you would have got 2 ** 8 lines. However you must be insane to test them all. But having some configurations can be useful too. Note that it references additional files called `ways/base{3,4}.nix`. This tells the nix system to add additional filters forcing using base3 or base4 only. In theory you don't have to use such filters. But in practise you can't feed the solver with all packages. This would be too slow.

So applying the filter

    base = { lt = "4"; };

disregards base >= 4.

Also note that different haskellPackages are used selecting different ghc versions.

    # real world .hack-nix-cabal-config example (Darcs)
    base3:[("haskellPackages","haskellPackages"),("flags","curl -curl-pipelining http -static terminfo threaded -type-witnesses color mmap -test -hpc -deps-only"),("mergeWith","ways/base3.nix")]
    base4:[("haskellPackages","haskellPackages"),("flags","curl -curl-pipelining http -static terminfo threaded -type-witnesses color mmap -test -hpc -deps-only"),("mergeWith","ways/base4.nix")]
    682:[("haskellPackages","haskellPackages_ghc682"),("flags","curl -curl-pipelining http -static terminfo threaded -type-witnesses color mmap -test -hpc -deps-only"),("mergeWith","ways/base3.nix")]
    683:[("haskellPackages","haskellPackages_ghc683"),("flags","curl -curl-pipelining http -static terminfo threaded -type-witnesses color mmap -test -hpc -deps-only"),("mergeWith","ways/base3.nix")]

in `ways/base3.nix`:

    {
      filtersByName = {
        base = { lt = "4"; };
        # you can add additional dependencies here etc..
        # you can override everything you can think about.
        # configure once and have fun!
      };
    }

If you've customized these files you can now run

SHELL 1:

    $ hack-nix --build-env base3
    $ . hack-nix-envs/base3/source-me
    $ ./Setup configure --distdir=distbase3
    $ ./Setup build --builddir=distbase3

  SHELL 2

    $ hack-nix --build-env base4
    $ . hack-nix-envs/base4/source-me
    $ ./Setup configure --builddir=distbase4



How to tell hack-nix about custom packages which are not yet on hackage?
========================================================================

You can always add additional packages to the pool of available packages by
using a a way file like this:

in `ways/way-definining-additional-dependency-wash`:

    args: {
      packageOverrides = args.packageOverrides ++ [ (import /pr/tasks/wash/WashNGo-2.12/dist/WashNGo.nix) ];
    }

The `dist/WashNGo.nix` file is created by hack-nix --to-nix. This command also creates a dist source file for you which is picked up by nix

Fetching & Updating Darcs Repositories Automatically
====================================================

See [nix-repository-manager](http://github.com/MarcWeber/nix-repository-manager). Contact me if you have any questions.

TAGS
====

  I can't live without them. They make looking up implementation details so much faster!


  Add this line to your ~/.hack-nix/config file:

    create-haskell-tags TTVim


  Put something like this in your .vimrc:

    for t in split($TAG_FILES,":")
      exec "set tags+=".t
    endfor

  and be done. The soure-me script will define TAG_FILES for you.
  So you always have accurate tags.
  hasktags is used. So code which is generated by either CPP or template haskell is missed.

FAQ
===

error: Setup: failed to parse output of 'ghc-pkg dump'

cause: After sourcing a env file the ghc or cabal version changed.

fix: rm Setup and recompile that file

TODO
====

* Get more users to fix bugs and help mantain this all
* support emacs tags
* support haddock
* check that profiling options are passed to gtk2hs etc as well
* make the ruby bindings library use shared libs.
* implement multithread support: `./Setup build +RTS -N4 -RTS`
* Should this project be renamed to cabal2nix ?

Well, its already useful enough :)
