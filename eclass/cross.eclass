# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: cross.eclass
# @MAINTAINER:
# cat@catcream.org
# @AUTHOR:
# Alfred Persson Forsberg <cat@catcream.org> (21 Jul 2023)
# @SUPPORTED_EAPIS: 7
# @BLURB: Utilities for cross compilation
# @DESCRIPTION: TODO

case ${EAPI} in
	7|8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ -z ${_CROSS_ECLASS} ]]; then
	_CROSS_ECLASS=1
fi

# @ECLASS_VARIABLE: _CROSS_CATEGORY_PREFIX
# @INTERNAL
# @DESCRIPTION:
# Specifies the cross category prefix.
_CROSS_CATEGORY_PREFIX=""

# @ECLASS_VARIABLE: _IS_CROSSPKG_LLVM
# @INTERNAL
# @DESCRIPTION:
# Specifies whether the package is in a LLVM cross category.
_IS_CROSSPKG_LLVM=0
if [[ ${CATEGORY} == cross_llvm-* ]] ; then
	_IS_CROSSPKG_LLVM=1
	_CROSS_CATEGORY_PREFIX="cross_llvm-"
fi
# @ECLASS_VARIABLE: _IS_CROSSPKG_GCC
# @INTERNAL
# @DESCRIPTION:
# Specifies whether the package is in a GCC cross category (default).
_IS_CROSSPKG_GCC=0
if [[ ${CATEGORY} == cross-* ]] ; then
	_IS_CROSSPKG_GCC=1
	_CROSS_CATEGORY_PREFIX="cross-"
fi

# @ECLASS_VARIABLE: _IS_CROSSPKG
# @INTERNAL
# @DESCRIPTION:
# Specifies whether the package is in a cross category.
[[ ${_IS_CROSSPKG_LLVM} || ${_IS_CROSSPKG_GCC} ]] && _IS_CROSSPKG=1

# Sets CBUILD to CHOST if CBUILD is empty or undefined
export CBUILD=${CBUILD:-${CHOST}}
# Sets CTARGET to CHOST if CBUILD is empty or undefined
export CTARGET=${CTARGET:-${CHOST}}

if [[ ${CTARGET} == ${CHOST} ]] ; then
	# The # operator removes the second argument from the
	# first if it matches ex. cross-avr -> avr.
	[[ ${_IS_CROSSPKG_GCC} ]] && CTARGET=${CATEGORY#cross-}
	[[ ${_IS_CROSSPKG_LLVM} ]] && CTARGET=${CATEGORY#cross_llvm-}
fi

# @FUNCTION: is_crosscompile
# @DESCRIPTION:
# TODO
is_crosscompile() {
	[[ ${CHOST} != ${CTARGET} ]]
}

# @FUNCTION: is_crosscompile_llvm
# @DESCRIPTION:
# TODO
is_crosscompile_llvm() {
	is_crosscompile && [[ $_IS_CROSSPKG_LLVM ]]
}

if is_crosscompile_llvm ; then
	export AR=llvm-ar
	export AS=llvm-as
	export CC="clang --config=/etc/clang/cross/${CTARGET}.cfg"
	export CXX="clang++ --config=/etc/clang/cross/${CTARGET}.cfg"
	export DLLTOOL=llvm-dlltool
	export HOSTCC="${CC:-clang}"
	export HOSTCXX="${CC:-clang++}"
	export LLVM=1
	export NM=llvm-nm
	export OBJCOPY=llvm-objcopy
	export RANLIB=llvm-ranlib
	export READELF=llvm-readelf
	export STRIP=llvm-strip
fi
