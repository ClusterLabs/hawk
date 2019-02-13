#!/bin/sh
cd /vagrant || exit
make WITHIN_VAGRANT=1 WWW_BASE=/vagrant clean
make WITHIN_VAGRANT=1 WWW_BASE=/vagrant tools/hawk_chkpwd tools/hawk_invoke
make WITHIN_VAGRANT=1 WWW_BASE=/vagrant tools/install
