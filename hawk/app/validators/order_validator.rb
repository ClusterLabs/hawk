class OrderValidator < ActiveModel::Validator
    
  def validate(record)
    unless record.score.blank?
      record.score.strip!
      unless [
        "mandatory",
        "optional",
        "serialize",
        "inf",
        "-inf",
        "infinity",
        "-infinity"
      ].include? record.score.downcase
        unless record.score.match(/^-?[0-9]+$/)
          record.errors[:score] << _("Invalid score value")
        end
      end
    else
      record.errors[:score] << _("Score is required")
    end

    if record.resources.length < 2
      record.errors[:base] << _("Constraint must consist of at least two separate resources")
    end
  end

end