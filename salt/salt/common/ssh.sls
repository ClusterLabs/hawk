vagrant_root:
  ssh_auth.present:
    - user: root
    - source: salt://sshkeys/vagrant.pub

vagrant_vagrant:
  ssh_auth.present:
    - user: vagrant
    - source: salt://sshkeys/vagrant.pub

krig_root:
  ssh_auth.present:
    - user: root
    - source: salt://sshkeys/krig.pub

krig_vagrant:
  ssh_auth.present:
    - user: vagrant
    - source: salt://sshkeys/krig.pub

/root/.ssh/id_rsa:
  file.managed:
    - source: salt://sshkeys/vagrant
    - user: root
    - group: root
    - mode: 600

/root/.ssh/id_rsa.pub:
  file.managed:
    - source: salt://sshkeys/vagrant.pub
    - user: root
    - group: root
    - mode: 644
