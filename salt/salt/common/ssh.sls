vagrant_root:
  ssh_auth.present:
    - user: root
    - source: salt://sshkeys/vagrant.pub
    - config: '%h/.ssh/authorized_keys'

vagrant_vagrant:
  ssh_auth.present:
    - user: vagrant
    - source: salt://sshkeys/vagrant.pub
    - config: '%h/.ssh/authorized_keys'

krig_root:
  ssh_auth.present:
    - user: root
    - source: salt://sshkeys/krig.pub
    - config: '%h/.ssh/authorized_keys'

krig_vagrant:
  ssh_auth.present:
    - user: vagrant
    - source: salt://sshkeys/krig.pub
    - config: '%h/.ssh/authorized_keys'
