# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module TemplateHelper
  def template_clazz_options(selected)
    options = [].tap do |result|
      ::Template.options.each do |clazz, providers|
        next if clazz.empty?

        result.push [
          clazz,
          clazz
        ]
      end
    end

    options_for_select(
      options,
      selected
    )
  end

  def template_provider_options(selected)
    options = [].tap do |result|
      ::Template.options.each do |clazz, providers|
        providers.each do |provider, types|
          next if provider.empty?

          result.push [
            provider,
            provider,
            data: {
              clazz: clazz
            }
          ]
        end
      end
    end

    options_for_select(
      options,
      selected
    )
  end

  def template_type_options(selected)
    options = [].tap do |result|
      ::Template.options.each do |clazz, providers|
        providers.each do |provider, types|
          types.each do |type|
            next if type.empty?

            result.push [
              type,
              type,
              data: {
                clazz: clazz,
                provider: provider
              }
            ]
          end
        end
      end
    end

    options_for_select(
      options,
      selected
    )
  end

  def template_meta_for(options = {})
    template_values_for(:available_meta, options)
  end

  def template_params_for(options = {})
    template_values_for(:available_params, options)
  end

  def template_ops_for(options = {})
    template_values_for(:available_ops, options)
  end

  protected

  def template_values_for(method, options = {})
    ::Template.send(method, {
      clazz: options[:clazz],
      provider: options[:provider],
      type: options[:type]
    })
  end
end
