Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
See COPYING for license.

module Haml
  class Compiler
    class << self
      def build_attributes_with_dasherize(is_html, attr_wrapper, escape_attrs, hyphenate_data_attrs, attributes = {})
        new_attributes = {}.tap do |dasherized|
          attributes.keys.each do |key|
            dasherized[key.to_s.gsub("_", "-").to_sym] = attributes[key]
          end
        end

        build_attributes_without_dasherize(
          is_html,
          attr_wrapper,
          escape_attrs,
          hyphenate_data_attrs,
          new_attributes
        )
      end

      alias_method :build_attributes_without_dasherize, :build_attributes
      alias_method :build_attributes, :build_attributes_with_dasherize
    end
  end
end

Haml::Template.options[:attr_wrapper] = "\""
