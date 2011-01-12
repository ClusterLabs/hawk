#
# spec file for package hawk (Version 0.3.5)
#
# Copyright (c) 2010 SUSE LINUX Products GmbH, Nuernberg, Germany.
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
Version:	0.3.5
Release:	0
License:	GPL v2 only
Group:		%{pkg_group}
Source:		%{name}-%{version}.tar.bz2
%if 0%{?suse_version}
Source1:	filter-requires.sh
%define		_use_internal_dependency_generator 0
%define		__find_requires /bin/sh %{SOURCE1}
%endif
BuildRoot:	%{_tmppath}/%{name}-%{version}-build
AutoReqProv:	on
Requires:	pacemaker
Requires:	ruby
Requires:	lighttpd >= 1.4.20
BuildRequires:	rubygems
BuildRequires:	rubygem-rake
BuildRequires:	rubygem-gettext_rails
BuildRequires:	pam-devel
%if 0%{?suse_version}
BuildRequires:	ruby-fcgi
BuildRequires:	rubygem-rails-2_3
BuildRequires:	fdupes
BuildRequires:	glib2-devel libpacemaker-devel libxml2-devel
# Require startproc respecting -p, bnc#559534#c44
%if 0%{?suse_version} > 1110
# 11.2 or newer; 
Requires:	sysvinit > 2.86-215.2
%else
# 11.1 or SLES11
Requires:	sysvinit > 2.86-195.3.1
%endif
%else
BuildRequires:  rubygem-rails >= 2.3
%endif

%description
A web-based GUI for monitoring the Pacemaker High-Availability cluster
resource manager

Authors: Tim Serong <tserong@novell.com>



%prep
%setup

%build
make WWW_BASE=%{www_base} INIT_STYLE=%{init_style}

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
# even more evil magic to get rubygems into the vendor directory
for f in $(rpm -ql rubygems|grep %{vendor_ruby}); do
	# gives something simliar to:
	#  /usr/lib64/ruby/vendor_ruby/1.8/rubygems.rb
	#  /usr/lib64/ruby/vendor_ruby/1.8/rubygems/...
	[ -f $f ] || continue
	r=$(echo $f | sed 's/.*%{vendor_ruby}\/[^\/]*\///')
	mkdir -p %{buildroot}%{www_base}/hawk/vendor/$(dirname $r)
	cp $f %{buildroot}%{www_base}/hawk/vendor/$r
done
# get rid of gem sample and test cruft
rm -rf %{buildroot}%{www_base}/hawk/vendor/gems/*/sample
rm -rf %{buildroot}%{www_base}/hawk/vendor/gems/*/samples
rm -rf %{buildroot}%{www_base}/hawk/vendor/gems/*/test
%if 0%{?suse_version}
# mark .mo files as such (works on SUSE but not FC12, as the latter wants directory to
# be "share/locale", not just "locale", and it also doesn't support appending to %{name}.lang)
%find_lang %{name} %{name}.lang
%find_lang rgettext %{name}.lang
%find_lang gettext_rails %{name}.lang
# hard link duplicate files
%fdupes %{buildroot}
%else
# Need file to exist else %files fails later
touch %{name}.lang
%endif
# more cruft to clean up (WTF?)
rm -f %{buildroot}%{www_base}/hawk/log/*
find %{buildroot}%{www_base}/hawk/vendor/rails -type f -name '*.css' -o -name '*.js' -o -name '*LICENSE' | xargs chmod a-x
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
%post
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
%{www_base}/hawk/db
%{www_base}/hawk/doc
%{www_base}/hawk/lib
%attr(0750, %{uname},%{gname})%{www_base}/hawk/log
%attr(0750, %{uname},%{gname})%{www_base}/hawk/tmp
%{www_base}/hawk/po
%{www_base}/hawk/public
%{www_base}/hawk/Rakefile
%{www_base}/hawk/COPYING
%{www_base}/hawk/script
%{www_base}/hawk/test
%if 0%{?suse_version}
# itemizing content in %{www_base}/hawk/vendor and locale to avoid
# duplicate files that would otherwise be the result of including hawk.lang
%dir %{www_base}/hawk/locale
%dir %{www_base}/hawk/vendor
%{www_base}/hawk/vendor/*rb
# architecture-specific .so files
%{www_base}/hawk/vendor/*-linux
# this is moderatly disgusting - the intent is to get everything except
# the content of "data/locale" which is covered by files in hawk.lang
%dir %{www_base}/hawk/vendor/gems
%dir %{www_base}/hawk/vendor/gems/*
%dir %{www_base}/hawk/vendor/gems/*/data
%dir %{www_base}/hawk/vendor/gems/*/data/locale
%{www_base}/hawk/vendor/gems/*/[!d]*
%{www_base}/hawk/vendor/gems/*/.specification
%{www_base}/hawk/vendor/rails
%{www_base}/hawk/vendor/rbconfig
%{www_base}/hawk/vendor/rubygems
%else
%{www_base}/hawk/locale
%{www_base}/hawk/vendor
%endif
%config(noreplace) %attr(-,root,root) %{_sysconfdir}/init.d/hawk
%if 0%{?suse_version}
%attr(-,root,root) %{_sbindir}/rchawk
%endif

%changelog
