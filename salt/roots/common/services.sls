/srv/www/htdocs/index.html:
  file.managed:
    - source: salt://files/index.html
    - template: jinja
    - context:
        hostname: "{{ grains['id'] }}"

/etc/haproxy/haproxy.cfg:
  file.managed:
    - source: salt://files/haproxy.cfg
    - template: jinja

/etc/apache2/listen.conf:
  file.replace:
    - pattern: '^Listen \d+$'
    - repl: "Listen 8000"
