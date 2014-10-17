name "base"
description "Base role"

run_list(
  "recipe[build]",
  "recipe[git]",
  "recipe[hawk::webui]"
)

default_attributes({

})

override_attributes({

})
