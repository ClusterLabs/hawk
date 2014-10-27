name "base"
description "Base role"

run_list(
  "recipe[hawk::node]"
)

default_attributes({

})

override_attributes({

})
