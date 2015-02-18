#!/bin/sh
# Courtesy of http://fedoraproject.org/wiki/PackagingDrafts/FilteringAutomaticDependencies

if [ -x /usr/lib/rpm/redhat/find-requires ] ; then
	FINDREQ=/usr/lib/rpm/redhat/find-requires
else
	FINDREQ=/usr/lib/rpm/find-requires
fi

$FINDREQ $* | sed -e '/libfcgi.so/d'

