#! /bin/bash

set -e

DATE=`date -u +%Y%m%d%H%M%S`
DATE_LONG=`date -u -R`
ROOT=`pwd`
BUILD=1
OUTPUT=/tmp/packages/gstreamer

# Build the packages for upload (and possibly build a local version too)
function build {
	if [ $BUILD -eq 1 ]; then 
		fakeroot debian/rules binary
	fi
	debuild -S -us -uc
}

function getsource {
	TMP=`pwd`
	if [ -d $ROOT/repos/common ]; then
		cd $ROOT/repos/common
		git pull || true
	else
		cd $ROOT/repos
		git clone git://anongit.freedesktop.org/git/gstreamer/common
	fi

	if [ -d $ROOT/repos/$1 ]; then
		cd $ROOT/repos/$1
		git pull || true
	else
		cd $ROOT/repos
		git clone git://anongit.freedesktop.org/git/gstreamer/$1
	fi

	cd $TMP
	git clone $ROOT/repos/$1/.git
	cd $1
	if [ -e common ]; then
		echo "Rewriting common"
		sed -e"s~git://anongit.freedesktop.org/gstreamer/common~$ROOT/repos/common/.git~" -i .gitmodules
	fi
	if [ x$2 = libtoolize.patch ]; then
		patch -p1 < $ROOT/libtoolize.patch
	fi
	./autogen.sh
	make
	make dist
	cd $TMP
}

function bumplog {
	cat > debian/changelog-new <<EOF
$1 ($2~git$DATE) lucid; urgency=low

  * $1 from git on $DATE

 -- Tim Ansell <mithro@mithis.com>  $DATE_LONG

EOF
	cat debian/changelog >> debian/changelog-new
	mv debian/changelog-new debian/changelog
}

echo $DATE

if [ ! -d $ROOT/repos ]; then
	mkdir -p $ROOT/repos
fi

if [ -d $OUTPUT ]; then
 rm -rf $OUTPUT
fi
mkdir $OUTPUT

## # Build the core gstreamer
## ###############################################################################
## cd $OUTPUT
## 
## if [ -d temp ]; then
## 	rm -rf temp
## fi
## 
## for i in $ROOT/depends/*.dsc; do
## 	(
## 		mkdir temp
## 		cd temp
## 		dpkg-source -x $i tobuild
## 		cd tobuild
## 		fakeroot debian/rules binary
## 		cd ..
## 		dpkg --install *.deb
## 	)
## 	rm -rf temp
## done

# Build the core gstreamer
###############################################################################
cd $OUTPUT

BASEVERSION=0.10.35.1
getsource gstreamer

tar -jxvf gstreamer/gstreamer-$BASEVERSION.tar.bz2
mv gstreamer-$BASEVERSION gstreamer0.10-$BASEVERSION

TAR=gstreamer0.10_$BASEVERSION~git$DATE.orig.tar.bz2
tar -cjvf $TAR gstreamer0.10-$BASEVERSION
rm -rf gstreamer0.10-$BASEVERSION

TAR_MD5=`md5sum $TAR | sed -e's/ .*//'`
TAR_SIZE=`du -b $TAR | sed -e's/\s.*//'`

cp $ROOT/gstreamer-debian.tar.gz gstreamer0.10_$BASEVERSION~git$DATE.debian.tar.gz

DSC=gstreamer0.10_$BASEVERSION~git$DATE.dsc
cat > $DSC <<EOF 
Format: 3.0 (quilt)
Source: gstreamer0.10
Binary: libgstreamer0.10-0, libgstreamer0.10-0-dbg, libgstreamer0.10-dev, gstreamer0.10-doc, gstreamer0.10-tools, gstreamer-tools, gir1.0-gstreamer-0.10
Architecture: any
Version: $BASEVERSION~git$DATE
Maintainer: Maintainers of GStreamer packages <pkg-gstreamer-maintainers@lists.alioth.debian.org>
Uploaders: Loic Minier <lool@dooz.org>, Sebastien Bacher <seb128@debian.org>, Sebastian Dröge <slomo@debian.org>, Sjoerd Simons <sjoerd@debian.org>
Homepage: http://gstreamer.freedesktop.org
Standards-Version: 3.8.4
Build-Depends: debhelper (>= 7), cdbs (>= 0.4.20), gnome-pkg-tools (>= 0.7), autotools-dev, dh-autoreconf, autopoint | gettext, libxml2-dev (>= 2.6.0), zlib1g-dev (>= 1:1.1.4), libglib2.0-dev (>= 2.22), libgmp3-dev, libgsl0-dev, pkg-config (>= 0.11.0), bison (>= 1.875), flex (>= 2.5.34), dpkg-dev (>= 1.15.1), perl-doc, libgirepository1.0-dev (>= 0.6.3), gobject-introspection (>= 0.6.5), gir1.0-glib-2.0, gir1.0-freedesktop
Build-Depends-Indep: python (>= 2.2), gtk-doc-tools (>= 0.7), jade (>= 1.2.1), transfig (>= 3.2.3.c), docbook-utils (>= 0.6.9), docbook-xml, docbook-xsl, xsltproc (>= 1.0.21), ghostscript, xmlto, netpbm, libxml2-doc, libglib2.0-doc
Files: 
 $TAR_MD5 $TAR_SIZE $TAR
 b86e1bcf1853168d27aa28d756daa805 41748 gstreamer0.10_$BASEVERSION~git$DATE.debian.tar.gz
EOF

dpkg-source -x $DSC

cd gstreamer0.10-$BASEVERSION~git$DATE

bumplog gstreamer0.10 $BASEVERSION
build

if [ $BUILD -eq 1 ]; then 
	cd ..
	dpkg --install gir1.0-* lib*.deb
	dpkg --install gstreamer0.10-tools*.deb
fi

# Build gst-plugins-base
###############################################################################
cd $OUTPUT

BASEVERSION=0.10.35.1
getsource gst-plugins-base 

TAR=gst-plugins-base0.10_$BASEVERSION~git$DATE.orig.tar.gz
cp gst-plugins-base/gst-plugins-base-$BASEVERSION.tar.gz $TAR
TAR_MD5=`md5sum $TAR | sed -e's: .*::'`
TAR_SIZE=`du -b $TAR | sed -e's/\s.*//'`

cp $ROOT/gst-plugins-base-debian.tar.gz gst-plugins-base0.10_$BASEVERSION~git$DATE.debian.tar.gz

DSC=gst-plugins-base_$BASEVERSION~git$DATE.dsc
cat > $DSC <<EOF 
Format: 3.0 (quilt)
Source: gst-plugins-base0.10
Binary: gstreamer0.10-plugins-base-apps, gstreamer0.10-plugins-base-doc, libgstreamer-plugins-base0.10-0, libgstreamer-plugins-base0.10-dev, gstreamer0.10-alsa, gstreamer0.10-gnomevfs, gstreamer0.10-plugins-base, gstreamer0.10-plugins-base-dbg, gstreamer0.10-x, gir1.0-gst-plugins-base-0.10
Architecture: any
Version: $BASEVERSION~git$DATE
Maintainer: Maintainers of GStreamer packages <pkg-gstreamer-maintainers@lists.alioth.debian.org>
Uploaders: Loic Minier <lool@dooz.org>, Sebastien Bacher <seb128@debian.org>, Sebastian Dröge <slomo@debian.org>, Sjoerd Simons <sjoerd@debian.org>
Homepage: http://gstreamer.freedesktop.org
Standards-Version: 3.8.4
Build-Depends: libgstreamer0.10-dev (= $BASEVERSION~git$DATE), libasound2-dev (>= 0.9.0) [linux-any], libgudev-1.0-dev (>= 143) [linux-any], autotools-dev, dh-autoreconf, autopoint | gettext, cdbs (>= 0.4.20), debhelper (>= 7), gnome-pkg-tools (>= 0.7), pkg-config (>= 0.11.0), libxv-dev (>= 6.8.2.dfsg.1-3), libxt-dev (>= 6.8.2.dfsg.1-3), libvorbis-dev (>= 1.0.0-2), libvorbisidec-dev (>= 1.0.0-2), libcdparanoia-dev (>= 3.10.2) [!hurd-i386], libgnomevfs2-dev (>= 1:2.20.0-2), liborc-0.4-dev (>= 1:0.4.11), libpango1.0-dev (>= 1.16.0), libtheora-dev (>= 1.1), libglib2.0-dev (>= 2.22), libxml2-dev (>= 2.4.23), zlib1g-dev (>= 1:1.1.4), libvisual-0.4-dev (>= 0.4.0), gstreamer-tools (= $BASEVERSION~git$DATE), dpkg-dev (>= 1.15.1), iso-codes, libgtk2.0-dev (>= 2.12.0), libglib2.0-doc, gstreamer0.10-doc, libgirepository1.0-dev (>= 0.6.3), gobject-introspection (>= 0.6.5), gir1.0-glib-2.0, gir1.0-freedesktop, gir1.0-gstreamer-0.10
Files: 
 $TAR_MD5 $TAR_SIZE $TAR
 d45c425b6a76ce27ee8435151e3c58c2 38805 gst-plugins-base0.10_$BASEVERSION~git$DATE.debian.tar.gz
EOF

dpkg-source -x $DSC

cd gst-plugins-base0.10-$BASEVERSION~git$DATE
bumplog gst-plugins-base0.10 $BASEVERSION
build

if [ $BUILD -eq 1 ]; then 
	cd ..
	dpkg --install gir1.0-*base* lib*base*.deb
fi

# Build gst-plugins-good
###############################################################################
cd $OUTPUT

GOODVERSION=0.10.30.1
getsource gst-plugins-good

TAR=gst-plugins-good0.10_$GOODVERSION~git$DATE.orig.tar.gz
cp gst-plugins-good/gst-plugins-good-$GOODVERSION.tar.gz $TAR
TAR_MD5=`md5sum $TAR | sed -e's/ .*//'`
TAR_SIZE=`du -b $TAR | sed -e's/\s.*//'`

cp $ROOT/gst-plugins-good-debian.tar.gz gst-plugins-good0.10_$GOODVERSION~git$DATE.debian.tar.gz

DSC=gst-plugins-good0.10_$GOODVERSION~git$DATE.dsc
cat > $DSC <<EOF 
Format: 3.0 (quilt)
Source: gst-plugins-good0.10
Binary: gstreamer0.10-plugins-good-doc, gstreamer0.10-pulseaudio, gstreamer0.10-gconf, gstreamer0.10-plugins-good, gstreamer0.10-plugins-good-dbg
Architecture: any
Version: $GOODVERSION~git$DATE
Maintainer: Maintainers of GStreamer packages <pkg-gstreamer-maintainers@lists.alioth.debian.org>
Uploaders: Loic Minier <lool@dooz.org>, Sebastian Dröge <slomo@debian.org>, Sjoerd Simons <sjoerd@debian.org>
Standards-Version: 3.8.4
Build-Depends: libgstreamer0.10-dev (= $BASEVERSION~git$DATE), libraw1394-dev (>= 2.0.0) [linux-any], libiec61883-dev (>= 1.0.0) [linux-any], libavc1394-dev [linux-any], libv4l-dev [linux-any], libgudev-1.0-dev (>= 143) [linux-any], libgstreamer-plugins-base0.10-dev (= $BASEVERSION~git$DATE), autotools-dev, dh-autoreconf, autopoint | gettext, cdbs (>= 0.4.20), debhelper (>= 5), dpkg-dev (>= 1.15.1), pkg-config (>= 0.11.0), gtk-doc-tools, gconf2, libglib2.0-dev (>= 2.22), liborc-0.4-dev (>= 1:0.4.11), libcairo2-dev, libcaca-dev, libspeex-dev (>= 1.1.6), libpng12-dev, libshout3-dev, libjpeg62-dev (>= 6b), libaa1-dev (>= 1.4p5), libflac-dev (>= 1.1.4), libdv4-dev | libdv-dev, libgconf2-dev, libxdamage-dev, libxext-dev, libxfixes-dev, libxv-dev, libxml2-dev, libgtk2.0-dev (>= 2.8), libtag1-dev (>= 1.5), libwavpack-dev (>= 4.20), gstreamer-tools (= $BASEVERSION~git$DATE), gstreamer0.10-plugins-base (= $BASEVERSION~git$DATE), libsoup-gnome2.4-dev (>= 2.26), libpulse-dev (>= 0.9.20), libbz2-dev, gstreamer0.10-doc, gstreamer0.10-plugins-base-doc, libjack-dev (>= 0.99.10)
Files: 
 $TAR_MD5 $TAR_SIZE $TAR
 71531d2a5bd3116db2ef7de51a2ace8a 30349 gst-plugins-good0.10_$GOODVERSION~git$DATE.debian.tar.gz
EOF

dpkg-source -x $DSC

cd gst-plugins-good0.10-$GOODVERSION~git$DATE
bumplog gst-plugins-good0.10 $GOODVERSION
build

# Build gst-plugins-bad
###############################################################################
cd $OUTPUT
BADVERSION=0.10.22.1
getsource gst-plugins-bad libtoolize.patch

TAR=gst-plugins-bad0.10_$BADVERSION~git$DATE.orig.tar.gz
cp gst-plugins-bad/gst-plugins-bad-$BADVERSION.tar.gz $TAR
TAR_MD5=`md5sum $TAR | sed -e's/ .*//'`
TAR_SIZE=`du -b $TAR | sed -e's/\s.*//'`

cp $ROOT/gst-plugins-bad-debian.tar.gz gst-plugins-bad0.10_$BADVERSION~git$DATE.debian.tar.gz

DSC=gst-plugins-bad0.10_$BADVERSION~git$DATE.dsc
cat > $DSC <<EOF 
Format: 3.0 (quilt)
Source: gst-plugins-bad0.10
Binary: gstreamer0.10-plugins-bad-doc, gstreamer0.10-plugins-bad, gstreamer0.10-sdl, gstreamer0.10-plugins-bad-dbg
Architecture: any
Version: $BADVERSION~git$DATE
Maintainer: Maintainers of GStreamer packages <pkg-gstreamer-maintainers@lists.alioth.debian.org>
Uploaders: Sebastian Dröge <slomo@debian.org>, Sjoerd Simons <sjoerd@debian.org>
Standards-Version: 3.8.4
Build-Depends: autopoint | gettext, autotools-dev, cdbs (>= 0.4.32), debhelper (>= 7), dh-autoreconf, dpkg-dev (>= 1.15.1), flite-dev, libasound2-dev (>= 0.9.1) [linux-any], libcdaudio-dev [linux-any], libdc1394-22-dev (>= 2.0.0) [linux-any], libgstreamer0.10-dev (= $BASEVERSION~git$DATE), gstreamer0.10-doc, gstreamer0.10-plugins-base (= $BASEVERSION~git$DATE), gstreamer0.10-plugins-base-doc, gstreamer-tools (= $BASEVERSION~git$DATE), gtk-doc-tools, ladspa-sdk, libass-dev (>= 0.9.4), libbz2-dev, libcairo2-dev, libcelt-dev (>= 0.5.0), libdca-dev, libdirac-dev (>= 0.10), libdirectfb-dev (>= 0.9.25), libdvdnav-dev (>= 4.1.2) [!hurd-any], libexempi-dev, libexif-dev (>= 0.6.16), libfaad-dev, libglib2.0-dev (>= 2.22), libgme-dev, libgsm1-dev, libgstreamer-plugins-base0.10-dev (= $BASEVERSION~git$DATE), libgtk2.0-dev (>= 2.14.0), libiptcdata0-dev (>= 1.0.2), libjasper-dev, libkate-dev (>= 0.1.7), libmimic-dev (>= 1.0), libmms-dev (>= 0.4), libmodplug-dev, libmpcdec-dev, libmusicbrainz4-dev (>= 2.1.0), libofa0-dev (>= 0.9.3), libopenspc-dev [i386], liborc-0.4-dev (>= 1:0.4.11), libpng12-dev, librsvg2-dev (>= 2.14.0), librtmp-dev, libschroedinger-dev (>= 1.0.7), libsdl1.2-dev, libslv2-dev (>= 0.6.6), libsndfile1-dev (>= 1.0.16), libsoundtouch1-dev, libssl-dev, libvpx-dev, libwildmidi-dev (>= 0.2.3), libx11-dev, lv2core, pkg-config (>= 0.11.0)
Files: 
 $TAR_MD5 $TAR_SIZE $TAR
 3a87f741df05dcb7fe5723b22dc40969 20372 gst-plugins-bad0.10_$BADVERSION~git$DATE.debian.tar.gz
EOF

dpkg-source -x $DSC

cd gst-plugins-bad0.10-$BADVERSION~git$DATE
bumplog gst-plugins-bad0.10 $BADVERSION
build


# Build gst-plugins-ugly
###############################################################################
cd $OUTPUT
UGLYVERSION=0.10.18.1

getsource gst-plugins-ugly libtoolize.patch

TAR=gst-plugins-ugly0.10_$UGLYVERSION~git$DATE.orig.tar.gz
cp gst-plugins-ugly/gst-plugins-ugly-$UGLYVERSION.tar.gz $TAR
TAR_MD5=`md5sum $TAR | sed -e's/ .*//'`
TAR_SIZE=`du -b $TAR | sed -e's/\s.*//'`

cp $ROOT/gst-plugins-ugly-debian.tar.gz gst-plugins-ugly0.10_$UGLYVERSION~git$DATE.debian.tar.gz

DSC=gst-plugins-ugly0.10_$UGLYVERSION~git$DATE.dsc
cat > $DSC <<EOF 
Format: 3.0 (quilt)
Source: gst-plugins-ugly0.10
Binary: gstreamer0.10-plugins-ugly-doc, gstreamer0.10-plugins-ugly, gstreamer0.10-plugins-ugly-dbg
Architecture: any
Version: $UGLYVERSION~git$DATE
Maintainer: Maintainers of GStreamer packages <pkg-gstreamer-maintainers@lists.alioth.debian.org>
Uploaders: Loic Minier <lool@dooz.org>, Sebastian Dröge <slomo@debian.org>
Standards-Version: 3.8.4
Build-Depends: autopoint | gettext, autotools-dev, cdbs (>= 0.4.20), debhelper (>= 7), dh-autoreconf, dpkg-dev (>= 1.15.1), libgstreamer0.10-dev (= $BASEVERSION~git$DATE), gstreamer0.10-doc, gstreamer0.10-plugins-base, gstreamer0.10-plugins-base-doc, gstreamer-tools (= $BASEVERSION~git$DATE), gtk-doc-tools, liba52-0.7.4-dev, libcdio-dev (>= 0.76), libdvdread-dev (>= 0.9.0), libglib2.0-dev (>= 2.20), libgstreamer-plugins-base0.10-dev (= $BASEVERSION~git$DATE), libid3tag0-dev, libmad0-dev (>= 0.15), libmpeg2-4-dev (>= 0.4.0), libopencore-amrnb-dev, libopencore-amrwb-dev, liborc-0.4-dev (>= 1:0.4.6), libsidplay1-dev, libtwolame-dev (>= 0.3.10), pkg-config (>= 0.11.0)
Files: 
 $TAR_MD5 $TAR_SIZE $TAR
 7ccb867c72f4ddc3606167077f9b9787 26391 gst-plugins-ugly0.10_$UGLYVERSION~git$DATE.debian.tar.gz
EOF


dpkg-source -x $DSC

cd gst-plugins-ugly0.10-$UGLYVERSION~git$DATE
bumplog gst-plugins-ugly0.10 $UGLYVERSION
build

# Build gst-ffmpeg
###############################################################################
cd $OUTPUT
FFMPEGVERSION=0.10.11.2
getsource gst-ffmpeg libtoolize.patch

TAR=gstreamer0.10-ffmpeg_$FFMPEGVERSION~git$DATE.orig.tar.gz
cp gst-ffmpeg/gst-ffmpeg-$FFMPEGVERSION.tar.gz $TAR
TAR_MD5=`md5sum $TAR | sed -e's/ .*//'`
TAR_SIZE=`du -b $TAR | sed -e's/\s.*//'`

cp $ROOT/gstreamer-ffmpeg-debian.tar.gz gstreamer0.10-ffmpeg_$FFMPEGVERSION~git$DATE.debian.tar.gz

DSC=gstreamer0.10-ffmpeg_$FFMPEGVERSION~git$DATE.dsc
cat > $DSC <<EOF
Format: 3.0 (quilt)
Source: gstreamer0.10-ffmpeg
Binary: gstreamer0.10-ffmpeg, gstreamer0.10-ffmpeg-dbg
Architecture: any
Version: $FFMPEGVERSION~git$DATE
Maintainer: Maintainers of GStreamer packages <pkg-gstreamer-maintainers@lists.alioth.debian.org>
Uploaders: David I. Lehn <dlehn@debian.org>,           Loic Minier <lool@dooz.org>,           Sebastian Dröge <slomo@debian.org>,           Sjoerd Simons <sjoerd@debian.org>
Standards-Version: 3.8.4
Build-Depends: debhelper (>= 7), cdbs (>= 0.4.8), autotools-dev, zlib1g-dev, libglib2.0-dev (>= 2.4.0), pkg-config (>= 0.11.0), libgstreamer0.10-dev (= $BASEVERSION~git$DATE), libgstreamer-plugins-base0.10-dev (= $BASEVERSION~git$DATE), liborc-0.4-dev (>= 0.4.5), gstreamer-tools (= $BASEVERSION~git$DATE), libbz2-dev, lsb-release
Files: 
 $TAR_MD5 $TAR_SIZE $TAR
 134541939457e654f5dde561da0b1a86 9344 gstreamer0.10-ffmpeg_$FFMPEGVERSION~git$DATE.debian.tar.gz
EOF

dpkg-source -x $DSC

cd gstreamer0.10-ffmpeg-$FFMPEGVERSION~git$DATE
bumplog gstreamer0.10-ffmpeg $FFMPEGVERSION
build

# Build gst-python
###############################################################################
cd $OUTPUT
PYTHONVERSION=0.10.21.1
getsource gst-python libtoolize.patch

TAR=gst0.10-python_$PYTHONVERSION~git$DATE.orig.tar.gz
cp gst-python/gst-python-$PYTHONVERSION.tar.gz $TAR
TAR_MD5=`md5sum $TAR | sed -e's/ .*//'`
TAR_SIZE=`du -b $TAR | sed -e's/\s.*//'`

cp $ROOT/gst-python-debian.tar.gz gst0.10-python_$PYTHONVERSION~git$DATE.debian.tar.gz

DSC=gst0.10-python_$PYTHONVERSION~git$DATE.dsc
cat > $DSC <<EOF
Format: 3.0 (quilt)
Source: gst0.10-python
Binary: python-gst0.10, python-gst0.10-dev, python-gst0.10-dbg
Architecture: any
Version: $PYTHONVERSION~git$DATE
Maintainer: Maintainers of GStreamer packages <pkg-gstreamer-maintainers@lists.alioth.debian.org>
Uploaders: Loic Minier <lool@dooz.org>,           Sebastian Dröge <slomo@debian.org>
Homepage: http://gstreamer.freedesktop.org
Standards-Version: 3.8.4
Build-Depends: debhelper (>= 7), pkg-config, libgstreamer0.10-dev (= $BASEVERSION~git$DATE), libgstreamer-plugins-base0.10-dev (= $BASEVERSION~git$DATE), gstreamer0.10-plugins-base, libxml2-utils, xmlto, libx11-dev, python-dev, python-gobject-dev (>= 2.11.2), python-gobject-dbg, python-all-dev (>= 2.3.5-11), python-all-dbg, python-central (>= 0.6.11), autotools-dev
Python-Version: >= 2.3
Files: 
 $TAR_MD5 $TAR_SIZE $TAR
 5e376af97c5e2ad3a64cd96b5148d29f 10060 gst0.10-python_$PYTHONVERSION~git$DATE.debian.tar.gz
EOF

dpkg-source -x $DSC
cd gst0.10-python-$PYTHONVERSION~git$DATE
bumplog gst0.10-python $PYTHONVERSION
build
