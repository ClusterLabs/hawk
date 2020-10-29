# Defines the tag for OBS and build script builds:
#!BuildTag: hawk_test
# Use the repositories defined in OBS for installing packages
#!UseOBSRepositories
FROM	opensuse/tumbleweed

RUN	zypper -n install -y --no-recommends \
		MozillaFirefox \
		MozillaFirefox-branding-upstream \
		chromium \
		file \
		python3-paramiko \
		python3-PyVirtualDisplay \
		python3-selenium \
		shadow \
		xauth \
		xdpyinfo \
		xorg-x11-fonts \
		xorg-x11-server-Xvfb && \
	zypper -n clean -a
         
RUN	zypper -n install -y --no-recommends \
		gzip \
		tar \
		wget && \
	zypper -n clean -a && \
	wget -O- https://github.com/mozilla/geckodriver/releases/download/v0.27.0/geckodriver-v0.27.0-linux64.tar.gz | tar zxf - -C /usr/local/bin/

RUN	chmod +x /usr/local/bin/*

RUN	useradd -l -m -d /test test

COPY	*.py /

ENV     PYTHONPATH /
ENV	PYTHONUNBUFFERED 1
ENV	DBUS_SESSION_BUS_ADDRESS /dev/null

WORKDIR	/test

USER	test
ENTRYPOINT ["/usr/bin/python3", "/hawk_test.py"]
