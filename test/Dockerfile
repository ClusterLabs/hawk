FROM krig/crmsh:latest
MAINTAINER Kristoffer Gronlund version: 0.1

ENV container docker

VOLUME [ "/sys/fs/cgroup" ]

RUN zypper -n --no-gpg-checks ar obs://network:ha-clustering:BuildDep/openSUSE_Leap_42.3 network:ha-clustering:BuildDep

RUN zypper -n --no-gpg-checks ref

RUN zypper -n --no-gpg-checks in ruby2.5-devel ruby2.5-rubygem-bundler libxml2-devel libxslt-devel gcc make patch nodejs6

RUN zypper -n --no-gpg-checks in ruby2.5-rubygem-puma ruby2.5-rubygem-virtus ruby2.5-rubygem-fast_gettext ruby2.5-rubygem-sprockets ruby2.5-rubygem-kramdown ruby2.5-rubygem-uglifier ruby2.5-rubygem-gettext ruby2.5-rubygem-nokogiri

CMD ["/usr/lib/systemd/systemd", "--system"]
