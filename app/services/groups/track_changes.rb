module Groups
  class TrackChanges
    def initialize(dhis2_snapshot:, current:, previous:, whodunnit:)
      @dhis2_snapshot = dhis2_snapshot
      @current = current
      @previous = previous
      @whodunnit = whodunnit
    end

    def call
      added_or_modifieds = (current - previous).index_by { |e| e["id"] }
      removed_or_modifieds = (previous - current).index_by { |e| e["id"] }

      all_ids = (added_or_modifieds.keys + removed_or_modifieds.keys).uniq

      all_ids.each do |dhis2_id|
        added_or_modified = added_or_modifieds[dhis2_id]
        removed_or_modified = removed_or_modifieds[dhis2_id]
        if added_or_modified && removed_or_modified
          create_change(added_or_modified, removed_or_modified, dhis2_id)
        elsif added_or_modified
          create_added(added_or_modified, dhis2_id)
        elsif
          create_deleted(removed_or_modified, dhis2_id)
        end
      end
    end

    private

    attr_reader :dhis2_snapshot, :current, :previous, :whodunnit

    def create_deleted(removed_or_modified, dhis2_id)
      dhis2_snapshot.dhis2_snapshot_changes.create(
        dhis2_id:       dhis2_id,
        dhis2_snapshot: dhis2_snapshot,
        values_before:  removed_or_modified,
        values_after:   {},
        whodunnit:      whodunnit
      )
    end

    def create_added(added_or_modified, dhis2_id)
      dhis2_snapshot.dhis2_snapshot_changes.create(
        dhis2_id:       dhis2_id,
        dhis2_snapshot: dhis2_snapshot,
        values_before:  {},
        values_after:   added_or_modified,
        whodunnit:      whodunnit
      )
        end

    def create_change(added_or_modified, removed_or_modified, dhis2_id)
      values_before = {}
      values_after = {}
      attribute_keys = (added_or_modified.keys + removed_or_modified.keys).uniq
      attribute_keys.each do |k|
        next unless added_or_modified[k] != removed_or_modified[k]
        values_after[k] = added_or_modified[k]
        values_before[k] = removed_or_modified[k]
      end
      dhis2_snapshot.dhis2_snapshot_changes.create(
        dhis2_id:       dhis2_id,
        dhis2_snapshot: dhis2_snapshot,
        values_before:  values_before,
        values_after:   values_after,
        whodunnit:      whodunnit
      )
    end
  end
end
