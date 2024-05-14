DOSBOX compatibility repo
=========================

All games are listed as CamelCase, with the most common name, keeping as
official as common sense allows, ending with version and year. If there's
different publishers etc keep it as part of the version.

```
<NameCamelCase>[<Version>][<ExtensionPack>[<ExtensionPackVersion>]]-<year>
```

E.g. `WingCommander1rev1SecretMissions1-1990`

It must contain the `dosbox-overlay.conf` with the minimum values so that the
game runs well. NO FIDDLING WITH SOUND unless it is to lower quality from a
sane default to work around common issues. So, mostly CPU, MEMORY, AUTOEXEC
sections

Feel free to check out this repo and add your game's data to `drive_c` or
other driver folders. The current `.gitignore` will prevent you from
commiting them back here.

Game compatibility file contributions are welcome. I will mostly blindly accept
them automatically, and subsequent corrections.


Follow my notes when learning about dosbox. Enjoy.

dosbox
======

There are a bunch of forks, with overkill things like built in mt-32 emulators
and visual shaders to emulate CRT. Safe to ignore if just starting. The default
dosbox have more than enough to experience all games in best condition.

Now, about config files... By default, it loads from
`~/.dosbox/dosbox-<version>.conf`. If there's a `./dosbox.conf`, then it loads
that instead.

It looks good and would be perfect if it loaded both in predictable order, they
even have two parameters for settings, which everyone confuse... maybe even the
devs. As soon as you pass a single one of those options, it ignores the base
one. So you must always pass all of them in the command line, and then the
distinction means nothing. Just use `-conf` and never think about it again.

About N config files:  Last one overriding repeat values from the last, with
`[autoexec]` being appended.

#### recommendation
Better to just have a helper that calls:
`dosbox -conf ~/.dosbox/dosbox.conf -conf dosbox-overlay.conf`


mount
-----

The first CLI parameter is either a mount for `C:` or the program to run, but
it is less useful in practice than the config files location because it will happen *after*
the autoexec portion, which means everything in autoexec cannot depend on
anything on the mount.

#### recommendation
Better to just use `mount C ./` in the autoexec when you need `C:`.

sound
-----

use the built-in sb16! trying to use mt-32 with external emulators is PURE PAIN.
and the quality is not even worth it, because often games have lame scores for it,
for example: [comparisson of all sound modes in Wing CommanderII](https://www.youtube.com/watch?v=K9Q9gi1zgo4&list=PLvH75QHS24Lv_kMKwXiPosaFR8Xf5y5Dq&index=16)
see how CDaudio is closer to everything but mt-32.

#### recommendation
use SB16. Bonus points to auto create the game's config file that uses it in
autoexec.

shortcut keys
-------------

`Ctrl+F10` let the mouse go.

`ctrl+F11/F12` fiddles with cpu speed.

if you press `ctrl+F9` you kill everything. Great choice. no way to turn off.

`alt+enter` toggle full screen.

Keyboard speed
--------------

dosbox keeps the default from ms-dos 5 i think. fast key repeat with a slow
delay.

it also does *not* include `MODE` command. People explored several solutions,
like copying `MODE.COM` from freeDOS, using `TURBOKEY.COM` from who knows
where, etc.

One Forum member provided a small assembly code that hardcode it to fast repeat
with minimum delay. I chose to include it in the helper launcher via `echo`ing
the resulting binary. If you use windows, good luck. just find those binary
files and move them around.

#### recommendation
just echo binary `B8 05 03 BB 00 00 CD 16 B4 4C CD 21` to a file and use it in autoexec.

final recipe
============

Organize files like so:
```asciiart
wingCommander1rev1-1990\
├── drive_c\
│   ├── gamedat
    ... here be game files ...
│   └── wc.exe
├── dosbox-overlay.conf
└── dosbox.sh
```
The outer dir can be named anything, the `drive_c/` dir inside is what will become your `C:` drive. DOS won't see it's name, so it can be long.

The outer dir will contain:
 * `drive_c/` the game dir. Mounted as `C:`.
 * `dosbox.sh` a fixed launcher helper. Convert to `.bat` if you need. Can live in your `bin/` path. Just have to remember to only call it from the outer dir as it expect relative paths for the game content. For now keeping copies as I am not sure we will not need special per-game code there. Hope not.
 * `dosbox-overlay.conf` the conf file with the overrides you need for the game. at least it will need the `autoexec` portion to mount `./drive_c` as it is the only essential part missing from the system conf file bellow.

Here are the files contents:
(for historical reasons, as originally in my notes. they will be actual files in this repo)

### one "launcher" helper for your OS/shell.
```sh
#!/bin/env bash
# launcher for dosbox. place in game dir along overlay.conf
set -xe

# COM file to make keyboard repeat fast:
# same effect of MODE CON RATE=32 DELAY=1 (maximum rate, minimum delay).
# author sr_st https://www.vogons.org/viewtopic.php?t=85256
# mov ax, 0305h
# mov bx, 0000h
# int 16h
# mov ah, 4ch
# int 21h
# ...write the resulting program to a file: B8 05 03 BB 00 00 CD 16 B4 4C CD 21
echo -en '\xB8\x05\x03\xBB\x00\x00\xCD\x16\xB4\x4C\xCD\x21' > drive_c/fastkey.com

dosbox -conf ~/.dosbox/dosbox.conf -conf dosbox-overlay.conf
```

### system wide config
one main config (this only shows the lines that differs from
default as of 2024):

```ini
# main system dosbox.conf (~/.dosbox/dosbox.conf or whatever your version loads by default)
[sdl]
windowresolution=800x600
output=opengl

[mixer]
rate=48000
blocksize=2048
prebuffer=30

[sblaster]
oplemu=compat
oplrate=48000

[gus]
gus=true
gusrate=48000

[speaker]
pcrate=48000

[autoexec]
# have no idea, but saw it on https://www.youtube.com/watch?v=ofU3hfdJM0k
loadfix -10
```

### overlay config
and one launch per directory with the changes you need, which
will almost always be on the cpu speed stuff. Example for wing commander 1:

```ini
# dosbox-overlay.conf for wing commander I
[cpu]
core=simple
cycles=3000

[joystick]
joysticktype=none

[dos]
xms=true
ems=true
umb=false

[autoexec]

# mount the drives
mount C ./drive_c
# lock further mount commands:
CONFIG -securemode
# this enter the drive in dos:
C:
# use our keyboard speed hack (see dosbox.sh)
FASTKEY.COM
# config game to use sb16:
echo v a904 >> wingcmdr.cfg
#OFF# config game with MIDI:
#OFF# echo v r >> wingcmdr.cfg
# start game program:
WC.EXE
```

### usage
now you just enter (or setting the working dir in the lnk if on windows) the
dir with the game, and run `./dosbox.sh` (or `.bat` if you ported)

if against all my suggestions you still decided to use midi, add something like
this before just starting `dosbox` in the helper script, to start your midi
synth emulator.

```sh
trap 'systemctl --user stop timidity' 0
systemctl --user start timidity
dosbox -conf ...
```
(on windows, just start your midi emulator program I guess)


