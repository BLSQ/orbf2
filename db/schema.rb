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

ActiveRecord::Schema.define(version: 20170116121718) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "entity_groups", force: :cascade do |t|
    t.string   "name"
    t.string   "external_reference"
    t.integer  "project_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["project_id"], name: "index_entity_groups_on_project_id", using: :btree
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["package_id", "state_id"], name: "index_package_states_on_package_id_and_state_id", unique: true, using: :btree
    t.index ["package_id"], name: "index_package_states_on_package_id", using: :btree
    t.index ["state_id", "package_id"], name: "index_package_states_on_state_id_and_package_id", unique: true, using: :btree
    t.index ["state_id"], name: "index_package_states_on_state_id", using: :btree
  end

  create_table "packages", force: :cascade do |t|
    t.string   "name",                       null: false
    t.string   "data_element_group_ext_ref", null: false
    t.string   "frequency",                  null: false
    t.integer  "project_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["project_id"], name: "index_packages_on_project_id", using: :btree
  end

  create_table "payment_rules", force: :cascade do |t|
    t.integer  "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["project_anchor_id"], name: "index_projects_on_project_anchor_id", using: :btree
  end

  create_table "rules", force: :cascade do |t|
    t.string   "name",            null: false
    t.string   "kind",            null: false
    t.integer  "package_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "payment_rule_id"
    t.index ["package_id"], name: "index_rules_on_package_id", using: :btree
    t.index ["payment_rule_id"], name: "index_rules_on_payment_rule_id", using: :btree
  end

  create_table "states", force: :cascade do |t|
    t.string   "name",                              null: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.boolean  "configurable", default: false,      null: false
    t.string   "level",        default: "activity", null: false
    t.index ["name"], name: "index_states_on_name", unique: true, using: :btree
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

  add_foreign_key "entity_groups", "projects"
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
  add_foreign_key "rules", "packages"
  add_foreign_key "rules", "payment_rules"
  add_foreign_key "users", "programs"
end
