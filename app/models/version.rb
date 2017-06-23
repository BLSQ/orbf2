# == Schema Information
#
# Table name: activities
#
#  id         :integer          not null, primary key
#  item_type  :string           not null
#  item_id    :integer          not null
#  event  	  :string           not null
#  whodunnit  :string
#  object     :jsonb
#  created_at :datetime         not null

class Version < PaperTrail::Version
  belongs_to :program
  belongs_to :project
  belongs_to :author, foreign_key: "whodunnit", class_name: "User"

  def diffs
    @diffs ||= build_diffs.compact.to_h
  end

  private

  def build_diffs
    changeset.map do |attribute_name, changes|
      next if ["updated_at", "password"].include?(attribute_name)
      next unless changes

      diff = if changes.last.to_s.lines.size > 10
               Differ.diff_by_line(changes.last.to_s, changes.first.to_s)
             else
               Differ.diff_by_word(changes.last.to_s, changes.first.to_s)
             end
      [
        attribute_name,
        OpenStruct.new(
          diff:    diff,
          changes: changes
        )
      ]
    end
  end
end
