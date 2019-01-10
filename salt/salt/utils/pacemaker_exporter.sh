#!/bin/sh

go get github.com/hawk-ui/pacemaker_exporter
cd $GOPATH/src/github.com/hawk-ui/pacemaker_exporter
make
