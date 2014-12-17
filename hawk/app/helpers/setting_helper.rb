module SettingHelper
  def language_options(selected)
    options = translated_languages.to_a.map do |v|
      v[1] = "#{v[1]} [#{v[0].downcase}]"
      v.reverse
    end

    options_for_select(
      options,
      selected
    )
  end

  def translated_languages
    @translated_languages ||= begin
      languages = YAML.load_file(
        Rails.root.join(
          'config',
          'languages.yml'
        ).to_s
      )

      result = I18n.available_locales.map do |locale|
        [locale.to_s.gsub('_', '-'), languages[locale]]
      end.sort_by { |v| v.first.to_s }

      ActiveSupport::OrderedHash[result].symbolize_keys
    end
  end
end
