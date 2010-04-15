#
# spec file for package hawk (Version 0.3.3)
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


%define gname haclient
%define uname hacluster
%if 0%{?fedora_version} || 0%{?centos_version} || 0%{?rhel_version}
%define pkg_group System Environment/Daemons
%else
%define pkg_group Productivity/Clustering/HA
%endif

Name:           hawk
Summary:        HA Web Konsole
Version:        0.3.3
Release:        0
License:        GPL v2 only
Group:          %{pkg_group}
Source:		%{name}-%{version}.tar.bz2
Source1:	filter-requires.sh
%define		_use_internal_dependency_generator 0
%define		__find_requires /bin/sh %{SOURCE1}
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
AutoReqProv:    on
Requires:       pacemaker
%if 0%{?suse_version} == 0 || %suse_version > 1110
# 11.2 or newer
# Require startproc respecting -p, bnc#559534#c44
Requires:	sysvinit > 2.86-215.2
%else
# 11.1 or SLES11
Requires:	sysvinit > 2.86-195.3.1
%endif
# (not forcing a later lighttpd; it's not available on SLE11SP1)
Requires:       lighttpd >= 1.4.20
Requires:       ruby
Requires:	pam-modules
BuildRequires:  ruby-fcgi
BuildRequires:  rubygems
BuildRequires:  rubygem-rake
BuildRequires:  rubygem-rails-2_3
BuildRequires:  rubygem-gettext_rails
BuildRequires:	fdupes

%description
A web-based GUI for monitoring the Pacemaker High-Availability cluster
resource manager

Authors: Tim Serong <tserong@novell.com>



%prep
%setup

%build
make

%install
make DESTDIR=$RPM_BUILD_ROOT install
# copy of GPL
cp COPYING $RPM_BUILD_ROOT/srv/www/hawk/
# evil magic to get ruby-fcgi into the vendor directory
for f in $(rpm -ql ruby-fcgi|grep vendor_ruby); do
	# gives something simliar to:
	#  /usr/lib64/ruby/vendor_ruby/1.8/fcgi.rb
	#  /usr/lib64/ruby/vendor_ruby/1.8/x86_64-linux/fcgi.so
	r=$(echo $f | sed 's/.*vendor_ruby\/[^\/]*\///')
	mkdir -p $RPM_BUILD_ROOT/srv/www/hawk/vendor/$(dirname $r)
	cp $f $RPM_BUILD_ROOT/srv/www/hawk/vendor/$r
done
# even more evil magic to get rubygems into the vendor directory
for f in $(rpm -ql rubygems|grep vendor_ruby); do
	# gives something simliar to:
	#  /usr/lib64/ruby/vendor_ruby/1.8/rubygems.rb
	#  /usr/lib64/ruby/vendor_ruby/1.8/rubygems/...
	[ -f $f ] || continue
	r=$(echo $f | sed 's/.*vendor_ruby\/[^\/]*\///')
	mkdir -p $RPM_BUILD_ROOT/srv/www/hawk/vendor/$(dirname $r)
	cp $f $RPM_BUILD_ROOT/srv/www/hawk/vendor/$r
done
# get rid of gem sample and test cruft
rm -rf $RPM_BUILD_ROOT/srv/www/hawk/vendor/gems/*/sample
rm -rf $RPM_BUILD_ROOT/srv/www/hawk/vendor/gems/*/samples
rm -rf $RPM_BUILD_ROOT/srv/www/hawk/vendor/gems/*/test
# mark .mo files as such
%find_lang %{name} %{name}.lang
%find_lang rgettext %{name}.lang
%find_lang gettext_activerecord %{name}.lang
%find_lang gettext_rails %{name}.lang
# hard link duplicate files
%fdupes $RPM_BUILD_ROOT
# more cruft to clean up (WTF?)
rm -f $RPM_BUILD_ROOT/srv/www/hawk/log/*
find $RPM_BUILD_ROOT/srv/www/hawk/vendor/rails -type f -name '*.css' -o -name '*.js' -o -name '*LICENSE' | xargs chmod a-x
# init script
%{__install} -d -m 0755 \
	%{buildroot}%{_sbindir}
%{__install} -D -m 0755 scripts/hawk.suse \
	%{buildroot}%{_sysconfdir}/init.d/hawk
%{__ln_s} -f %{_sysconfdir}/init.d/hawk %{buildroot}%{_sbindir}/rchawk

%clean
rm -rf $RPM_BUILD_ROOT

%post
%fillup_and_insserv hawk

%preun
%stop_on_removal hawk

%postun
%restart_on_update hawk
%{insserv_cleanup}

%triggerin -- lighttpd
%restart_on_update hawk

%files -f %{name}.lang
%defattr(-,root,root)
%dir /srv/www/hawk
/srv/www/hawk/app
/srv/www/hawk/config
/srv/www/hawk/db
/srv/www/hawk/doc
/srv/www/hawk/lib
%attr(0750, %{uname},%{gname})/srv/www/hawk/log
%attr(0750, %{uname},%{gname})/srv/www/hawk/tmp
%dir /srv/www/hawk/locale
/srv/www/hawk/po
/srv/www/hawk/public
/srv/www/hawk/Rakefile
/srv/www/hawk/COPYING
/srv/www/hawk/script
/srv/www/hawk/test
# itemizing content in /srv/www/hawk/vendor to avoid duplicate
# files that would otherwise be the result of including hawk.lang
%dir /srv/www/hawk/vendor
/srv/www/hawk/vendor/*rb
# architecture-specific .so files
/srv/www/hawk/vendor/*-linux
# this is moderatly disgusting - the intent is to get everything except
# the content of "data/locale" which is covered by files in hawk.lang
%dir /srv/www/hawk/vendor/gems
%dir /srv/www/hawk/vendor/gems/*
%dir /srv/www/hawk/vendor/gems/*/data
%dir /srv/www/hawk/vendor/gems/*/data/locale
/srv/www/hawk/vendor/gems/*/[!d]*
/srv/www/hawk/vendor/gems/*/.specification
/srv/www/hawk/vendor/rails
/srv/www/hawk/vendor/rbconfig
/srv/www/hawk/vendor/rubygems
%config(noreplace) %attr(-,root,root) %{_sysconfdir}/init.d/hawk
%attr(-,root,root) %{_sbindir}/rchawk

%changelog
