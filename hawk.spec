#
# spec file for package hawk (Version 0.6.0)
#
# Copyright (c) 2010-2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
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

%define	gname		haclient
%define	uname		hacluster


Name:		hawk
Summary:	HA Web Konsole
Version:	0.6.0
Release:	0
License:	GPL v2 only
Url:		http://www.clusterlabs.org/wiki/Hawk
Group:		%{pkg_group}
Source:		%{name}-%{version}.tar.bz2
%if 0%{?suse_version}
Source1:	filter-requires.sh
%define		_use_internal_dependency_generator 0
%define		__find_requires /bin/sh %{SOURCE1}
%endif
BuildRoot:	%{_tmppath}/%{name}-%{version}-build
AutoReqProv:	on
Requires:       hawk-templates >= %{version}-%{release}
Requires:	pacemaker
Requires:	ruby
Requires:   rubygem-bundler
Requires:	lighttpd >= 1.4.20
Requires:	graphviz
Requires:	graphviz-gd
Requires:	iproute2
%if 0%{?suse_version}
Recommends:	graphviz-gnome
%endif
BuildRequires:	rubygems
BuildRequires:	rubygem-rake
BuildRequires:  rubygem-gettext
BuildRequires:  rubygem-gettext_i18n_rails
BuildRequires:  rubygem-fast_gettext
BuildRequires:	pam-devel
BuildRequires:	glib2-devel libxml2-devel
%if 0%{?suse_version}
PreReq:			permissions
BuildRequires:	ruby-fcgi
BuildRequires:	fdupes
BuildRequires:	rubygem-rails-3_2
BuildRequires:  rubygem-rails-i18n
BuildRequires:	libpacemaker-devel
BuildRequires:  rubygem-rack
# Require startproc respecting -p, bnc#559534#c44
%if 0%{?suse_version} > 1110
# 11.2 or newer; 
Requires:	sysvinit > 2.86-215.2
%else
# 11.1 or SLES11
Requires:	sysvinit > 2.86-195.3.1
%endif
%else
BuildRequires:  rubygem-rails >= 3.2
BuildRequires:	pacemaker-libs-devel
%endif

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
make WWW_BASE=%{www_base} INIT_STYLE=%{init_style} LIBDIR=%{_libdir} BINDIR=%{_bindir} SBINDIR=%{_sbindir}

%install
make WWW_BASE=%{www_base} INIT_STYLE=%{init_style} DESTDIR=%{buildroot} install
# copy of GPL
cp COPYING %{buildroot}%{www_base}/hawk/
%if 0%{?suse_version}
# evil magic to get ruby-fcgi into the vendor directory
for f in $(rpm -ql ruby-fcgi|grep %{vendor_ruby}); do
	# gives something simliar to:
	#  /usr/lib64/ruby/vendor_ruby/1.8/fcgi.rb
	#  /usr/lib64/ruby/vendor_ruby/1.8/x86_64-linux/fcgi.so
	r=$(echo $f | sed 's/.*%{vendor_ruby}\/[^\/]*\///')
	mkdir -p %{buildroot}%{www_base}/hawk/vendor/$(dirname $r)
	cp $f %{buildroot}%{www_base}/hawk/vendor/$r
done
%endif
# get rid of gem sample and test cruft
rm -rf %{buildroot}%{www_base}/hawk/vendor/bundle/ruby/*/gems/*/doc
rm -rf %{buildroot}%{www_base}/hawk/vendor/bundle/ruby/*/gems/*/examples
rm -rf %{buildroot}%{www_base}/hawk/vendor/bundle/ruby/*/gems/*/samples
rm -rf %{buildroot}%{www_base}/hawk/vendor/bundle/ruby/*/gems/*/test
# mark .mo files as such (works on SUSE but not FC12, as the latter wants directory to
# be "share/locale", not just "locale", and it also doesn't support appending to %%{name}.lang)
%find_lang %{name} %{name}.lang
# hard link duplicate files
%fdupes %{buildroot}
%else
# Need file to exist else %files fails later
touch %{name}.lang
%endif
# more cruft to clean up (WTF?)
rm -f %{buildroot}%{www_base}/hawk/log/*
#;find %{buildroot}%{www_base}/hawk/vendor/rails -type f -name '*.css' -o -name '*.js' -o -name '*LICENSE' | xargs chmod a-x
# likewise .git special files
find %{buildroot}%{www_base}/hawk -type f -name '.git*' -print0 | xargs -0 rm
# init script
%{__install} -d -m 0755 \
	%{buildroot}%{_sbindir}
%{__install} -D -m 0755 scripts/hawk.%{init_style} \
	%{buildroot}%{_sysconfdir}/init.d/hawk
%if 0%{?suse_version}
%{__ln_s} -f %{_sysconfdir}/init.d/hawk %{buildroot}%{_sbindir}/rchawk
%endif

%clean
rm -rf %{buildroot}

%if 0%{?suse_version}
# TODO(must): Determine sensible non-SUSE versions of these,
# in particular restart_on_update and stop_on_removal.

%verifyscript
%verify_permissions -e %{_sbindir}/hawk_chkpwd
%verify_permissions -e %{_sbindir}/hawk_invoke

%post
%set_permissions %{_sbindir}/hawk_chkpwd
%set_permissions %{_sbindir}/hawk_invoke
%fillup_and_insserv hawk

%preun
%stop_on_removal hawk

%postun
%restart_on_update hawk
%{insserv_cleanup}

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
%{www_base}/hawk/doc
%{www_base}/hawk/lib
%attr(0750, %{uname},%{gname})%{www_base}/hawk/log
%dir %attr(0750, %{uname},%{gname})%{www_base}/hawk/tmp
%attr(0750, %{uname},%{gname})%{www_base}/hawk/tmp/cache
%attr(0770, %{uname},%{gname})%{www_base}/hawk/tmp/explorer
%attr(0770, %{uname},%{gname})%{www_base}/hawk/tmp/home
%attr(0750, %{uname},%{gname})%{www_base}/hawk/tmp/pids
%attr(0750, %{uname},%{gname})%{www_base}/hawk/tmp/sessions
%attr(0750, %{uname},%{gname})%{www_base}/hawk/tmp/sockets
%exclude %{www_base}/hawk/tmp/session_secret
%{www_base}/hawk/locale/hawk.pot
%{www_base}/hawk/.bundle
%{www_base}/hawk/public
%{www_base}/hawk/Rakefile
%{www_base}/hawk/Gemfile
%{www_base}/hawk/Gemfile.lock
%{www_base}/hawk/COPYING
%{www_base}/hawk/README.rdoc
%{www_base}/hawk/config.ru
%{www_base}/hawk/script
%{www_base}/hawk/test
%if 0%{?suse_version}
# itemizing content in %%{www_base}/hawk/vendor and locale to avoid
# duplicate files that would otherwise be the result of including hawk.lang
%dir %{www_base}/hawk/locale
%else
%{www_base}/hawk/locale
%endif
# Not doing this itemization for %lang files in vendor, it's frightfully
# hideous, so we're going to live with a handful of file-not-in-%lang rpmlint
# warnings for bundled gems.
%{www_base}/hawk/vendor

%attr(-,root,root) %{_sysconfdir}/init.d/hawk
%if 0%{?suse_version}
%attr(-,root,root) %{_sbindir}/rchawk
%endif

%files templates
%defattr(-,root,root)
%{www_base}/hawk/config/wizard

%changelog
