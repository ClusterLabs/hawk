devel:languages:ruby:
  pkgrepo.managed:
    - humanname: devel:languages:ruby
    - baseurl: http://download.opensuse.org/repositories/devel:/languages:/ruby/openSUSE_Leap_42.3/
    - refresh: True
    - gpgautoimport: True

devel:languages:ruby:extensions:
  pkgrepo.managed:
    - humanname: devel:languages:ruby:extensions
    - baseurl: http://download.opensuse.org/repositories/devel:/languages:/ruby:/extensions/openSUSE_Leap_42.3/
    - refresh: True
    - gpgautoimport: True

network:ha-clustering:Factory:
  pkgrepo.managed:
    - humanname: network:ha-clustering:Factory
    - baseurl: http://download.opensuse.org/repositories/network:/ha-clustering:/Factory/openSUSE_Leap_42.3/
    - refresh: True
    - gpgautoimport: True

home:KGronlund:branches:devel:languages:ruby:extensions:
  pkgrepo.managed:
    - humanname: home:KGronlund:branches:devel:languages:ruby:extensions
    - baseurl: http://download.opensuse.org/repositories/home:/KGronlund:/branches:/devel:/languages:/ruby:/extensions/openSUSE_Leap_42.3/
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
    - require:
        - pkgrepo: network:ha-clustering:Factory
        - pkgrepo: devel:languages:ruby
        - pkgrepo: devel:languages:ruby:extensions
        - pkgrepo: home:KGronlund:branches:devel:languages:ruby:extensions

