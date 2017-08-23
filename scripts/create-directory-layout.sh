#!/bin/sh
DESTDIR=$1
WWW_BASE=$2
WWW_LOG=$3
WWW_TMP=$4
mkdir -p "$DESTDIR$WWW_BASE/hawk/locale"
mkdir -p "$DESTDIR$WWW_LOG"
mkdir -p "$DESTDIR$WWW_TMP/cache"
mkdir -p "$DESTDIR$WWW_TMP/explorer/uploads"
mkdir -p "$DESTDIR$WWW_TMP/pids"
mkdir -p "$DESTDIR$WWW_TMP/sessions"
mkdir -p "$DESTDIR$WWW_TMP/sockets"
mkdir -p "$DESTDIR$WWW_TMP/home"
[ "$WWW_LOG" != "$WWW_BASE/hawk/log" ] && ln -rfs "$DESTDIR$WWW_LOG" "$DESTDIR$WWW_BASE/hawk/log"
[ "$WWW_TMP" != "$WWW_BASE/hawk/tmp" ] && ln -rfs "$DESTDIR$WWW_TMP" "$DESTDIR$WWW_BASE/hawk/tmp"
chown -R hacluster.haclient "$DESTDIR$WWW_LOG" || true
chown -R hacluster.haclient "$DESTDIR$WWW_TMP" || true
chmod g+w "$DESTDIR$WWW_TMP/home"
chmod g+w "$DESTDIR$WWW_TMP/explorer"
