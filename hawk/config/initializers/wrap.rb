# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

ActiveSupport.on_load :action_controller do
  wrap_parameters format: [:json] if respond_to? :wrap_parameters
end

ActiveSupport.on_load(:active_record) do
  self.include_root_in_json = false
end
