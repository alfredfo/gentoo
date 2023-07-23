# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
inherit cmake cross flag-o-matic llvm llvm.org python-any-r1 toolchain-funcs

DESCRIPTION="The LLVM C Library"
HOMEPAGE="https://libc.llvm.org"

LICENSE="Apache-2.0-with-LLVM-exceptions"
SLOT="${LLVM_MAJOR}"
KEYWORDS=""
IUSE="headers-only test"

DEPEND="
		sys-devel/llvm:${LLVM_MAJOR}
"
BDEPEND="
		>=dev-util/cmake-3.16
		sys-apps/libc-hdrgen
"

# compiler-rt is needed for the SCUDO allocator used by llvm-libc
# s/llvm/runtimes for runtimes build
LLVM_COMPONENTS=( runtimes libc compiler-rt/lib/scudo/standalone cmake llvm/cmake )
llvm.org_set_globals

pkg_setup() {
	python-any-r1_pkg_setup
}

# runtimes/ seems like the right root src directory to use for cross compiling
# llvm-libc and building the CBUILD tools standalone.
# However, there's no way to build SCUDO in CMake when using it,
# so this is a temporary terrible fix.
SCUDO_SOURCES=(
	checksum.cpp
	common.cpp
	crc32_hw.cpp
	flags_parser.cpp
	flags.cpp
	fuchsia.cpp
	linux.cpp
	mem_map.cpp
	mem_map_fuchsia.cpp
	release.cpp
	report.cpp
	rss_limit_checker.cpp
	string_utils.cpp
	wrappers_c.cpp
)

franken_build_scudo_standalone() {
	mkdir "${WORKDIR}"/scudo_build
	for i in "${SCUDO_SOURCES[@]}" ;
	do
		$(tc-getCC) ${CFLAGS} -std=c++17 -mcrc32 -O2 -static -fno-exceptions \
					-nostdlib++ -ffreestanding -I ${WORKDIR}/compiler-rt/lib/scudo/standalone/include \
					-c "${WORKDIR}/compiler-rt/lib/scudo/standalone/${i}" -o "${WORKDIR}/scudo_build/${i}.o"
	done
}

append_scudo_objects() {
	for i in "${WORKDIR}"/scudo_build/*.o; do
		echo "${i}"
		$(tc-getAR) rs "${BUILD_DIR}/libc/lib/libc.a" "${i}"
	done
}

src_configure() {
	BUILD_DIR=${WORKDIR}/${P}_build

	local mycmakeargs=(
		-DLLVM_ENABLE_RUNTIMES=libc
		-DLLVM_LIBC_FULL_BUILD=ON

		# Do not bundle llvm-libc's libc-hdrgen
		-DLIBC_HDRGEN_EXE="${BROOT}/usr/bin/libc-hdrgen"
		-DLLVM_INCLUDE_TESTS=$(usex test)
		-DPython3_EXECUTABLE="${PYTHON}"
	)
	if ! use headers-only ; then
		franken_build_scudo_standalone
		# This is how you do it with llvm/ as root src directory
		# mycmakeargs+=(
		# 	# For SCUDO
		# 	-DLLVM_LIBC_INCLUDE_SCUDO=ON
		# 	-DCOMPILER_RT_BUILD_SCUDO_STANDALONE_WITH_LLVM_LIBC=ON
		# 	-DCOMPILER_RT_BUILD_GWP_ASAN=OFF
		# 	-DCOMPILER_RT_SCUDO_STANDALONE_BUILD_SHARED=OFF
		# )
	fi
	if is_crosscompile || use headers-only ; then
		mycmakeargs+=(
			-DCMAKE_C_COMPILER_WORKS=1
			-DCMAKE_CXX_COMPILER_WORKS=1
			-DCMAKE_INSTALL_PREFIX="/usr/${CTARGET}/usr"
		)
	fi
	cmake_src_configure
}

src_compile() {
	use headers-only || cmake_src_compile libc libc-startup libm
}

src_install() {
	if use headers-only ; then
		DESTDIR="${D}" cmake_build install-libc-headers
	else
		append_scudo_objects
		cmake_src_install install-libc
	fi
}
