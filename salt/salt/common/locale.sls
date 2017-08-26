{% set us_locale = salt['grains.filter_by']({
    'Debian': 'en_US.UTF-8',
    'SUSE': 'en_US.utf8',
}, default='SUSE') %}

us_locale:
  locale.present:
    - name: {{ us_locale }}

default_locale:
  locale.system:
    - name: {{ us_locale }}
    - require:
      - locale: us_locale
