#!/bin/bash
# Copyright (C) 2022-2023 Vladislav Nepogodin
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

set -e

cd "`dirname "$0"`"

if [[ $1 == "--help" ]]; then
cat<<EOF
Usage: configure.sh [options]
Options:
  --help                   Display this information.
  --buildtype=, -t=        Specify build type.
  --prefix=                Specify install prefix.
  --libdir=                Specify lib directory.
  --path=, -p=             Specify build directory.
  --use_clang              Use Clang compiler.
EOF
exit 0
fi


_buildpath="build"
_prefix="/usr/local"
_libdir="lib"
_buildtype="RelWithDebInfo"
_buildfolder="${_buildpath}/${_buildtype}"
_use_clang=false
for i in "$@"; do
  case $i in
    -t=*|--buildtype=*)
      _buildtype="${i#*=}"
      _buildfolder="${_buildpath}/${_buildtype}"
      shift # past argument=value
      ;;
    --prefix=*)
      _prefix="${i#*=}"
      shift # past argument=value
      ;;
    --libdir=*)
      _libdir="${i#*=}"
      shift # past argument=value
      ;;
    -p=*|--path=*)
      _buildpath="${i#*=}"
      _buildfolder="${_buildpath}/${_buildtype}"
      shift # past argument=value
      ;;
    --use_clang)
      _use_clang=true
      shift # past argument=value
      ;;
    *)
      # unknown option
      echo "Unknown option [$i]"
      exit 255
      ;;
  esac
done

if ${_use_clang}; then
  export AR=llvm-ar
  export CC=clang
  export CXX=clang++
  export NM=llvm-nm
  export RANLIB=llvm-ranlib
fi

if command -v ninja &> /dev/null; then
  _configure_flags+=('-GNinja')
fi

cmake -S . -B ${_buildfolder} \
    -DCMAKE_BUILD_TYPE=${_buildtype} \
    -DCMAKE_INSTALL_PREFIX=${_prefix} \
    -DCMAKE_INSTALL_LIBDIR=${_libdir} \
    "${_configure_flags[@]}"

cat > build.sh <<EOF
#!/bin/bash
# Copyright (C) 2022-2023 Vladislav Nepogodin
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

set -e

cd "\`dirname "\$0"\`"

cmake --build ${_buildfolder} --parallel $(nproc)
EOF

chmod +x ./build.sh
