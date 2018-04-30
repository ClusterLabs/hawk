module Helpers
  module ApiHelpers
    def pass_fake_yaml_store
      fake_yaml_store = YAML.load_file(file_fixture("api_token_dummy.store"))
      allow(File).to receive(:open).and_return(fake_yaml_store)
    end
  end
end
