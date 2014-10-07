name "base"
description "Base role"

run_list(
  "recipe[build]",
  "recipe[git]",
  "recipe[hawk::webui]"
)

default_attributes({
  "git" => {
    "zypper" => {
      "enabled" => false
    }
  },
  "foreman" => {
    "executable" => "/usr/bin/foreman.ruby2.1"
  }
})

override_attributes({
  "foreman" => {
    "gems" => %w(foreman),
    "packages" => %w()
  }
})
