# go toolchain env paths
export GOOS="linux"
case "$(uname -m)" in
    *86)
	export GOARCH=386
	libdir=lib
	;;
    aarch64)
	export GOARCH=arm64
	libdir=lib64
	;;
    x86_64)
	export GOARCH=amd64
	libdir=lib64
	;;
    ppc64)
	export GOARCH=ppc64
	libdir=lib64
	;;
    ppc64le)
	export GOARCH=ppc64le
	libdir=lib64
	;;
    arm*)
	export GOARCH=arm
	libdir=lib
	;;
    s390x)
	export GOARCH=s390x
	libdir=lib64
	;;
esac
export GOROOT=/usr/$libdir/go/1.10
export GOBIN=/usr/bin
export GOPATH=/usr/share/go/1.10/contrib

if [ `id -u` != 0 ]; then
  export GOPATH=$HOME/go:/usr/share/go/1.10/contrib
  unset GOBIN
fi
