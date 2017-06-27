# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170627063702) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "activities", force: :cascade do |t|
    t.string   "name",                                             null: false
    t.integer  "project_id",                                       null: false
    t.uuid     "stable_id",  default: -> { "uuid_generate_v4()" }, null: false
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.index ["name", "project_id"], name: "index_activities_on_name_and_project_id", unique: true, using: :btree
    t.index ["project_id"], name: "index_activities_on_project_id", using: :btree
  end

  create_table "activity_packages", force: :cascade do |t|
    t.integer  "activity_id",                                       null: false
    t.integer  "package_id",                                        null: false
    t.uuid     "stable_id",   default: -> { "uuid_generate_v4()" }, null: false
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.index ["activity_id"], name: "index_activity_packages_on_activity_id", using: :btree
    t.index ["package_id", "activity_id"], name: "index_activity_packages_on_package_id_and_activity_id", unique: true, using: :btree
    t.index ["package_id"], name: "index_activity_packages_on_package_id", using: :btree
  end

  create_table "activity_states", force: :cascade do |t|
    t.string   "external_reference"
    t.string   "name",                                                     null: false
    t.integer  "state_id",                                                 null: false
    t.integer  "activity_id",                                              null: false
    t.uuid     "stable_id",          default: -> { "uuid_generate_v4()" }, null: false
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
    t.string   "kind",               default: "data_element",              null: false
    t.string   "formula"
    t.index ["activity_id"], name: "index_activity_states_on_activity_id", using: :btree
    t.index ["external_reference", "activity_id"], name: "index_activity_states_on_external_reference_and_activity_id", unique: true, using: :btree
    t.index ["state_id"], name: "index_activity_states_on_state_id", using: :btree
  end

  create_table "decision_tables", force: :cascade do |t|
    t.integer "rule_id"
    t.text    "content"
    t.index ["rule_id"], name: "index_decision_tables_on_rule_id", using: :btree
  end

  create_table "dhis2_logs", force: :cascade do |t|
    t.jsonb    "sent"
    t.jsonb    "status"
    t.integer  "project_anchor_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.index ["project_anchor_id"], name: "index_dhis2_logs_on_project_anchor_id", using: :btree
  end

  create_table "dhis2_snapshots", force: :cascade do |t|
    t.string   "kind",              null: false
    t.jsonb    "content",           null: false
    t.integer  "project_anchor_id"
    t.string   "dhis2_version",     null: false
    t.integer  "year",              null: false
    t.integer  "month",             null: false
    t.string   "job_id",            null: false
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.index ["project_anchor_id"], name: "index_dhis2_snapshots_on_project_anchor_id", using: :btree
  end

  create_table "entity_groups", force: :cascade do |t|
    t.string   "name"
    t.string   "external_reference"
    t.integer  "project_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["project_id"], name: "index_entity_groups_on_project_id", using: :btree
  end

  create_table "formula_mappings", force: :cascade do |t|
    t.integer "formula_id",         null: false
    t.integer "activity_id"
    t.string  "external_reference", null: false
    t.string  "kind",               null: false
    t.index ["activity_id"], name: "index_formula_mappings_on_activity_id", using: :btree
    t.index ["formula_id"], name: "index_formula_mappings_on_formula_id", using: :btree
  end

  create_table "formulas", force: :cascade do |t|
    t.string   "code",        null: false
    t.string   "description", null: false
    t.text     "expression",  null: false
    t.integer  "rule_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["rule_id"], name: "index_formulas_on_rule_id", using: :btree
  end

  create_table "package_entity_groups", force: :cascade do |t|
    t.string   "name"
    t.integer  "package_id"
    t.string   "organisation_unit_group_ext_ref"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.index ["package_id"], name: "index_package_entity_groups_on_package_id", using: :btree
  end

  create_table "package_payment_rules", force: :cascade do |t|
    t.integer  "package_id",      null: false
    t.integer  "payment_rule_id", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["package_id"], name: "index_package_payment_rules_on_package_id", using: :btree
    t.index ["payment_rule_id"], name: "index_package_payment_rules_on_payment_rule_id", using: :btree
  end

  create_table "package_states", force: :cascade do |t|
    t.integer  "package_id"
    t.integer  "state_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "ds_external_reference"
    t.string   "deg_external_reference"
    t.string   "de_external_reference"
    t.index ["package_id", "state_id"], name: "index_package_states_on_package_id_and_state_id", unique: true, using: :btree
    t.index ["package_id"], name: "index_package_states_on_package_id", using: :btree
    t.index ["state_id", "package_id"], name: "index_package_states_on_state_id_and_package_id", unique: true, using: :btree
    t.index ["state_id"], name: "index_package_states_on_state_id", using: :btree
  end

  create_table "packages", force: :cascade do |t|
    t.string   "name",                                                             null: false
    t.string   "data_element_group_ext_ref",                                       null: false
    t.string   "frequency",                                                        null: false
    t.integer  "project_id"
    t.datetime "created_at",                                                       null: false
    t.datetime "updated_at",                                                       null: false
    t.uuid     "stable_id",                  default: -> { "uuid_generate_v4()" }, null: false
    t.string   "kind",                       default: "single"
    t.string   "ogs_reference"
    t.index ["project_id"], name: "index_packages_on_project_id", using: :btree
  end

  create_table "payment_rules", force: :cascade do |t|
    t.integer  "project_id",                       null: false
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.string   "frequency",  default: "quarterly", null: false
    t.index ["project_id"], name: "index_payment_rules_on_project_id", using: :btree
  end

  create_table "programs", force: :cascade do |t|
    t.string   "code",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_programs_on_code", unique: true, using: :btree
  end

  create_table "project_anchors", force: :cascade do |t|
    t.integer  "program_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id"], name: "index_project_anchors_on_program_id", using: :btree
  end

  create_table "projects", force: :cascade do |t|
    t.string   "name",                                null: false
    t.string   "dhis2_url",                           null: false
    t.string   "user"
    t.string   "password"
    t.boolean  "bypass_ssl",        default: false
    t.boolean  "boolean",           default: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "status",            default: "draft", null: false
    t.datetime "publish_date"
    t.integer  "project_anchor_id"
    t.integer  "original_id"
    t.index ["project_anchor_id"], name: "index_projects_on_project_anchor_id", using: :btree
  end

  create_table "rules", force: :cascade do |t|
    t.string   "name",                                                  null: false
    t.string   "kind",                                                  null: false
    t.integer  "package_id"
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.integer  "payment_rule_id"
    t.uuid     "stable_id",       default: -> { "uuid_generate_v4()" }, null: false
    t.index ["package_id"], name: "index_rules_on_package_id", using: :btree
    t.index ["payment_rule_id"], name: "index_rules_on_payment_rule_id", using: :btree
  end

  create_table "states", force: :cascade do |t|
    t.string   "name",                              null: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.boolean  "configurable", default: false,      null: false
    t.string   "level",        default: "activity", null: false
    t.integer  "project_id"
    t.index ["project_id"], name: "index_states_on_project_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "program_id"
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["program_id"], name: "index_users_on_program_id", using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  create_table "version_associations", force: :cascade do |t|
    t.integer "version_id"
    t.string  "foreign_key_name", null: false
    t.integer "foreign_key_id"
    t.index ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key", using: :btree
    t.index ["version_id"], name: "index_version_associations_on_version_id", using: :btree
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "old_object"
    t.datetime "created_at"
    t.integer  "transaction_id"
    t.jsonb    "object"
    t.integer  "program_id"
    t.integer  "project_id"
    t.jsonb    "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
    t.index ["program_id"], name: "index_versions_on_program_id", using: :btree
    t.index ["project_id"], name: "index_versions_on_project_id", using: :btree
    t.index ["transaction_id"], name: "index_versions_on_transaction_id", using: :btree
  end

  add_foreign_key "activities", "projects"
  add_foreign_key "activity_packages", "activities"
  add_foreign_key "activity_packages", "packages"
  add_foreign_key "activity_states", "activities"
  add_foreign_key "activity_states", "states"
  add_foreign_key "decision_tables", "rules"
  add_foreign_key "dhis2_logs", "project_anchors"
  add_foreign_key "dhis2_snapshots", "project_anchors"
  add_foreign_key "entity_groups", "projects"
  add_foreign_key "formula_mappings", "activities"
  add_foreign_key "formula_mappings", "formulas"
  add_foreign_key "formulas", "rules"
  add_foreign_key "package_entity_groups", "packages"
  add_foreign_key "package_payment_rules", "packages"
  add_foreign_key "package_payment_rules", "payment_rules"
  add_foreign_key "package_states", "packages"
  add_foreign_key "package_states", "states"
  add_foreign_key "packages", "projects"
  add_foreign_key "payment_rules", "projects"
  add_foreign_key "project_anchors", "programs"
  add_foreign_key "projects", "project_anchors"
  add_foreign_key "projects", "projects", column: "original_id"
  add_foreign_key "rules", "packages"
  add_foreign_key "rules", "payment_rules"
  add_foreign_key "states", "projects"
  add_foreign_key "users", "programs"
  add_foreign_key "versions", "programs"
  add_foreign_key "versions", "projects"
end
