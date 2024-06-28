# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..13} pypy3 )

inherit distutils-r1 pypi

DESCRIPTION="Python library to work with pdf files based on qpdf"
HOMEPAGE="
	https://github.com/pikepdf/pikepdf/
	https://pypi.org/project/pikepdf/
"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~loong ~ppc ppc64 ~riscv ~s390 ~sparc x86"
IUSE="big-endian"

# Check QPDF_MIN_VERSION in pyproject.toml on bumps, as well as
# https://qpdf.readthedocs.io/en/stable/release-notes.html.
DEPEND="
	>=app-text/qpdf-11.5.0:0=
"
RDEPEND="
	${DEPEND}
	dev-python/deprecated[${PYTHON_USEDEP}]
	>=dev-python/lxml-4.0[${PYTHON_USEDEP}]
	dev-python/packaging[${PYTHON_USEDEP}]
	>=dev-python/pillow-10.0.1[lcms,${PYTHON_USEDEP}]
"
BDEPEND="
	>=dev-python/pybind11-2.10.1[${PYTHON_USEDEP}]
	>=dev-python/setuptools-scm-7.0.5[${PYTHON_USEDEP}]
	test? (
		>=dev-python/attrs-20.2.0[${PYTHON_USEDEP}]
		>=dev-python/hypothesis-6.36[${PYTHON_USEDEP}]
		>=dev-python/numpy-1.21.0[${PYTHON_USEDEP}]
		>=dev-python/pillow-5.0.0[${PYTHON_USEDEP},jpeg,lcms,tiff]
		>=dev-python/psutil-5.9[${PYTHON_USEDEP}]
		>=dev-python/pytest-timeout-2.1.0[${PYTHON_USEDEP}]
		>=dev-python/python-dateutil-2.8.1[${PYTHON_USEDEP}]
		!big-endian? (
			>=dev-python/python-xmp-toolkit-2.0.1[${PYTHON_USEDEP}]
		)
		$(python_gen_cond_dep '
			dev-python/tomli[${PYTHON_USEDEP}]
		' 3.10)
		media-libs/tiff[zlib]
	)
"

distutils_enable_tests pytest

EPYTEST_DESELECT=(
	# fragile to system load
	tests/test_image_access.py::test_random_image
)

src_prepare() {
	local PATCHES=(
		# https://github.com/pikepdf/pikepdf/commit/6831e87bb94322b7ca53964a57ba575861b5916c
		"${FILESDIR}/${P}-py313.patch"
	)

	distutils-r1_src_prepare

	sed -e '/-n auto/d' -i pyproject.toml || die
}

python_test() {
	local -x PYTEST_DISABLE_PLUGIN_AUTOLOAD=1
	epytest -p timeout
}
