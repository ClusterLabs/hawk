#!/bin/sh
DESTDIR=$1
WWW_BASE=$2
WWW_LOG=$3
WWW_TMP=$4
mkdir -p "$DESTDIR$WWW_LOG/hawk/log"
mkdir -p "$DESTDIR$WWW_TMP/hawk/tmp/cache"
mkdir -p "$DESTDIR$WWW_TMP/hawk/tmp/explorer/uploads"
mkdir -p "$DESTDIR$WWW_TMP/hawk/tmp/pids"
mkdir -p "$DESTDIR$WWW_TMP/hawk/tmp/sessions"
mkdir -p "$DESTDIR$WWW_TMP/hawk/tmp/sockets"
mkdir -p "$DESTDIR$WWW_TMP/hawk/tmp/home"
mkdir -p "$DESTDIR$WWW_BASE/hawk"
mkdir -p "$DESTDIR$WWW_BASE/hawk/locale"
[ "$WWW_LOG" != "$WWW_BASE" ] && ln -rfs "$DESTDIR$WWW_LOG/hawk/log" "$DESTDIR$WWW_BASE/hawk/log"
[ "$WWW_TMP" != "$WWW_BASE" ] && ln -rfs "$DESTDIR$WWW_TMP/hawk/tmp" "$DESTDIR$WWW_BASE/hawk/tmp"
chown -R hacluster.haclient "$DESTDIR$WWW_LOG/hawk/log" || true
chown -R hacluster.haclient "$DESTDIR$WWW_TMP/hawk/tmp" || true
chmod g+w "$DESTDIR$WWW_TMP/hawk/tmp/home"
chmod g+w "$DESTDIR$WWW_TMP/hawk/tmp/explorer"
