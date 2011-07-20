#! /bin/bash

set -e

if [ ! -d /tmp/packages ]; then
	mkdir /tmp/packages
fi

./depends-gstreamer-debs.sh

cp $PWD/pbuilderrc ~/.pbuilderrc
sed -i -e"s:GSTREAMER_DIR:$PWD:" -e"s/DEPENDS/$(echo $(cat depends.upstream))/" ~/.pbuilderrc
cat ~/.pbuilderrc
pbuilder update --override-config

cat > /tmp/gstreamer-build.sh <<EOF
#! /bin/sh
cd $PWD
apt-add-repository ppa:mithro/streamtime
apt-get update
apt-get install -y $(cat depends.ppa)
./build-gstreamer-debs.sh
EOF
pbuilder execute /tmp/gstreamer-build.sh
