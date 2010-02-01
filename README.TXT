# Introduction

SIB2LY is a tool for exporting Sibelius scores and translating them into the
language of LilyPond for typesetting the most beautiful scores. While LilyPond
is by far the best tool today to typeset professionally looking music, many
musicians still find the non-WYSIWYG way of editing intimidating. Sibelius,
being one of the few non-evil WYSIWIG notation editors, is appealing to
musicians as it allows a convenient way of editing scores and seeing them at
the same time. While I remain an advocate of non-WISYWIG typesetting of texts
(forever a user of LaTeX), typesetting music, essentially a graphical
language, is harder this way. Therefore, a combination of the two paradigms --
WISIWYG for entering and editing of music and non-WYSIWYG approach to final
tuning and camera-ready typesetting -- is attractive.
Hence `sib2ly`.

With `sib2ly`, the conversion (or rather, translation) is a two-stage process.
First, one runs an export plugin in Sibelius. The plugin is minimalistic in
design and simply reads through all the staves in the score and dumps all the
score objects, along with meta-data such as title, composer, etc., into an
.xml file. One then runs the `sib2ly` _interpreter tool_ on the generated .xml
dump to finally produce a LilyPond source. The rationale for this is as
follows. The original attempt at `sib2ly` was in the form of a self-contained
plugin that would do all the translation. However, as many new features were
added, and as more and more special cases were dealt with, the `sib2ly` plugin
grew into monstrosity, got unmanageable, unmaintainable, slow, and started tu
run into limitations of the ManuScript language. Soon it became clear that a
different approach is required to handle all the complexities of the language
of music. Therefore, the `sib2ly` _suite_ now consists of a dumb Sibelius
plugin, and an intelligent interpreter that translates the music into the
target LilyPond language. This ensures better extensibility and
maintainability.


# Installation

  1. If you are using a binary distribution of `sib2ly`, simply download the
suite and place the executable `sib2ly.exe` into a new folder of your choice.
For convenience, make sure the folder is in the PATH.

  2. Take the Sibelius plugin `sib2lydump.plg` and place it into the folder
where your Sibelius plugins are stored. On Windows, this is typically
`C:\Documents and Settings\_username_\Application Data\Sibelius
Software\Sibelius 6\Plugins\`.

Restart Sibelius to make sure the installed plugin is loaded. Optionally,
assign a shortcut in Sibelius to call the plugin more easily if you do it
often.

# Usage

  1. In Sibelius, open a score that you want to translate into LilyPond.

  2. Optionally, select the staves you want to translate. If nothing is
selected, the whole score will be processed.

  3. Run the "Sib2Ly Score Dump" plugin from the Plug-ins menu (or using a
keyboard shortcut if you have configured one).

  4. You will be prompted to select a file in which to dump the score. Do so
and click Save.

  5. The plugin will now read through the score and create an `.xml` file.

  6. Finally, from the command line run: `sib2ly filename.xml`

This will produce a translation `filename.ly`.

  7. Run LilyPond on `filename.ly` and enjoy the beautifully typeset music!

# Contact me

I welcome bug reports and suggestions. Please send your comments to Kirill
Sidorov using electric mail `sidosoft at yandex dot ru`.

If you are a performer, composer, conductor or a librarian and if you find
`sib2ly` useful, invite me to your next concert!))

