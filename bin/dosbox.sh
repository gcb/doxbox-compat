#!/bin/env bash

# sanity check so we don't litter unexpected locations.
if [ ! -d drive_c ]; then
	echo "You shuld execute ${0} from inside the dosbox-compat game dir. The one that contains the drive_c directory."
	exit 2
fi

set -xe

# COM file to make keyboard repeat fast:
# same effect of MODE CON RATE=32 DELAY=1 (maximum rate, minimum delay).
# author sr_st https://www.vogons.org/viewtopic.php?t=85256
# mov ax, 0305h
# mov bx, 0000h
# int 16h
# mov ah, 4ch
# int 21h
echo -en '\xB8\x05\x03\xBB\x00\x00\xCD\x16\xB4\x4C\xCD\x21' > drive_c/fastkey.com

dosbox -conf ~/.dosbox/dosbox.conf -conf dosbox-overlay.conf

