# == Schema Information
#
# Table name: versions
#
#  id             :integer          not null, primary key
#  event          :string           not null
#  item_type      :string           not null
#  object         :jsonb
#  object_changes :jsonb
#  old_object     :text
#  whodunnit      :string
#  created_at     :datetime
#  item_id        :integer          not null
#  program_id     :integer
#  project_id     :integer
#  transaction_id :integer
#
# Indexes
#
#  index_versions_on_item_type_and_item_id  (item_type,item_id)
#  index_versions_on_program_id             (program_id)
#  index_versions_on_project_id             (project_id)
#  index_versions_on_transaction_id         (transaction_id)
#
# Foreign Keys
#
#  fk_rails_...  (program_id => programs.id)
#  fk_rails_...  (project_id => projects.id)
#

class Version < PaperTrail::Version
  belongs_to :program
  belongs_to :project
  belongs_to :author, foreign_key: "whodunnit", class_name: "User", optional: true

  def diffs
    @diffs ||= build_diffs.compact.to_h
  end

  private

  def build_diffs
    changeset.map do |attribute_name, changes|
      next if %w[updated_at password].include?(attribute_name)
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
