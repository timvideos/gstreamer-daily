#! /bin/bash

set -e

./depends-gstreamer-debs.sh

cp $PWD/pbuilderrc ~/.pbuilderrc
sed -i -e"s:GSTREAMER_DIR:$PWD:" -e"s/DEPENDS/$(echo $(cat depends.upstream))/" ~/.pbuilderrc
cat ~/.pbuilderrc
pbuilder update --override-config

export DATE=`date -u +%Y%m%d%H%M%S`
export DATE_LONG=`date -u -R`
export OUTPUT=/tmp/packages/gstreamer$DATE
mkdir -p $OUTPUT

cat > /tmp/gstreamer-build.sh <<EOF
#! /bin/sh

set -e

export DATE=$DATE
export DATE_LONG="$DATE_LONG"
export OUTPUT="$OUTPUT"

cd $PWD
apt-add-repository ppa:mithro/streamtime
apt-get update
apt-get -y upgrade
apt-get install -y $(echo $(cat depends.ppa))
./build-gstreamer-debs.sh
EOF
pbuilder execute /tmp/gstreamer-build.sh

./dput-gstreamer-debs.sh
