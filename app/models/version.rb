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
      next if attribute_name == "updated_at"
      diff = if changes.first.lines.size > 10
               Differ.diff_by_line(changes.last, changes.first)
             else
               Differ.diff_by_word(changes.last, changes.first)
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
