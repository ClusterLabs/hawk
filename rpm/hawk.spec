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
Version:        1.0.0~alpha1+git.1442580882.11cc227
Release:        0
Url:            http://www.clusterlabs.org/wiki/Hawk
Source:         %{name}-%{version}.tar.bz2
Source100:      hawk-rpmlintrc
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Provides:       ha-cluster-webui
Requires:       crmsh
Requires:       graphviz
Requires:       graphviz-gd
# Need a font of some kind for graphviz to work correctly (bsc#931950)
Requires:       dejavu
Requires:       pacemaker >= 1.1.8
%if 0%{?fedora_version} >= 19
Requires:       rubypick
BuildRequires:  rubypick
%endif
Requires:       rubygem(%{rb_default_ruby_abi}:bundler)
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
BuildRequires:  pacemaker-libs-devel
%endif

BuildRequires:  rubygem(%{rb_default_ruby_abi}:builder) >= 3.2
BuildRequires:  rubygem(%{rb_default_ruby_abi}:byebug) >= 3.5
BuildRequires:  rubygem(%{rb_default_ruby_abi}:fast_gettext:0.9)
BuildRequires:  rubygem(%{rb_default_ruby_abi}:gettext:3.1)
BuildRequires:  rubygem(%{rb_default_ruby_abi}:gettext_i18n_rails:1.2)
BuildRequires:  rubygem(%{rb_default_ruby_abi}:gettext_i18n_rails_js)
BuildRequires:  rubygem(%{rb_default_ruby_abi}:haml-rails) >= 0.8.2
BuildRequires:  rubygem(%{rb_default_ruby_abi}:hashie) >= 3.4
BuildRequires:  rubygem(%{rb_default_ruby_abi}:js-routes:1)
BuildRequires:  rubygem(%{rb_default_ruby_abi}:kramdown:1) >= 1.3
BuildRequires:  rubygem(%{rb_default_ruby_abi}:mail) >= 2.6
BuildRequires:  rubygem(%{rb_default_ruby_abi}:mime-types) >= 2.5
BuildRequires:  rubygem(%{rb_default_ruby_abi}:minitest) >= 5.6
BuildRequires:  rubygem(%{rb_default_ruby_abi}:puma:2) >= 2.11
BuildRequires:  rubygem(%{rb_default_ruby_abi}:rails:4.2)
BuildRequires:  rubygem(%{rb_default_ruby_abi}:ruby_parser) >= 3.6.6
BuildRequires:  rubygem(%{rb_default_ruby_abi}:sass) >= 3.4
BuildRequires:  rubygem(%{rb_default_ruby_abi}:sass-rails) >= 5.0.1
BuildRequires:  rubygem(%{rb_default_ruby_abi}:sexp_processor) >= 4.5.1
BuildRequires:  rubygem(%{rb_default_ruby_abi}:spring:1) >= 1.3
BuildRequires:  rubygem(%{rb_default_ruby_abi}:virtus)

%if 0%{?suse_version} <= 1310
BuildRequires:  rubygem(%{rb_default_ruby_abi}:rake:10.4)
%endif

BuildRequires:  rubygem(%{rb_default_ruby_abi}:spring:1) >= 1.3
BuildRequires:  rubygem(%{rb_default_ruby_abi}:sprockets) >= 3.0
BuildRequires:  rubygem(%{rb_default_ruby_abi}:thor) >= 0.19
BuildRequires:  rubygem(%{rb_default_ruby_abi}:tilt:1.4)
BuildRequires:  rubygem(%{rb_default_ruby_abi}:web-console:2) >= 2.1

%if 0%{?bundle_gems}
%else
# SLES bundles all this stuff at build time, other distros just
# use runtime dependencies.
Requires:       rubygem(%{rb_default_ruby_abi}:fast_gettext:0.9)
Requires:       rubygem(%{rb_default_ruby_abi}:gettext_i18n_rails:1.2)
Requires:       rubygem(%{rb_default_ruby_abi}:gettext_i18n_rails_js)
Requires:       rubygem(%{rb_default_ruby_abi}:haml-rails) >= 0.8.2
Requires:       rubygem(%{rb_default_ruby_abi}:hashie) >= 3.4
Requires:       rubygem(%{rb_default_ruby_abi}:js-routes:1)
Requires:       rubygem(%{rb_default_ruby_abi}:kramdown:1) >= 1.3
Requires:       rubygem(%{rb_default_ruby_abi}:puma:2) >= 2.11
Requires:       rubygem(%{rb_default_ruby_abi}:rails:4.2)
Requires:       rubygem(%{rb_default_ruby_abi}:sass-rails:5.0) >= 5.0.1
Requires:       rubygem(%{rb_default_ruby_abi}:sass:3.4)
Requires:       rubygem(%{rb_default_ruby_abi}:sexp_processor) >= 4.5.1
Requires:       rubygem(%{rb_default_ruby_abi}:sprockets) >= 3.0
Requires:       rubygem(%{rb_default_ruby_abi}:tilt:1.4)
Requires:       rubygem(%{rb_default_ruby_abi}:virtus:1.0)

%if 0%{?suse_version} <= 1310
Requires:       rubygem(%{rb_default_ruby_abi}:rake:10.4)
%endif

%endif

BuildRequires:  %{rubydevel >= 1.8.7}
BuildRequires:  git
BuildRequires:  glib2-devel
BuildRequires:  libxml2-devel >= 2.6.21
BuildRequires:  libxslt-devel
BuildRequires:  openssl-devel
BuildRequires:  pam-devel

%description
A web-based GUI for managing and monitoring the Pacemaker
High-Availability cluster resource manager.

Authors: Tim Serong <tserong@suse.com>


%prep
%setup

%build
export NOKOGIRI_USE_SYSTEM_LIBRARIES=1
CFLAGS="${CFLAGS} ${RPM_OPT_FLAGS}"
export CFLAGS
make WWW_BASE=%{www_base} INIT_STYLE=%{init_style} LIBDIR=%{_libdir} BINDIR=%{_bindir} SBINDIR=%{_sbindir} BUNDLE_GEMS=%{expand:%{?bundle_gems:true}%{!?bundle_gems:false}} RUBY_ABI=%{rb_ver}

%install
make WWW_BASE=%{www_base} INIT_STYLE=%{init_style} DESTDIR=%{buildroot} BUNDLE_GEMS=%{expand:%{?bundle_gems:true}%{!?bundle_gems:false}} install
# copy of GPL
cp COPYING %{buildroot}%{www_base}/hawk/
%if 0%{?bundle_gems}
# get rid of gem sample and test cruft
rm -rf %{buildroot}%{www_base}/hawk/vendor/bundle/ruby/*/gems/*/doc
rm -rf %{buildroot}%{www_base}/hawk/vendor/bundle/ruby/*/gems/*/examples
rm -rf %{buildroot}%{www_base}/hawk/vendor/bundle/ruby/*/gems/*/samples
rm -rf %{buildroot}%{www_base}/hawk/vendor/bundle/ruby/*/gems/*/test
rm -rf %{buildroot}%{www_base}/hawk/vendor/bundle/ruby/*/gems/*/ports
rm -rf %{buildroot}%{www_base}/hawk/vendor/bundle/ruby/*/gems/*/ext
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
%find_lang hawk hawk.lang
# don't ship .po files (find_lang only grabs the mos, and we don't need the pos anyway)
rm %{buildroot}%{www_base}/hawk/locale/*/hawk.po
rm %{buildroot}%{www_base}/hawk/locale/*/hawk.po.time_stamp
rm %{buildroot}%{www_base}/hawk/locale/*/hawk.edit.po
# hard link duplicate files
%fdupes %{buildroot}
%else
# Need file to exist else %%files fails later
touch hawk.lang
%endif
# more cruft to clean up (WTF?)
rm -f %{buildroot}%{www_base}/hawk/log/*
# likewise .git special files
find %{buildroot}%{www_base}/hawk -type f -name '.git*' -print0 | xargs --no-run-if-empty -0 rm
%if 0%{?suse_version}
%{__ln_s} -f %{_sbindir}/service %{buildroot}%{_sbindir}/rchawk
%endif

install -p -d -m 755 %{buildroot}%{_sysconfdir}/hawk

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

%endif

%files -f hawk.lang
%defattr(-,root,root)
%attr(4750, root, %{gname})%{_sbindir}/hawk_chkpwd
%attr(4750, root, %{gname})%{_sbindir}/hawk_invoke
%{_sbindir}/hawk_monitor
%dir %{www_base}/hawk
%{www_base}/hawk/app
%{www_base}/hawk/config
%{www_base}/hawk/lib
%attr(0750, %{uname},%{gname})%{_sysconfdir}/hawk
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

# Not doing this itemization for %%lang files in vendor, it's frightfully
# hideous, so we're going to live with a handful of file-not-in-%%lang rpmlint
# warnings for bundled gems.
%{www_base}/hawk/vendor

%{_unitdir}/hawk.service
%if 0%{?suse_version}
%attr(-,root,root) %{_sbindir}/rchawk
%endif

%changelog
