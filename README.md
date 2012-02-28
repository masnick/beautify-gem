
             _                      _   _  __
            | |__   ___  __ _ _   _| |_(_)/ _|_   _
            | '_ \ / _ \/ _` | | | | __| | |_| | | |
            | |_) |  __/ (_| | |_| | |_| |  _| |_| |
            |_.__/ \___|\__,_|\__,_|\__|_|_|  \__, |
                                              |___/

**beautify** is a Ruby helper that makes it easy to export attractive
tables from [Stata].

[Stata]: http://www.stata.com/

It can take something like this:

<img src="http://dl.dropbox.com/u/634/beautify-gem_screenshots/stata.png">

And turn it into something like this:

<img src="http://dl.dropbox.com/u/634/beautify-gem_screenshots/tab2out.png">

Features
--------

- **beautify** keeps your Stata code nice and clean:

```
    webuse citytemp2, clear

    // Beautify setup
    do beautify.do
    beautify_init, filename("output.txt") byvariable("region")

    // Make some pretty tables...
    tab2out agecat, l("agecat")

    // Beautify output
    shell beautify stata --data output.txt --template template.yaml --output ./
```

- **beautify** is smart enough to use the variable and value labels in
  your dataset so you only have to label your data once.
- The HTML output from **beautify** is nicely formatted and properly
  paged for printing.

Technology
----------

It relies on the following technology:

- Stata 10 or newer
- Ruby >= 1.9.2
- [rubygems]
- [bundler]
- HTML/Javascript/CSS for rendering pretty tables (Google Chrome is
  best for viewing the `.html` file created by `beautify`).

[rubygems]: http://rubygems.org/pages/download
[bundler]: http://gembundler.com/



Available commands
==================

tab1out
-------

Equivalent to Stata's `tabulate oneway` command.

`tab1out agecat, l("agecat")` creates:

<img src="http://dl.dropbox.com/u/634/beautify-gem_screenshots/tab1out.png">

tab2out
-------

Equivalent to Stata's `tabulate twoway` command.

`tab2out agecat, l("agecat_region")` creates:

<img src="http://dl.dropbox.com/u/634/beautify-gem_screenshots/tab2out.png">


floatsummary
------------

Equivalent to Stata's `summarize` command. Table columns are grouped
by the `byvariable`.

`floatsummary tempjan, l("tempjan")` creates:

<img src="http://dl.dropbox.com/u/634/beautify-gem_screenshots/floatsummary.png">


tabmultout
----------

A multivariable version of the `floatsummary` command for creating
compact tables of summary statistics and statistical significance.

`tabmultout temp*, l("mult")` creates:

<img src="http://dl.dropbox.com/u/634/beautify-gem_screenshots/tabmultout.png">

How to use
==========

You should already have a Stata `.do` file that's running some
commands with output you want to export into a prettier format.

Step 0: Install beautify
--------------------------

Make sure you have Ruby first. You can type `ruby -v` at the command line
to check if it's installed. You should see something like:

    ruby 1.9.3p0 (2011-10-30 revision 33570) [x86_64-darwin11.2.0]

You'll need at least v1.9.2.

If you don't have Ruby installed or your version is too old, there is
an [installer for Windows](http://rubyinstaller.org/). On Mac, the best
thing to do is [use rbenv](https://github.com/masnick/beautify-gem/wiki/Installing-Ruby-on-Mac).

`beautify` is not currently on rubygems, so you'll need manually
download and install it.

First, download the most recent `.gem` from [github][dl]. It's the file called
`beautify-x.x.x.gem` under "Download Packages".

Then run the following at the command prompt:

    gem install /path/to/beautify-X.X.X.gem

This should install the `beautify` executable. You can check to see
if this worked with the `which beautify` command.

[dl]: https://github.com/masnick/beautify-gem/downloads

Step 1: Bootstrap
-----------------

`beautify` relies on a Stata `.do` file to add some functionality to
Stata. You can get this file by running the following at the command
line:

    beautify bootstrap --output /path/to/your/do/file

This will save a file named `beautify.do` in the output directory you
specify.

Step 2: Modifying your .do file
---------------------------------

You will need to add the following to the top of your `.do` file:

    do beautify.do
    beautify_init, filename("output.txt") byvariable("group")

You can change `group` to any integer variable. This is the second
variable that `beautify` will use in two-way tables (e.g. `tab2out`).

Then, add the following to the end of your `.do` file:

    shell beautify stata --data /path/to/output.txt --template /path/to/template.yml --output /path/to/output/folder

If you use `bash` instead of `zsh`, replace `.zshrc` with
`.bash_profile` or whatever has the `$PATH` declaration for `rbenv`.

If you use [rbenv], use the following instead:

    shell source /path/to/.zshrc && beautify stata --data /path/to/output.txt --template /path/to/template.yml --output /path/to/output/folder

[rbenv]: https://github.com/sstephenson/rbenv

Step 3: Setting up a template.yml file
----------------------------------------

`beautify` uses a [YAML] template file to make the pretty version of
your Stata output.

[YAML]: http://en.wikipedia.org/wiki/Yaml

The YAML file should follow this format:

    title: title here
    subtitle: subtitle here
    content:
      - section: "Section name"
        items:
          - heading: "Subsection name heading"
            items:
              - name: "Table name"
                description: "Table description"
                content: name_of_content_in_stata

Example
=======

You can see a functional example of `beautify`
at https://github.com/masnick/beautify-gem/tree/master/example.

License
=======

Copyright 2012 Duke University. All rights reserved.