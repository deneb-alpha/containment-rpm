#!/bin/bash

if [ -z "$1" ]; then
  cat <<EOF
usage:
  ./make_spec.sh PACKAGE [BRANCH]
EOF
  exit 1
fi

cd $(dirname $0)

YEAR=$(date +%Y)
VERSION=$(git describe --abbrev=0 --tags)
# remove "v"
VERSION=$(echo $VERSION | sed -e "s/v//g")
REVISION=$(git rev-list HEAD | wc -l)
COMMIT=$(git rev-parse --short HEAD)
VERSION="${VERSION%+*}+git_r${REVISION}_${COMMIT}"
NAME=$1
BRANCH=${2:-master}
SAFE_BRANCH=${BRANCH//\//-}

cat <<EOF > ${NAME}.spec
#
# spec file for package containment-rpm
#
# Copyright (c) $YEAR SUSE LLC and contributors
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via https://bugs.opensuse.org/
#


Name:           $NAME
Version:        $VERSION
Release:        0
Summary:        Wraps OBS docker/kiwi-built images in rpms
License:        MIT
Group:          System/Management
URL:            https://github.com/SUSE/containment-rpm
Source:         ${SAFE_BRANCH}.tar.gz
BuildRequires:  filesystem
Requires:       jq
Requires:       libxml2-tools
BuildArch:      noarch
# disabled for now, not used for public cloud purpose
%if 0
Requires:       changelog-generator-data
Requires:       libxml2-tools
%if 0%{?suse_version} >= 1230
Requires:       rubygem(changelog_generator)
%else
Requires:       rubygem-changelog_generator
%endif
%endif
# Conflicts with other packages that provide /usr/lib/build/kiwi_post_run
Conflicts:      infos-creator-rpm

%description
OBS kiwi_post_run hook to wrap a kiwi-produced image in an rpm package.

This package should be required by the Build Service project's meta
prjconf, so that the kiwi_post_run hook is present in the kiwi image
and gets executed at the end of the image build.  It will then build
an rpm which contains the newly-produced image from kiwi (using
image.spec.in), and place the rpm in the correct location that it
becomes an additional build artefact.

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{_prefix}/lib/build/post_build.d
install -m 644 image.spec.in %{buildroot}%{_prefix}/lib/build/
install -m 755 container_post_run %{buildroot}%{_prefix}/lib/build/post_build.d/

%files
%dir %{_prefix}/lib/build/post_build.d
%{_prefix}/lib/build/post_build.d/*_post_run
%{_prefix}/lib/build/image.spec.in

%changelog
EOF
