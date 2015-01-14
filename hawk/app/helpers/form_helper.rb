module FormHelper
  def errors_for(record)
    unless record.errors[:base].empty?
      content_tag(
        :div,
        record.errors[:base].first.html_safe,
        class: 'alert alert-danger',
        role: 'alert'
      )
    end
  end

  def form_for(record, options, &proc)
    unless options.fetch(:bootstrap, true)
      return super(record, options, &proc)
    end

    options[:validate] = true

    options[:builder] ||= Hawk::FormBuilder

    options[:html] ||= {}
    options[:html][:role] ||= 'form'
    options[:html][:class] ||= ''

    if options.fetch(:inline, false)
      options[:html][:class] = [
        'form-inline',
        options[:html][:class]
      ].join(' ')
    end

    if options.fetch(:horizontal, false)
      options[:html][:class] = [
        'form-horizontal',
        options[:html][:class]
      ].join(' ')
    end

    if options.fetch(:simple, false)
      options[:html][:class] = [
        'form-simple',
        options[:html][:class]
      ].join(' ')
    end

    options[:html][:class].strip!

    super(record, options, &proc)
  end
end
