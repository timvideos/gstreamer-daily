#! /bin/bash

eval $(gpg-agent --daemon)

debsign -k$GPGKEY $OUTPUT/*.changes
dput timsvideo $OUTPUT/*.changes
