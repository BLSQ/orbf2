namespace :db do
  desc "pull db and create dhis2 logs table if not present"
  task fetch: :environment do
    app_name = ENV.fetch("APP_NAME")
    db_name = ENV.fetch("DB_NAME", "orbf2")
    command = "heroku pg:pull DATABASE_URL #{db_name} --app #{app_name} --exclude-table-data \"dhis2_logs;dhis2_snapshots;dhis2_snapshot_changes\""
    puts command
    `#{command}`
    unless ActiveRecord::Base.connection.data_source_exists?("dhis2_logs")
      puts "creating dhis2_logs"
      ActiveRecord::Base.connection.create_table "dhis2_logs", force: :cascade do |t|
        t.jsonb "sent"
        t.jsonb    "status"
        t.integer  "project_anchor_id"
        t.datetime "created_at",        null: false
        t.datetime "updated_at",        null: false
        t.index ["project_anchor_id"], name: "index_dhis2_logs_on_project_anchor_id", using: :btree
      end
      ActiveRecord::Base.connection.create_table "dhis2_snapshots", id: :serial, force: :cascade do |t|
        t.string "kind", null: false
        t.jsonb "content", null: false
        t.integer "project_anchor_id"
        t.string "dhis2_version", null: false
        t.integer "year", null: false
        t.integer "month", null: false
        t.string "job_id", null: false
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
        t.index ["project_anchor_id"], name: "index_dhis2_snapshots_on_project_anchor_id"
      end
      ActiveRecord::Base.connection.create_table "dhis2_snapshot_changes", force: :cascade do |t|
        t.string   "dhis2_id", null: false
        t.integer  "dhis2_snapshot_id"
        t.jsonb    "values_before"
        t.jsonb    "values_after"
        t.string   "whodunnit"
        t.datetime "created_at",        null: false
        t.datetime "updated_at",        null: false
        t.index ["dhis2_snapshot_id"], name: "index_dhis2_snapshot_changes_on_dhis2_snapshot_id", using: :btree
      end
    end
  end
end
