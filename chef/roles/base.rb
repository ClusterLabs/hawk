name "base"
description "Base role"

run_list(
  "recipe[hosts]",
  "recipe[timezone]",
  "recipe[locales]",
  "recipe[zypper]",
  "recipe[sshkey]",
  "recipe[ntp]",
  "recipe[openssh]",
  "recipe[sudo]",
  "recipe[ruby]"
)

default_attributes({
  "zypper" => {
    "repos" => [
      {
        "title" => "Network HA Clustering",
        "alias" => "network-ha-clustering",
        "uri" => "http://download.opensuse.org/repositories/network:/ha-clustering:/Factory/openSUSE_13.1/",
        "key" => "http://download.opensuse.org/repositories/network:/ha-clustering:/Factory/openSUSE_13.1/repodata/repomd.xml.key"
      }
    ]
  },
  "sudo" => {
    "users" => [
      {
        "username" => "vagrant",
        "passwordless" => true
      }
    ]
  },
  "sshkey" => {
    "users" => [
      {
        "username" => "vagrant",
        "group" => "users",
        # Simply the vagrant unsecure private key
        "private_key" => "https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant",
        # Simply the vagrant unsecure public key
        "public_key" => "https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub",
        "keys" => {
          "vagrant" => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ=="
        }
      },
      {
        "username" => "root",
        "group" => "root",
        # Simply the vagrant unsecure private key
        "private_key" => "https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant",
        # Simply the vagrant unsecure public key
        "public_key" => "https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub",
        "keys" => {
          "vagrant" => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ=="
        }
      }
    ]
  },
  "hosts" => {
    "entries" => [
      {
        "ipaddress" => "10.13.37.10",
        "fqdn" => "webui",
        "aliases" => %w(webui)
      },
      {
        "ipaddress" => "10.13.37.11",
        "fqdn" => "node1",
        "aliases" => %w(node1)
      },
      {
        "ipaddress" => "10.13.37.12",
        "fqdn" => "node2",
        "aliases" => %w(node2)
      },
      {
        "ipaddress" => "10.13.37.13",
        "fqdn" => "node3",
        "aliases" => %w(node3)
      }
    ]
  }
})

override_attributes({})
