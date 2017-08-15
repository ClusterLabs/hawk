# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module Hawk
  class FormBuilder < ActionView::Helpers::FormBuilder
    def fields_for(record_name, record_object = nil, args = {}, &block)
      unless options.fetch(:bootstrap, true)
        return super
      end

      if options[:inline]
        args[:inline] = true
      end

      if options[:horizontal]
        args[:horizontal] = true
      end

      if options[:simple]
        args[:simple] = true
      end

      args[:builder] ||= Hawk::FormBuilder

      super(record_name, record_object, args, &block)
    end

    %w(
      text_field
      password_field
    ).each do |method_name|
      define_method method_name.to_sym do |field, *args|
        unless options.fetch(:bootstrap, true)
          return super
        end

        field_options = args.extract_options!
        field_options[:class] = "#{field_options[:class]} #{form_field_class_for(field, method_name)}".strip

        group_options = field_options.fetch(:group, {})
        group_options[:class] = "#{group_options[:class]} #{form_group_class_for(field, method_name)}".strip

        label_options = field_options.fetch(:label, {})

        field_options.delete(:label)
        field_options.delete(:group)

        if label_options.is_a? String
          label_options = {
            value: label_options
          }
        end

        label_options[:class] = "#{label_options[:class]} #{label_tag_class_for(field, method_name)}".strip

        help_options = field_options.fetch(:help, {})
        field_options.delete(:help)

        if help_options.is_a? String
          help_options = {
            value: help_options
          }
        end

        label_tag = if field_options === false
          nil
        else
          build_label_tag(
            field,
            label_options
          )
        end

        help_block = if field_options.fetch(:help, false)
          build_help_block(
            field,
            help_options
          )
        else
          nil
        end

        form_group(field, group_options) do
          content = [
            super(field, field_options),
            help_block,
            errors_for(field)
          ].compact.join('').html_safe

          input_tag = case
          when options[:horizontal]
            @template.content_tag(
              :div,
              content,
              class: horizontal_field_class
            )
          else
            content
          end

          [
            label_tag,
            input_tag
          ].compact.join('').html_safe
        end.html_safe
      end
    end

    def select(field, choices = nil, args = {}, html = {})
      unless options.fetch(:bootstrap, true)
        return super
      end

      if choices.is_a? Symbol
        choices = @template.send(choices, @object[field])
      end

      field_options = html
      field_options[:class] = "#{field_options[:class]} #{form_field_class_for(field, 'select')}".strip

      group_options = field_options.fetch(:group, {})
      group_options[:class] = "#{group_options[:class]} #{form_group_class_for(field, 'select')}".strip

      label_options = field_options.fetch(:label, {})

      field_options.delete(:label)
      field_options.delete(:group)

      if label_options.is_a? String
        label_options = {
          value: label_options
        }
      end

      label_options[:class] = "#{label_options[:class]} #{label_tag_class_for(field, 'select')}".strip

      help_options = field_options.fetch(:help, {})

      if help_options.is_a? String
        help_options = {
          value: help_options
        }
      end

      label_tag = if field_options === false
        nil
      else
        build_label_tag(
          field,
          label_options
        )
      end

      help_block = if field_options.fetch(:help, false)
        build_help_block(
          field,
          help_options
        )
      else
        nil
      end

      form_group(field, group_options) do
        content = [
          super(field, choices, args, field_options),
          help_block,
          errors_for(field)
        ].compact.join('').html_safe

        input_tag = case
        when options[:horizontal]
          @template.content_tag(
            :div,
            content,
            class: horizontal_field_class
          )
        else
          content
        end

        [
          label_tag,
          input_tag
        ].compact.join('').html_safe
      end.html_safe
    end

    def form_group(field = nil, args = {}, &block)
      unless args.is_a? Hash
        raise "Expected hash for options, got #{args.inspect}"
      end

      args[:class] = Array(args[:class])
      args[:class].push form_group_class

      if has_error_on? field
        args[:class].push form_group_error
      end

      args[:class] = args[:class].join(' ').strip

      @template.content_tag(:div, args) do
        @template.capture &block
      end
    end

    def button_group(args = {}, &block)
      if options.fetch(:horizontal, false)
        clazz = button_group_class

        if args[:class]
          clazz = [
            clazz,
            args[:class]
          ].join(" ")
        end

        @template.content_tag(
          button_group_tag,
          @template.content_tag(
            button_group_tag,
            @template.capture(&block),
            class: 'btn-group',
            role: 'group'
          ),
          class: clazz
        )
      else
        @template.capture(&block)
      end
    end

    protected

    def build_label_tag(field, args)
      if options.fetch(:horizontal, false)
        args[:class] = "#{args[:class]} #{horizontal_label_class}".strip
      end

      if block_given?
        label(field, args.delete(:value), args) do
          yield(args)
        end
      else
        label(field, args.delete(:value), args)
      end
    end

    def build_help_block(field, args)
      args[:class] = "#{args[:class]} #{help_block_class}".strip

      @template.content_tag(
        help_block_tag,
        args.delete(:value),
        args
      )
    end

    def horizontal_field_class
      'col-sm-7'
    end

    def horizontal_label_class
      'col-sm-5 control-label'
    end

    def button_group_tag
      :span
    end

    def button_group_class
      'col-sm-offset-5 col-sm-7'
    end

    def help_block_tag
      :span
    end

    def help_block_class
      'help-block'
    end

    def form_group_class
      'form-group'
    end

    def form_group_error
      'has-error has-feedback'
    end

    def label_tag_class_for(field, method_name)
      ''
    end

    def form_group_class_for(field, method)
      ''
    end

    def form_field_class_for(field, method)
      [
        'form-control',
        method.gsub('_', '-')
      ].join(' ')
    end

    def has_error_on?(field)
      @object and @object.errors.messages.has_key?(field) and @object.errors.messages[field].any?
    end

    def errors_for(field)
      if has_error_on? field
        @template.icon_tag(
          class: 'fa-lg form-control-feedback',
          title: @object.errors.messages[field].first,
          data: {
            toggle: 'tooltip'
          }
        )
      else
        nil
      end
    end
  end
end
