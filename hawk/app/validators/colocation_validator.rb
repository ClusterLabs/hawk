class ColocationValidator < ActiveModel::Validator
  
  def validate(record)  
    unless record.score.blank?
      record.score.strip!
      unless [
        "mandatory",
        "advisory",
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

    unless record.node_attr.blank?
      unless record.node_attr.match(/\A[a-zA-Z0-9_-]+\z/)
        record.errors[:node_attr] << _("Invalid node attribute")
      end
    end

    if record.resources.length < 2
      record.errors[:base] << _("Constraint must consist of at least two separate resources")
    end
  end

end