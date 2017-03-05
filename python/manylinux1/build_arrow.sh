#!/bin/bash
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License. See accompanying LICENSE file.
#
# Usage:
#   docker run --rm -v $PWD:/io arrow-base-x86_64 /io/build_arrow.sh
# or with Parquet support
#   docker run --rm -v $PWD:/io parquet_arrow-base-x86_64 /io/build_arrow.sh

# Build upon the scripts in https://github.com/matthew-brett/manylinux-builds
# * Copyright (c) 2013-2016, Matt Terry and Matthew Brett (BSD 2-clause)

PYTHON_VERSIONS="${PYTHON_VERSIONS:-2.7 3.4 3.5 3.6}"

# Package index with only manylinux1 builds
MANYLINUX_URL=https://nipy.bic.berkeley.edu/manylinux

source /multibuild/manylinux_utils.sh

cd /arrow/python

# PyArrow build configuration
export PYARROW_BUILD_TYPE='release'
export PYARROW_CMAKE_OPTIONS='-DPYARROW_BUILD_TESTS=ON'
export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_JEMALLOC=1
export PYARROW_BUNDLE_ARROW_CPP=1
# Need as otherwise arrow_io is sometimes not linked
export LDFLAGS="-Wl,--no-as-needed"
export ARROW_HOME="/arrow-dist"
export PARQUET_HOME="/usr"

# Ensure the target directory exists
mkdir -p /io/dist

for PYTHON in ${PYTHON_VERSIONS}; do
    PYTHON_INTERPRETER="$(cpython_path $PYTHON)/bin/python"
    PIP="$(cpython_path $PYTHON)/bin/pip"
    PIPI_IO="$PIP install -f $MANYLINUX_URL"
    PATH="$PATH:$(cpython_path $PYTHON)"

    echo "=== (${PYTHON}) Installing build dependencies ==="
    $PIPI_IO "numpy==1.9.0"
    $PIPI_IO "cython==0.24"

    # Clear output directory
    rm -rf dist/
    echo "=== (${PYTHON}) Building wheel ==="
    PATH="$PATH:$(cpython_path $PYTHON)/bin" $PYTHON_INTERPRETER setup.py build_ext --inplace --with-parquet --with-jemalloc --bundle-arrow-cpp
    PATH="$PATH:$(cpython_path $PYTHON)/bin" $PYTHON_INTERPRETER setup.py bdist_wheel

    echo "=== (${PYTHON}) Test the existence of optional modules ==="
    $PIPI_IO -r requirements.txt
    PATH="$PATH:$(cpython_path $PYTHON)/bin" $PYTHON_INTERPRETER -c "import pyarrow.parquet"
    PATH="$PATH:$(cpython_path $PYTHON)/bin" $PYTHON_INTERPRETER -c "import pyarrow.jemalloc"

    echo "=== (${PYTHON}) Tag the wheel with manylinux1 ==="
    mkdir -p repaired_wheels/
    auditwheel -v repair -L . dist/pyarrow-*.whl -w repaired_wheels/

    echo "=== (${PYTHON}) Testing manylinux1 wheel ==="
    # Fix version to keep build reproducible"
    $PIPI_IO "virtualenv==15.1.0"
    rm -rf venv
    "$(cpython_path $PYTHON)/bin/virtualenv" -p ${PYTHON_INTERPRETER} --no-download venv
    source ./venv/bin/activate
    pip install repaired_wheels/*.whl
    pip install pytest pandas
    py.test venv/lib/*/site-packages/pyarrow
    deactivate

    mv repaired_wheels/*.whl /io/dist
done

