#
# spec file for package hawk
#
# Copyright (c) 2015 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


%if 0%{?suse_version}
%define	www_base	/srv/www
%define	vendor_ruby	vendor_ruby
%define	init_style	suse
%define	pkg_group	Productivity/Clustering/HA
%else
%define	www_base	/var/www
%define	vendor_ruby	site_ruby
%define	init_style	redhat
%define	pkg_group	System Environment/Daemons
%endif

%if 0%{?suse_version} == 1110 || 0%{?suse_version} == 1315
%define bundle_gems	1
%endif

%define	gname		haclient
%define	uname		hacluster

Name:           hawk
Summary:        HA Web Konsole
License:        GPL-2.0
Group:          %{pkg_group}
Version:        0.7.0+git.1424258458.f83efc0
Release:        0
Url:            http://www.clusterlabs.org/wiki/Hawk
Source:         %{name}-%{version}.tar.bz2
%if 0%{?suse_version}
Source1:        filter-requires.sh
%define         _use_internal_dependency_generator 0
%define         __find_requires /bin/sh %{SOURCE1}
%endif
Source100:      hawk-rpmlintrc
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Requires:       crmsh
Requires:       graphviz
Requires:       graphviz-gd
Requires:       hawk-templates >= %{version}-%{release}
Requires:       lighttpd >= 1.4.20
Requires:       pacemaker >= 1.1.8
Requires:       ruby
%if 0%{?fedora_version} >= 19
Requires:       rubypick
BuildRequires:  rubypick
%endif
Requires:       rubygem(bundler)
%if 0%{?suse_version}
Recommends:     graphviz-gnome
Requires:       iproute2
PreReq:         permissions
BuildRequires:  fdupes
BuildRequires:  libpacemaker-devel
%{?systemd_requires}
%if 0%{?suse_version} >= 1210
BuildRequires:  systemd
%endif
%else
Requires:       iproute
Requires:       lighttpd-fastcgi
BuildRequires:  pacemaker-libs-devel
%endif

BuildRequires:  rubygems
BuildRequires:  rubygem(byebug)
BuildRequires:  rubygem(fast_gettext)
BuildRequires:  rubygem(gettext)
BuildRequires:  rubygem(gettext_i18n_rails)
BuildRequires:  rubygem(quiet_assets)
BuildRequires:  rubygem(rails) >= 4
BuildRequires:  rubygem(rake)
BuildRequires:  rubygem(spring)
BuildRequires:  rubygem(sprockets)
BuildRequires:  rubygem(tilt)
BuildRequires:  rubygem(web-console)
%if 0%{?bundle_gems}
%if 0%{?suse_version} == 1110
BuildRequires:  ruby-fcgi
%endif
%else
# SLES bundles all this stuff at build time, other distros just
# use runtime dependencies.
Requires:       rubygems
Requires:       rubygem(fast_gettext)
Requires:       rubygem(gettext_i18n_rails)
Requires:       rubygem(rails) >= 4
Requires:       rubygem(rake)
Requires:       rubygem(sprockets)
Requires:       rubygem(tilt)
# Not using this right now (seems to be unavailable due to ruby 2.0 --> 2.1 migration on Factory)
#%%if 0%{?suse_version}
#Requires:       rubygem-ruby-fcgi
#%%endif
%endif

BuildRequires:  glib2-devel
BuildRequires:  libxml2-devel
BuildRequires:  pam-devel

%description
A web-based GUI for managing and monitoring the Pacemaker
High-Availability cluster resource manager.

Authors: Tim Serong <tserong@suse.com>


%package templates
Summary:        Hawk Setup Wizard Templates
Group:          Productivity/Clustering/HA

%description templates
Template files for Hawk's cluster setup wizard.

Authors: Tim Serong <tserong@suse.com>


%prep
%setup

%build
CFLAGS="${CFLAGS} ${RPM_OPT_FLAGS}"
export CFLAGS
make WWW_BASE=%{www_base} INIT_STYLE=%{init_style} LIBDIR=%{_libdir} BINDIR=%{_bindir} SBINDIR=%{_sbindir} BUNDLE_GEMS=%{expand:%{?bundle_gems:true}%{!?bundle_gems:false}}

%install
make WWW_BASE=%{www_base} INIT_STYLE=%{init_style} DESTDIR=%{buildroot} install
# copy of GPL
cp COPYING %{buildroot}%{www_base}/hawk/
%if 0%{?bundle_gems}
# evil magic to get ruby-fcgi into the vendor directory
for f in $(rpm -ql ruby-fcgi|grep %{vendor_ruby}); do
	# gives something simliar to:
	#  /usr/lib64/ruby/vendor_ruby/1.8/fcgi.rb
	#  /usr/lib64/ruby/vendor_ruby/1.8/x86_64-linux/fcgi.so
	r=$(echo $f | sed 's/.*%{vendor_ruby}\/[^\/]*\///')
	mkdir -p %{buildroot}%{www_base}/hawk/vendor/$(dirname $r)
	cp $f %{buildroot}%{www_base}/hawk/vendor/$r
done
# get rid of gem sample and test cruft
rm -rf %{buildroot}%{www_base}/hawk/vendor/bundle/ruby/*/gems/*/doc
rm -rf %{buildroot}%{www_base}/hawk/vendor/bundle/ruby/*/gems/*/examples
rm -rf %{buildroot}%{www_base}/hawk/vendor/bundle/ruby/*/gems/*/samples
rm -rf %{buildroot}%{www_base}/hawk/vendor/bundle/ruby/*/gems/*/test
%endif
%if 0%{?suse_version}

# Hack so missing links to docs don't kill the build
mkdir -p %{buildroot}/usr/share/doc/manual/sle-ha-geo-quick_en-pdf
mkdir -p %{buildroot}/usr/share/doc/manual/sle-ha-guide_en-pdf
mkdir -p %{buildroot}/usr/share/doc/manual/sle-ha-manuals_en
mkdir -p %{buildroot}/usr/share/doc/manual/sle-ha-geo-manuals_en
mkdir -p %{buildroot}/usr/share/doc/manual/sle-ha-nfs-quick_en-pdf

# mark .mo files as such (works on SUSE but not FC12, as the latter wants directory to
# be "share/locale", not just "locale", and it also doesn't support appending to %%{name}.lang)
%find_lang %{name} %{name}.lang
# don't ship .po files (find_lang only grabs the mos, and we don't need the pos anyway)
rm %{buildroot}%{www_base}/hawk/locale/*/hawk.po
rm %{buildroot}%{www_base}/hawk/locale/*/hawk.po.time_stamp
rm %{buildroot}%{www_base}/hawk/locale/*/hawk.edit.po
# hard link duplicate files
%fdupes %{buildroot}
%else
# Need file to exist else %%files fails later
touch %{name}.lang
%endif
# more cruft to clean up (WTF?)
rm -f %{buildroot}%{www_base}/hawk/log/*
# likewise .git special files
find %{buildroot}%{www_base}/hawk -type f -name '.git*' -print0 | xargs --no-run-if-empty -0 rm
%if 0%{?suse_version}
%{__ln_s} -f %{_sbindir}/service %{buildroot}%{_sbindir}/rchawk
%endif

%clean
rm -rf %{buildroot}

%if 0%{?suse_version}
# TODO(must): Determine sensible non-SUSE versions of these,
# in particular restart_on_update and stop_on_removal.

%verifyscript
%verify_permissions -e %{_sbindir}/hawk_chkpwd
%verify_permissions -e %{_sbindir}/hawk_invoke

%pre
%service_add_pre hawk.service

%post
%set_permissions %{_sbindir}/hawk_chkpwd
%set_permissions %{_sbindir}/hawk_invoke
%service_add_post hawk.service

%preun
%service_del_preun hawk.service

%postun
%service_del_postun hawk.service

%triggerin -- lighttpd
%restart_on_update hawk
%endif

%files -f %{name}.lang
%defattr(-,root,root)
%attr(4750, root, %{gname})%{_sbindir}/hawk_chkpwd
%attr(4750, root, %{gname})%{_sbindir}/hawk_invoke
%{_sbindir}/hawk_monitor
%dir %{www_base}/hawk
%{www_base}/hawk/app
%{www_base}/hawk/config
# Packaged in hawk-templates
%exclude %{www_base}/hawk/config/wizard
%{www_base}/hawk/db
%{www_base}/hawk/lib
%attr(0750, %{uname},%{gname})%{www_base}/hawk/log
%dir %attr(0750, %{uname},%{gname})%{www_base}/hawk/tmp
%attr(0750, %{uname},%{gname})%{www_base}/hawk/tmp/cache
%attr(0770, %{uname},%{gname})%{www_base}/hawk/tmp/explorer
%attr(0770, %{uname},%{gname})%{www_base}/hawk/tmp/explorer/uploads
%attr(0770, %{uname},%{gname})%{www_base}/hawk/tmp/home
%attr(0750, %{uname},%{gname})%{www_base}/hawk/tmp/pids
%attr(0750, %{uname},%{gname})%{www_base}/hawk/tmp/sessions
%attr(0750, %{uname},%{gname})%{www_base}/hawk/tmp/sockets
%exclude %{www_base}/hawk/tmp/session_secret
%{www_base}/hawk/locale/hawk.pot
%if 0%{?bundle_gems}
%{www_base}/hawk/.bundle
%endif
%{www_base}/hawk/public
%{www_base}/hawk/Rakefile
%if 0%{?bundle_gems}
%{www_base}/hawk/Gemfile
%{www_base}/hawk/Gemfile.lock
%else
%exclude %{www_base}/hawk/Gemfile
%exclude %{www_base}/hawk/Gemfile.lock
%endif
%{www_base}/hawk/COPYING
%{www_base}/hawk/config.ru
%{www_base}/hawk/bin
%{www_base}/hawk/test
%if 0%{?suse_version}
# itemizing content in %%{www_base}/hawk/locale to avoid
# duplicate files that would otherwise be the result of including hawk.lang
%dir %{www_base}/hawk/locale
%dir %{www_base}/hawk/locale/*
%dir %{www_base}/hawk/locale/*/*
%else
%{www_base}/hawk/locale
%endif

%if 0%{?bundle_gems}
# Not doing this itemization for %%lang files in vendor, it's frightfully
# hideous, so we're going to live with a handful of file-not-in-%%lang rpmlint
# warnings for bundled gems.
%{www_base}/hawk/vendor
%endif
%{_unitdir}/hawk.service
%if 0%{?suse_version}
%attr(-,root,root) %{_sbindir}/rchawk
%endif

%files templates
%defattr(-,root,root)
%{www_base}/hawk/config/wizard

%changelog
