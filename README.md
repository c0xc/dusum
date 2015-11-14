dusum
=====

dusum calculates the size of a directory by summing up the file sizes.
The directory inode is not counted.

This is almost the same as `du -s`, but it doesn't count directory inodes,
so this will return "0 B" for an empty directory.
du would show something like "4 KB" (or more) instead.
Also, the actual sizes of the files are used instead the size on disk.



Rationale
---------

Sometimes du just won't do.

Sometimes, the user wants to see a zero
if the directory is empty, no matter how much space is used by metadata.
And the size on disk might not be the best number to use when comparing
two directories on different filesystems.

Since this tool is meant to abstract away the filesystem,
it sees different hardlinks or CoW copies of the same file as different files,
like a regular user would see them.

There are lots of simple "find | ..." one-liners out there
for this particular purpose.
Unfortunately, many of these fail awkwardly when used with file names
that contain spaces or other special characters.
This tool will not fail even if there are whitespaces, quotes or dollar signs
in a file name.



Installation
------------

Copy dusum to a directory in your $PATH, like `~/.local/bin`.
You might want to drop the unpleasant suffix and just name it "dsum".

If `~/.local/bin` is not in your path (check `echo $PATH`), add it.
For example, in ~/.profile:

    export PATH=$PATH:$HOME/.local/bin



Scripts
-------

There are multiple versions of the same tool in this repository.

- dsum.pl

  This version is written in Perl.
  Use this one if possible (if Perl is installed).
  It's the fastest and safest version.
  It's safe because it doesn't have to worry about quoting/escaping file names.

  Options:
  - `-b` `--bytes` (output value in bytes, not formatted)
  - `-c` `--count` (print number of files)

- dusum.sh

  This is a Bash script. Use this instead of the Perl script
  if you don't have Perl installed.
  It uses a temporary named pipe, so it won't work if `mkfifo` can't be found.
  Other than that, it should work in most environments.
  It's called "dusum" because it actually uses "du" (per file);
  another tool can be used by setting `SIZE_TOOL=ls` (du, ls, stat, wc).
  It will use numfmt for formatting, if available.
  When calculating the size of a huge directory, a counter will show
  the number of scanned files. This makes it really slow, but it looks cool.
  Use the `-q` option to disable this counter.

  Options:
  - `-b` (output value in bytes, not formatted)
  - `-c` (print number of files)
  - `-q` (quiet, no output while working)

- dsum.sh

  This is a very simple Bash version without uncommon dependencies.
  It does need awk though.
  No options are available.

All of these scripts can scan multiple directories.
Without arguments, the current directory will be scanned.



Example
-------

    $ dusum test/
    73426332 (70 MB) .................................. test/
    $ dsum -c test/ Documents/
    70.02 MB, 44 files ................................ test/
    49.94 MB, 22 files ................................ Documents/



