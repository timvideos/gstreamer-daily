#! /bin/bash
#
# Work out the dependencies for packages in build-gstreamer-debs

PPA="(dh-autoreconf|libvpx|rtmp|schroedinger)"
EXCLUDE="(libopenspc-dev)"

grep Build-Depends build-gstreamer-debs.sh \
  | sed \
     -e's/Build-Depends.*: //' \
     -e's/\([^ ,]*\)[^,]*,* */\1 /g' \
     -e's/ /\n/g' \
     -e's/autopoint/gettext/g' \
  | sort \
  | uniq \
  | grep -v gstreamer \
  | egrep -v $EXCLUDE \
  > depends.everything

egrep $PPA depends.everything > depends.ppa
egrep -v $PPA depends.everything > depends.upstream

