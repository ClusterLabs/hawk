#
# spec file for package hawk
#
# Copyright (c) 2017 SUSE LLC, Nuernberg, Germany.
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
%define	vendor_ruby	vendor_ruby
%define	init_style	suse
%define	pkg_group	Productivity/Clustering/HA
%else
%define	vendor_ruby	site_ruby
%define	init_style	redhat
%define	pkg_group	System Environment/Daemons
%endif

%define www_base %{_datadir}
%define www_tmp  %{_localstatedir}/lib/hawk/tmp
%define www_log  %{_localstatedir}/log/hawk

%define rb_build_versions ruby25
%define rb_ruby_abi ruby:2.5.0
%define rb_ruby_suffix ruby2.5

%define	gname		haclient
%define	uname		hacluster

Name:           hawk
Summary:        HA Web Konsole
License:        GPL-2.0
Group:          %{pkg_group}
Version:        2.1.0
Release:        0
Url:            http://www.clusterlabs.org/wiki/Hawk
Source:         %{name}-%{version}.tar.bz2
Source100:      hawk-rpmlintrc
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Provides:       ha-cluster-webui
Obsoletes:      hawk <= 1.1.0
Provides:       hawk = %{version}
Requires:       crmsh >= 2.2.0+git.1464237560
Requires:       graphviz
Requires:       graphviz-gd
Requires(post): %fillup_prereq
# Need a font of some kind for graphviz to work correctly (bsc#931950)
Requires:       dejavu
Requires:       pacemaker >= 1.1.8
%if 0%{?fedora_version} >= 19
Requires:       rubypick
BuildRequires:  rubypick
%endif
Requires:       rubygem(%{rb_ruby_abi}:bundler)
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

BuildRequires:  rubygem(%{rb_ruby_abi}:fast_gettext) >= 1.4
BuildRequires:  rubygem(%{rb_ruby_abi}:gettext) >= 3.1
BuildRequires:  rubygem(%{rb_ruby_abi}:gettext_i18n_rails) >= 1.8
BuildRequires:  rubygem(%{rb_ruby_abi}:gettext_i18n_rails_js) >= 1.3
BuildRequires:  rubygem(%{rb_ruby_abi}:js-routes) >= 1.3.3
BuildRequires:  rubygem(%{rb_ruby_abi}:kramdown) >= 1.14
BuildRequires:  rubygem(%{rb_ruby_abi}:puma) >= 3.12.6
BuildRequires:  rubygem(%{rb_ruby_abi}:rails:5)
BuildRequires:  rubygem(%{rb_ruby_abi}:sass) >= 3.4
BuildRequires:  rubygem(%{rb_ruby_abi}:sass-rails) >= 5.0.1
BuildRequires:  rubygem(%{rb_ruby_abi}:virtus) >= 1.0.1
BuildRequires:  distribution-release

BuildRequires:  rubygem(%{rb_ruby_abi}:sprockets) >= 3.7

Requires:       rubygem(%{rb_ruby_abi}:fast_gettext) >= 1.4
Requires:       rubygem(%{rb_ruby_abi}:gettext_i18n_rails) >= 1.8
Requires:       rubygem(%{rb_ruby_abi}:gettext_i18n_rails_js) >= 1.3
Requires:       rubygem(%{rb_ruby_abi}:js-routes) >= 1.3.3
Requires:       rubygem(%{rb_ruby_abi}:kramdown) >= 1.14
Requires:       rubygem(%{rb_ruby_abi}:puma) >= 3
Requires:       rubygem(%{rb_ruby_abi}:rails:5)
Requires:       rubygem(%{rb_ruby_abi}:sass-rails) >= 5.0.1
Requires:       rubygem(%{rb_ruby_abi}:sass) >= 3.4
Requires:       rubygem(%{rb_ruby_abi}:sprockets) >= 3.0
Requires:       rubygem(%{rb_ruby_abi}:virtus) >= 1.0

BuildRequires:  %{rubydevel >= 2.4}
BuildRequires:  git
BuildRequires:  glib2-devel
BuildRequires:  libxml2-devel >= 2.6.21
BuildRequires:  libxslt-devel
BuildRequires:  openssl-devel
BuildRequires:  pam-devel
BuildRequires:  nodejs6

%description
A web-based GUI for managing and monitoring the Pacemaker
High-Availability cluster resource manager.


%prep
%setup

%build
sed -i 's$#!/.*$#!%{_bindir}/ruby.%{rb_ruby_suffix}$' hawk/bin/rails
sed -i 's$#!/.*$#!%{_bindir}/ruby.%{rb_ruby_suffix}$' hawk/bin/rake
sed -i 's$#!/.*$#!%{_bindir}/ruby.%{rb_ruby_suffix}$' hawk/bin/bundle
export NOKOGIRI_USE_SYSTEM_LIBRARIES=1
CFLAGS="${CFLAGS} ${RPM_OPT_FLAGS}"
export CFLAGS
make WWW_BASE=%{www_base} WWW_TMP=%{www_tmp} WWW_LOG=%{www_log} INIT_STYLE=%{init_style} LIBDIR=%{_libdir} BINDIR=%{_bindir} SBINDIR=%{_sbindir}

%install
make WWW_BASE=%{www_base} WWW_TMP=%{www_tmp} WWW_LOG=%{www_log} INIT_STYLE=%{init_style} DESTDIR=%{buildroot} install

# copy of GPL
cp COPYING %{buildroot}%{www_base}/hawk/
%if 0%{?suse_version}

# Hack so missing links to docs don't kill the build
mkdir -p %{buildroot}/usr/share/doc/manual/sle-ha-geo-quick_en-pdf
mkdir -p %{buildroot}/usr/share/doc/manual/sle-ha-guide_en-pdf
mkdir -p %{buildroot}/usr/share/doc/manual/sle-ha-manuals_en
mkdir -p %{buildroot}/usr/share/doc/manual/sle-ha-geo-manuals_en
mkdir -p %{buildroot}/usr/share/doc/manual/sle-ha-nfs-quick_en-pdf
mkdir -p %{buildroot}/usr/share/doc/manual/sle-ha-install-quick_en-pdf

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
rm -f %{buildroot}%{www_log}/*
# likewise .git special files
find %{buildroot}%{www_base}/hawk -type f -name '.git*' -print0 | xargs --no-run-if-empty -0 rm
%if 0%{?suse_version}
%{__ln_s} -f %{_sbindir}/service %{buildroot}%{_sbindir}/rchawk
%endif

install -p -d -m 755 %{buildroot}%{_sysconfdir}/hawk
install -D -m 0644 -T rpm/sysconfig.hawk %{buildroot}%{_localstatedir}/adm/fillup-templates/sysconfig.hawk

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
%{fillup_only -n hawk}

%preun
%service_del_preun hawk.service

%postun
%service_del_postun hawk.service

%endif

%files -f hawk.lang
%defattr(644,root,root,755)
%{_localstatedir}/adm/fillup-templates/sysconfig.hawk
%attr(4750, root, %{gname})%{_sbindir}/hawk_chkpwd
%attr(4750, root, %{gname})%{_sbindir}/hawk_invoke
%attr(0755, root, root) %{_sbindir}/hawk_monitor
%dir %{www_base}/hawk
%{www_base}/hawk/log
%{www_base}/hawk/tmp
%{www_base}/hawk/app
%{www_base}/hawk/config
%dir %{_localstatedir}/lib/hawk
%dir %{www_base}/hawk/bin
%attr(0755, root, root)%{www_base}/hawk/bin/rake
%attr(0755, root, root)%{www_base}/hawk/bin/rails
%exclude %{www_base}/hawk/bin/hawk
%attr(0755, root, root)%{www_base}/hawk/bin/generate-ssl-cert
%attr(0755, root, root)%{www_base}/hawk/bin/bundle
%attr(0750, %{uname},%{gname})%{_sysconfdir}/hawk
%dir %attr(0750, %{uname},%{gname})%{www_log}
%dir %attr(0750, %{uname},%{gname})%{www_tmp}
%attr(-, %{uname},%{gname})%{www_tmp}/cache
%attr(-, %{uname},%{gname})%{www_tmp}/explorer
%attr(-, %{uname},%{gname})%{www_tmp}/home
%attr(-, %{uname},%{gname})%{www_tmp}/pids
%attr(-, %{uname},%{gname})%{www_tmp}/sessions
%attr(-, %{uname},%{gname})%{www_tmp}/sockets
%{www_base}/hawk/locale/hawk.pot
%{www_base}/hawk/public
%{www_base}/hawk/Rakefile
%exclude %{www_base}/hawk/Gemfile
%exclude %{www_base}/hawk/Gemfile.lock
%{www_base}/hawk/COPYING
%{www_base}/hawk/config.ru
%{www_base}/hawk/test
%{www_base}/hawk/spec
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
