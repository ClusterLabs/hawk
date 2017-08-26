/etc/drbd.d/global_common.conf:
  file.managed:
    - source: salt://files/global_common.conf
    - user: root
    - group: root
    - mode: 644

/etc/drbd.d/r0.res:
  file.managed:
    - source: salt://files/r0.res
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
{% if 'vdc' in grains['disks'] %}
        disk: /dev/vdc
{% else %}
        disk: /dev/sdc
{% endif %}

