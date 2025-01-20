Name:       bluecherrydvr
Version:    3.0.0_beta22
Release:    1
Summary:    Bluecherry client written in Flutter.
License:    EULA
Requires:   mpv, mpv-libs-devel
AutoReqProv: no

%define __os_install_post %{nil}

%description
Bluecherry client written in Flutter.

%prep
# no source

%build
# no source

%install
export DONT_STRIP=1
mkdir -p %{buildroot}
cp -rf linux/debian/usr/ %{buildroot}

%files
FILES_HERE

%changelog
# no changelog