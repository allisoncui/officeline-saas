# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_11_12_232213) do
  create_table "enrollments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "office_hour_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["office_hour_id"], name: "index_enrollments_on_office_hour_id"
    t.index ["user_id", "office_hour_id"], name: "index_enrollments_on_user_id_and_office_hour_id", unique: true
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "office_hours", force: :cascade do |t|
    t.string "course_name"
    t.string "instructor"
    t.string "day"
    t.string "start_time"
    t.string "end_time"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ta_uni"
    t.boolean "queue_active", default: false
    t.datetime "queue_started_at"
  end

  create_table "questions", force: :cascade do |t|
    t.integer "office_hour_id", null: false
    t.text "question_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["office_hour_id"], name: "index_questions_on_office_hour_id"
    t.index ["user_id"], name: "index_questions_on_user_id"
  end

  create_table "queue_entries", force: :cascade do |t|
    t.integer "office_hour_id", null: false
    t.integer "user_id", null: false
    t.integer "position"
    t.datetime "joined_at"
    t.string "status", default: "waiting"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["office_hour_id", "status"], name: "index_queue_entries_on_office_hour_id_and_status"
    t.index ["office_hour_id", "user_id"], name: "index_queue_entries_on_office_hour_id_and_user_id", unique: true
    t.index ["office_hour_id"], name: "index_queue_entries_on_office_hour_id"
    t.index ["user_id"], name: "index_queue_entries_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "uni", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "course_name"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uni"], name: "index_users_on_uni", unique: true
  end

  add_foreign_key "enrollments", "office_hours"
  add_foreign_key "enrollments", "users"
  add_foreign_key "questions", "office_hours"
  add_foreign_key "questions", "users"
  add_foreign_key "queue_entries", "office_hours"
  add_foreign_key "queue_entries", "users"
end
