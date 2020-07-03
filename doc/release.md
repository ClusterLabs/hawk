# Release

# Release Github Branches:

Actively maintained are:

-  SLE15 and higher -> `master`

-  SLE12SP4 and SLES12P3 -> `sles12-sp3 and sp4` github branches.

-  openSUSE factory -> `factory` 
# Note on sle15 and sles12 branches:

sle15 and sle12 have completely different design and also, the ruby supported is quite different


### Packaging Notes

For anyone looking to package Hawk for distributions, the best approach is probably to look at the RPM packaging at the SUSE Open Build Service and begin from there:

* https://build.opensuse.org/package/show/network:ha-clustering:Factory/hawk2
