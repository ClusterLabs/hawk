webui_packages:
  pkg.installed:
    - names:
        - glib2-devel
        - libxml2-devel
        - pam-devel
        - libpacemaker-devel
        - libglue-devel

    - require:
        - pkg: common_packages

salt://utils/install_tools.sh:
  cmd.script:
    - require:
        - pkg: webui_packages

salt://utils/init_cluster.sh:
  cmd.script:
    - require:
        - cmd: "salt://utils/install_tools.sh"
