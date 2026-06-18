# == Schema Information
#
# Table name: dhis2_snapshots
#
#  id                :bigint(8)        not null, primary key
#  content           :jsonb            not null
#  dhis2_version     :string           not null
#  kind              :string           not null
#  month             :integer          not null
#  year              :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  job_id            :string           not null
#  project_anchor_id :integer
#
# Indexes
#
#  index_dhis2_snapshots_on_project_anchor_id  (project_anchor_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_anchor_id => project_anchors.id)
#

require "rails_helper"

RSpec.describe Dhis2Snapshot, type: :model do
  def snapshot_with(content:)
    project_anchor = FactoryBot.create(:project_anchor)
    snapshot = Dhis2Snapshot.create!(
      dhis2_version:     "does-not-matter",
      kind:              "does-not-matter",
      month:             1,
      year:              1,
      job_id:            "does-not-matter",
      project_anchor_id: project_anchor.id,
      content:           content
    )
  end

  describe 'scopes' do
    Dhis2Snapshot::KINDS.each do |kind|
      it "responds to the scope #{kind}" do
        expect(Dhis2Snapshot.public_send(kind).count).to eq(0)
      end
    end
  end

  describe "containing_dhis2_" do
    it "will find matching id" do
      dhis2_id = "fKb766I1Ma9"
      snapshot = snapshot_with(content: [{ "table"=>{ "id"=> dhis2_id } }])

      expect(Dhis2Snapshot.containing_dhis2_id(dhis2_id).first).to eq(snapshot)
    end

    it "will find matching display_name" do
      dhis2_display_name = "Inigo Montoya"
      project_anchor = FactoryBot.create(:project_anchor)
      snapshot = snapshot_with(content: [{ "table"=>{ "display_name"=> dhis2_display_name } }])

      expect(Dhis2Snapshot.containing_dhis2_display_name(dhis2_display_name).first).to eq(snapshot)
    end

    it "will not erroneously find matching display_name" do
      dhis2_display_name = "Inigo Montoya"
      snapshot = snapshot_with(content: [{ "table"=>{ "display_name"=> dhis2_display_name } }])

      expect(Dhis2Snapshot.containing_dhis2_display_name("fezzik").first).to eq(nil)
    end

    it "will not break if the json is not what we expected" do
      dhis2_display_name = "Inigo Montoya"
      snapshot = snapshot_with(content: { "o"=>{ "hai" => "there" } })

      expect(Dhis2Snapshot.containing_dhis2_display_name("fezzik").count).to eq(0)
    end
  end
end
