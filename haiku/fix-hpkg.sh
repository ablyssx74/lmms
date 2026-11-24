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
#  - lib/libcarla_native-plugin.so links to the dummy Carla library in
#    lib/lmms/optional/, which the Carla plugins need and the loader does not
#    search (a build with the CMake change in plugins/Carla* does not need it).
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
mkdir -p lib
ln -sf ../apps/LMMS/lib/lmms/optional/libcarla_native-plugin.so lib/libcarla_native-plugin.so
ver=$(sed -n 's/^version[[:space:]]*//p' .PackageInfo | head -1)
out="$(dirname "$in")/lmms-$ver-x86_64.hpkg"
package create -C . "$out"
cd /; rm -rf "$dir"
echo "$out"
