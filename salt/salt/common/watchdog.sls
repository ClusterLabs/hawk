setup_watchdog:
  kmod.present:
    - name: softdog
    - persist: True
