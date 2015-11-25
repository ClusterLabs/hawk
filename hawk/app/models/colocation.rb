# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Colocation < Constraint
  attribute :id, String
  attribute :score, String
  attribute :node_attr, String
  attribute :resources, Array[Hash]

  validates :id,
    presence: { message: _("Constraint ID is required") },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _("Invalid Constraint ID") }

  validates :score,
    presence: { message: _("Score is required") }

  validate do |record|
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
        errors.add :score, _("Invalid score value")
      end
    end

    if record.resources.length < 2
      errors.add :base, _("Constraint must consist of at least two separate resources")
    end
  end

  def resources
    @resources ||= []
  end

  def resources=(value)
    @resources = value
  end

  class << self
    def all
      super.select do |record|
        record.is_a? self
      end
    end
  end

  protected

  def shell_syntax
    [].tap do |cmd|

      cmd.push "colocation #{@id} #{@score}:"

      #
      # crm syntax matches nasty inconsistency in CIB, i.e. to get:
      #
      #   d6 -> d5 -> ( d4 d3 ) -> d2 -> d1 -> d0
      #
      # you use:
      #
      #   colocation <id> <score>: d5 d6 ( d3 d4 ) d0 d1 d2
      #
      # except when using simple constrains, i.e. to get:
      #
      #   d1 -> d0
      #
      # you use:
      #
      #   colocation <id> <score>: d1 d0
      #
      # To further confuse matters, duplicate roles in complex chains
      # are collapsed to sets, so for:
      #
      #   d2:Master -> d1:Started -> d0:Started
      #
      # you use:
      #
      #   colocation <id> <score>: d2:Master d0:Started d1:Started
      #
      # To deal with this, we need to collapse all the sets first
      # then iterate through them (unlike the Order model, where
      # this is unnecessary)

      # Have to clone out of @resources, else we've just got references
      # to elements of @resources inside collapsed, which causes @resources
      # to be modified, which we *really* don't want.
      collapsed = [ @resources.first.clone ]
      @resources.last(@resources.length - 1).each do |set|
        if collapsed.last[:sequential] == set[:sequential] &&
           collapsed.last[:action] == set[:action]
          collapsed.last[:resources] += set[:resources]
        else
          collapsed << set.clone
        end
      end

      if collapsed.length == 1 && collapsed[0][:resources].length == 2
        # simple constraint (it's already in reverse order so
        # don't flip around the other way like we do below)
        simpleset = collapsed[0]
        simpleset[:resources].each do |r|
          cmd.push r + (simpleset[:action] ? ":#{simpleset[:action]}" : "")
        end
      else
        collapsed.each do |set2|
          cmd.push " ( " unless set2[:sequential]
          set2[:resources].reverse_each do |r|
            cmd.push r + (set2[:action] ? ":#{set2[:action]}" : "")
          end
          cmd.push " )" unless set2[:sequential]
        end
      end

      unless node_attr.blank?
        cmd.push "node-attribute=#{node_attr}"
      end
    end.join(" ")
  end

  class << self
    def instantiate(xml)
      record = allocate
      record.score = xml.attributes["score"] || nil

      record.resources = [].tap do |resources|
        if xml.attributes["rsc"]
          resources.push(
            sequential: true,
            action: xml.attributes["rsc-role"] || nil,
            resources: [
              xml.attributes["rsc"]
            ]
          )

          resources.push(
            sequential: true,
            action: xml.attributes["with-rsc-role"] || nil,
            resources: [
              xml.attributes["with-rsc"]
            ]
          )
        else
          xml.elements.each do |resource|
            set = {
              sequential: Util.unstring(resource.attributes["sequential"], true),
              action: resource.attributes["role"] || nil,
              resources: []
            }

            resource.elements.each do |el|
              set[:resources].unshift(
                el.attributes["id"]
              )
            end

            resources.push set
          end
        end
      end

      record
    end

    def cib_type_write
      :rsc_colocation
    end
  end
end
