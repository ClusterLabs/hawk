name "base"
description "Base role"

run_list(
  "recipe[build]",
  "recipe[hawk::webui]"
)

default_attributes({

})

override_attributes({

})
