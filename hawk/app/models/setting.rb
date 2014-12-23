class Setting < Tableless
  class << self
    def available_languages
      @available_languages ||= begin
        languages = YAML.load_file(
          Rails.root.join(
            'config',
            'languages.yml'
          ).to_s
        )

        result = I18n.available_locales.map do |locale|
          locale.to_s.gsub! '-', '_'
          [locale, languages[locale]]
        end.sort_by { |v| v.first.to_s }

        ActiveSupport::OrderedHash[result].symbolize_keys
      end
    end
  end

  attribute :language, String, default: ::I18n.locale

  validates :language,
    presence: {
      message: _('Language is required')
    },
    inclusion: {
      in: available_languages.keys.map(&:to_s),
      message: "Is not a valid language"
    }
end
