network:ha-clustering:Factory:
  pkgrepo.managed:
    - humanname: network:ha-clustering:Factory
    - baseurl: http://download.opensuse.org/repositories/network:/ha-clustering:/Factory/openSUSE_Tumbleweed/
    - refresh: True
    - gpgautoimport: True

common_packages:
  pkg.installed:
    - names:
        - ha-cluster-bootstrap
        - fence-agents
        - apache2
        - haproxy
        - hawk-apiserver
        - libglue-devel
        - drbd
        - drbd-utils
        - nodejs6
        - ruby2.4-rubygem-rails-5_1
        - ruby2.4-rubygem-puma
        - ruby2.4-rubygem-sass-rails
        - ruby2.4-rubygem-virtus
        - ruby2.4-rubygem-js-routes
        - ruby2.4-rubygem-fast_gettext
        - ruby2.4-rubygem-gettext_i18n_rails
        - ruby2.4-rubygem-gettext_i18n_rails_js
        - ruby2.4-rubygem-sprockets
        - ruby2.4-rubygem-kramdown
        - make
        - gcc
    - require:
        - pkgrepo: network:ha-clustering:Factory

