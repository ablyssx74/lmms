#!/bin/sh
# Make a haikuporter-built LMMS package run on Renku as well as on Haiku.
#
# usage: fix-hpkg.sh lmms-1.3.0~YYYYMMDD-N-x86_64.hpkg NEWREVISION
#
# It writes lmms-1.3.0~YYYYMMDD-NEWREVISION-x86_64.hpkg next to the original:
#  - haiku >= is lowered to hrev60072 (Renku's, older than Haiku's), because
#    haikuporter writes the version of the Haiku it was built on;
#  - bin/lmms points at the app with a relative link: the one haikuporter
#    writes has the package's version in an absolute path, which a new
#    revision breaks;
#  - the Carla plugins are taken out: there is no Carla for Haiku, and the
#    dummy library they are built against makes them load and then crash
#    when one is added to a track (a build with WANT_CARLA left to the
#    CMakeLists.txt does not make them).
set -e
in="$1"; rev="$2"
[ -f "$in" ] && [ -n "$rev" ] || { sed -n '2,15p' "$0"; exit 1; }
in=$(cd "$(dirname "$in")" && pwd)/$(basename "$in")
dir=$(mktemp -d)
package extract -C "$dir" "$in" > /dev/null
cd "$dir"
sed -i "s/haiku >= r1~beta6_hrev[0-9]*[_0-9]*-1/haiku >= r1~beta6_hrev60072-1/" .PackageInfo
sed -i "s/^\(version[[:space:]]*1\.3\.0~[0-9]*\)-[0-9]*/\1-$rev/" .PackageInfo
sed -i "s/^\(\tlmms = 1\.3\.0~[0-9]*\)-[0-9]*/\1/" .PackageInfo
ln -sf ../apps/LMMS/bin/LMMS bin/lmms
rm -f apps/LMMS/lib/lmms/libcarla*.so
rm -f apps/LMMS/lib/lmms/optional/libcarla*.so
rmdir apps/LMMS/lib/lmms/optional 2> /dev/null || true
ver=$(sed -n 's/^version[[:space:]]*//p' .PackageInfo | head -1)
out="$(dirname "$in")/lmms-$ver-x86_64.hpkg"
package create -C . "$out"
cd /; rm -rf "$dir"
echo "$out"
