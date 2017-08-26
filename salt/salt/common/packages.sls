rubyext:
  pkgrepo.managed:
    - humanname: devel:languages:ruby:extensions
    - baseurl: http://download.opensuse.org/repositories/devel:/languages:/ruby:/extensions/openSUSE_Leap_42.3/
    - refresh: True
    - gpgautoimport: True

darix:
  pkgrepo.managed:
    - humanname: home:darix:apps
    - baseurl: http://download.opensuse.org/repositories/home:/darix:/apps/openSUSE_Leap_42.3/
    - refresh: True
    - gpgautoimport: True

common_packages:
  pkg.installed:
    - names:
        - ha-cluster-bootstrap
        - fence-agents
        - apache2
        - haproxy
        - libglue-devel
        - drbd
        - drbd-utils
        - nodejs8
        - ruby2.4-rubygem-rails-5.1
        - ruby2.4-rubygem-puma
        - ruby2.4-rubygem-sass-rails-5_0
        - ruby2.4-rubygem-virtus
        - ruby2.4-rubygem-js-routes
        - ruby2.4-rubygem-tilt
        - ruby2.4-rubygem-fast_gettext
        - ruby2.4-rubygem-gettext_i18n_rails
        - ruby2.4-rubygem-gettext_i18n_rails_js
        - ruby2.4-rubygem-sprockets
        - ruby2.4-rubygem-kramdown
        - ruby2.4-rubygem-web-console
        - ruby2.4-rubygem-spring
        - ruby2.4-rubygem-uglifier
        - ruby2.4-rubygem-gettext
    - require:
        - pkgrepo: darix
        - pkgrepo: rubyext
