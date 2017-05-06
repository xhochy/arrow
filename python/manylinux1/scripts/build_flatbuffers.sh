#!/bin/bash -ex
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

wget https://github.com/google/flatbuffers/archive/v1.6.0.tar.gz -O flatbuffers-1.6.0.tar.gz
tar xf flatbuffers-1.6.0.tar.gz
pushd flatbuffers-1.6.0
cmake "-DCMAKE_CXX_FLAGS=-fPIC" "-DCMAKE_INSTALL_PREFIX:PATH=/usr" "-DFLATBUFFERS_BUILD_TESTS=OFF"
make -j5
make install
popd
rm -rf flatbuffers-1.6.0.tar.gz flatbuffers-1.6.0
