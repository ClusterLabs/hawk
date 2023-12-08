#
# spec file for package hawk2 3
#
# Copyright (c) 2022 SUSE LLC
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


#Compat macro for new _fillupdir macro introduced in Nov 2017
%if ! %{defined _fillupdir}
  %define _fillupdir /var/adm/fillup-templates
%endif

%define	vendor_ruby	vendor_ruby
%define	init_style	suse
%define	pkg_group	Productivity/Clustering/HA


%define www_base %{_datadir}
%define www_tmp  %{_localstatedir}/lib/hawk/tmp
%define www_log  %{_localstatedir}/log/hawk
%define gname haclient
%define uname hacluster

%define rb_build_versions ruby25
%define rb_ruby_abi ruby:2.5.0
%define rb_ruby_suffix ruby2.5

Name:           hawk2
Summary:        HA Web Konsole
License:        GPL-2.0-only
Group:          %{pkg_group}
Version:        2.6.4+git.1648030447.9fe03396
Release:        0
Url:            http://www.clusterlabs.org/wiki/Hawk
Source:         %{name}-%{version}.tar.bz2
Source1:        sysconfig.hawk
Source2:        hawk-rpmlintrc
### GEMS START
Source100: https://rubygems.org/downloads/actioncable-5.2.3.gem
Source101: https://rubygems.org/downloads/actionmailer-5.2.3.gem
Source102: https://rubygems.org/downloads/actionpack-5.2.3.gem
Source103: https://rubygems.org/downloads/actionview-5.2.3.gem
Source104: https://rubygems.org/downloads/activejob-5.2.3.gem
Source105: https://rubygems.org/downloads/activemodel-5.2.3.gem
Source106: https://rubygems.org/downloads/activerecord-5.2.3.gem
Source107: https://rubygems.org/downloads/activestorage-5.2.3.gem
Source108: https://rubygems.org/downloads/activesupport-5.2.3.gem
Source109: https://rubygems.org/downloads/arel-9.0.0.gem
Source110: https://rubygems.org/downloads/axiom-types-0.1.1.gem
Source111: https://rubygems.org/downloads/builder-3.2.3.gem
Source112: https://rubygems.org/downloads/coercible-1.0.0.gem
Source113: https://rubygems.org/downloads/concurrent-ruby-1.0.5.gem
Source114: https://rubygems.org/downloads/crass-1.0.3.gem
Source115: https://rubygems.org/downloads/descendants_tracker-0.0.4.gem
Source116: https://rubygems.org/downloads/equalizer-0.0.11.gem
Source117: https://rubygems.org/downloads/erubi-1.7.0.gem
Source118: https://rubygems.org/downloads/execjs-2.7.0.gem
Source119: https://rubygems.org/downloads/fast_gettext-1.6.0.gem
Source120: https://rubygems.org/downloads/ffi-1.9.18.gem
Source121: https://rubygems.org/downloads/gettext-3.2.5.gem
Source122: https://rubygems.org/downloads/gettext_i18n_rails-1.8.0.gem
Source123: https://rubygems.org/downloads/gettext_i18n_rails_js-1.3.0.gem
Source124: https://rubygems.org/downloads/globalid-0.4.1.gem
Source125: https://rubygems.org/downloads/i18n-1.1.1.gem
Source126: https://rubygems.org/downloads/ice_nine-0.11.2.gem
Source127: https://rubygems.org/downloads/js-routes-1.4.1.gem
Source128: https://rubygems.org/downloads/json-2.1.0.gem
Source129: https://rubygems.org/downloads/kramdown-1.15.0.gem
Source130: https://rubygems.org/downloads/locale-2.1.2.gem
Source131: https://rubygems.org/downloads/loofah-2.2.2.gem
Source132: https://rubygems.org/downloads/mail-2.7.1.gem
Source133: https://rubygems.org/downloads/marcel-0.3.3.gem
Source134: https://rubygems.org/downloads/method_source-0.9.0.gem
Source135: https://rubygems.org/downloads/mimemagic-0.3.2.gem
Source136: https://rubygems.org/downloads/mini_mime-1.0.0.gem
Source137: https://rubygems.org/downloads/mini_portile2-2.3.0.gem
Source138: https://rubygems.org/downloads/minitest-5.10.3.gem
Source139: https://rubygems.org/downloads/nio4r-2.1.0.gem
Source140: https://rubygems.org/downloads/nokogiri-1.8.5.gem
Source141: https://rubygems.org/downloads/po_to_json-1.0.1.gem
Source142: https://rubygems.org/downloads/puma-4.3.5.gem
Source143: https://rubygems.org/downloads/rack-2.0.8.gem
Source144: https://rubygems.org/downloads/rack-test-0.6.3.gem
Source145: https://rubygems.org/downloads/rails-5.2.3.gem
Source146: https://rubygems.org/downloads/rails-dom-testing-2.0.3.gem
Source147: https://rubygems.org/downloads/rails-html-sanitizer-1.0.4.gem
Source148: https://rubygems.org/downloads/railties-5.2.3.gem
Source149: https://rubygems.org/downloads/rake-12.3.3.gem
Source150: https://rubygems.org/downloads/rb-fsevent-0.10.2.gem
Source151: https://rubygems.org/downloads/rb-inotify-0.9.10.gem
Source152: https://rubygems.org/downloads/sass-3.5.3.gem
Source153: https://rubygems.org/downloads/sass-listen-4.0.0.gem
Source154: https://rubygems.org/downloads/sass-rails-5.0.7.gem
Source155: https://rubygems.org/downloads/sprockets-3.7.2.gem
Source156: https://rubygems.org/downloads/sprockets-rails-3.2.1.gem
Source157: https://rubygems.org/downloads/text-1.3.1.gem
Source158: https://rubygems.org/downloads/thor-0.20.0.gem
Source159: https://rubygems.org/downloads/thread_safe-0.3.6.gem
Source160: https://rubygems.org/downloads/tilt-2.0.8.gem
Source161: https://rubygems.org/downloads/tzinfo-1.2.7.gem
Source162: https://rubygems.org/downloads/uglifier-4.1.5.gem
Source163: https://rubygems.org/downloads/virtus-1.0.5.gem
Source164: https://rubygems.org/downloads/websocket-driver-0.6.5.gem
Source165: https://rubygems.org/downloads/websocket-extensions-0.1.3.gem
### GEMS END
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Provides:       ha-cluster-webui
Obsoletes:      hawk <= 1.1.0
Provides:       hawk = %{version}
Requires:       crmsh >= 3.0.0
Requires:       graphviz
Requires:       graphviz-gd
Requires:       hawk-apiserver
Requires(post): %fillup_prereq
# Need a font of some kind for graphviz to work correctly (bsc#931950)
Requires:       dejavu
Requires:       pacemaker >= 1.1.8
Recommends:     graphviz-gnome
Requires:       iproute2
PreReq:         permissions
BuildRequires:  fdupes
BuildRequires:  systemd-rpm-macros
%{?systemd_requires}

BuildRequires:  distribution-release
BuildRequires:  timezone
BuildRequires:  nodejs10
BuildRequires:  %{rubygem bundler}
Requires:       %{rubygem bundler}
BuildRequires:  %{rubygem rails:5.1}
Requires:       %{rubygem rails:5.1}
BuildRequires:  %{rubygem puma >= 4.3.5}
Requires:       %{rubygem puma >= 4.3.5}
BuildRequires:  %{rubygem sass-rails >= 5.0.1}
Requires:       %{rubygem sass-rails >= 5.0.1}
BuildRequires:  %{rubygem virtus:1.0 >= 1.0.1}
Requires:       %{rubygem virtus:1.0 >= 1.0.1}
BuildRequires:  %{rubygem js-routes >= 1.3.3}
Requires:       %{rubygem js-routes >= 1.3.3}
BuildRequires:  %{rubygem fast_gettext >= 1.4}
Requires:       %{rubygem fast_gettext >= 1.4}
BuildRequires:  %{rubygem gettext_i18n_rails >= 1.8}
Requires:       %{rubygem gettext_i18n_rails >= 1.8}
BuildRequires:  %{rubygem gettext_i18n_rails_js >= 1.3}
Requires:       %{rubygem gettext_i18n_rails_js >= 1.3}
BuildRequires:  %{rubygem sprockets >= 3.7}
Requires:       %{rubygem sprockets >= 3.7}
#BuildRequires:  %{rubygem kramdown >= 1.14}
#Requires:       %{rubygem kramdown >= 1.14}

BuildRequires:  %{rubygem gettext >= 3.2}
BuildRequires:  %{rubygem uglifier >= 3}

# Help OBS scheduler:
BuildRequires:  %{rubygem mail >= 2.6}
BuildRequires:  %{rubygem tilt >= 2}
#/Help OBS scheduler

BuildRequires:  git
BuildRequires:  nodejs >= 6
BuildRequires:  pam-devel

%description
A web-based GUI for managing and monitoring the Pacemaker
High-Availability cluster resource manager.


%prep
%setup

mkdir -p vendor/cache
#cp %{_sourcedir}/*.gem vendor/cache
cp %{_sourcedir}/kramdown*.gem vendor/cache

%build

export GEM_HOME=$PWD/vendor
gem install vendor/cache/*.gem
#bundler install
#bundle --local --deployment --with production

sed -i 's$#!/.*$#!%{_bindir}/ruby.%{rb_ruby_suffix}$' hawk/bin/rails
sed -i 's$#!/.*$#!%{_bindir}/ruby.%{rb_ruby_suffix}$' hawk/bin/rake
sed -i 's$#!/.*$#!%{_bindir}/ruby.%{rb_ruby_suffix}$' hawk/bin/bundle
pushd hawk
if [ -x /usr/bin/bundle.ruby.%{rb_ruby_suffix} ]; then
	bundlerexe=bundle.ruby.%{rb_ruby_suffix}
else
	bundlerexe=bundle.%{rb_ruby_suffix}
fi
$bundlerexe exec bin/rails version
popd
export NOKOGIRI_USE_SYSTEM_LIBRARIES=1
CFLAGS="${CFLAGS} ${RPM_OPT_FLAGS}"
export CFLAGS
make WWW_BASE=%{www_base} WWW_TMP=%{www_tmp} WWW_LOG=%{www_log} INIT_STYLE=%{init_style} LIBDIR=%{_libdir} BINDIR=%{_bindir} SBINDIR=%{_sbindir} RUBY_SUFFIX=.%{rb_ruby_suffix}

%install
make WWW_BASE=%{www_base} WWW_TMP=%{www_tmp} WWW_LOG=%{www_log} INIT_STYLE=%{init_style} DESTDIR=%{buildroot} install

# copy of GPL
cp COPYING %{buildroot}%{www_base}/hawk/

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
# more cruft to clean up (WTF?)
rm -f %{buildroot}%{www_log}/*
# likewise .git special files
find %{buildroot}%{www_base}/hawk -type f -name '.git*' -print0 | xargs --no-run-if-empty -0 rm
%{__ln_s} -f %{_sbindir}/service %{buildroot}%{_sbindir}/rchawk

install -p -d -m 755 %{buildroot}%{_sysconfdir}/hawk
install -D -m 0644 %{S:1}  %{buildroot}%{_fillupdir}/sysconfig.hawk

%clean
rm -rf %{buildroot}

%verifyscript
%verify_permissions -e %{_sbindir}/hawk_chkpwd

%pre
getent group %{gname} >/dev/null || groupadd -r %{gname} -g 189
getent passwd %{uname} >/dev/null || useradd -r -g %{gname} -u 189 -s /sbin/nologin -c "cluster user" %{uname}
%service_add_pre hawk.service hawk-backend.service

%post
%set_permissions %{_sbindir}/hawk_chkpwd
%service_add_post hawk.service hawk-backend.service
%{fillup_only -n hawk}

%preun
%service_del_preun hawk.service hawk-backend.service

%postun
%service_del_postun hawk.service hawk-backend.service


%files -f hawk.lang
%defattr(644,root,root,755)
%{_fillupdir}/sysconfig.hawk
%attr(4750, root, %{gname})%{_sbindir}/hawk_chkpwd
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
# itemizing content in %%{www_base}/hawk/locale to avoid
# duplicate files that would otherwise be the result of including hawk.lang
%dir %{www_base}/hawk/locale
%dir %{www_base}/hawk/locale/*
%dir %{www_base}/hawk/locale/*/*

# Not doing this itemization for %%lang files in vendor, it's frightfully
# hideous, so we're going to live with a handful of file-not-in-%%lang rpmlint
# warnings for bundled gems.
%{www_base}/hawk/vendor

%{_unitdir}/hawk.service
%{_unitdir}/hawk-backend.service
%attr(-,root,root) %{_sbindir}/rchawk

%changelog

