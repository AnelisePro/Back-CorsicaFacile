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

ActiveRecord::Schema[7.1].define(version: 2025_08_05_092803) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "role", default: "admin"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
  end

  create_table "artisan_expertises", force: :cascade do |t|
    t.bigint "artisan_id", null: false
    t.bigint "expertise_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artisan_id"], name: "index_artisan_expertises_on_artisan_id"
    t.index ["expertise_id"], name: "index_artisan_expertises_on_expertise_id"
  end

  create_table "artisans", force: :cascade do |t|
    t.string "company_name"
    t.string "address"
    t.string "siren"
    t.string "phone"
    t.boolean "verified", default: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "membership_plan"
    t.string "authentication_token"
    t.text "description"
    t.string "kbis_url"
    t.string "insurance_url"
    t.datetime "subscription_started_at"
    t.string "avatar_url"
    t.datetime "banned_at"
    t.integer "banned_by"
    t.integer "monthly_response_count", default: 0
    t.datetime "last_response_reset_at"
    t.index ["email"], name: "index_artisans_on_email", unique: true
    t.index ["reset_password_token"], name: "index_artisans_on_reset_password_token", unique: true
    t.index ["siren"], name: "index_artisans_on_siren", unique: true
  end

  create_table "availability_slots", force: :cascade do |t|
    t.bigint "artisan_id", null: false
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artisan_id"], name: "index_availability_slots_on_artisan_id"
  end

  create_table "besoins", force: :cascade do |t|
    t.string "type_prestation"
    t.text "description"
    t.text "schedule"
    t.string "address"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "image_urls", default: []
    t.index ["client_id"], name: "index_besoins_on_client_id"
  end

  create_table "client_notifications", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "artisan_id", null: false
    t.bigint "besoin_id", null: false
    t.string "message", null: false
    t.string "link"
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artisan_id"], name: "index_client_notifications_on_artisan_id"
    t.index ["besoin_id"], name: "index_client_notifications_on_besoin_id"
    t.index ["client_id"], name: "index_client_notifications_on_client_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.date "birthdate"
    t.string "phone"
    t.boolean "verified", default: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar_url"
    t.datetime "banned_at"
    t.integer "banned_by"
    t.index ["email"], name: "index_clients_on_email", unique: true
    t.index ["reset_password_token"], name: "index_clients_on_reset_password_token", unique: true
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "artisan_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false
    t.index ["artisan_id"], name: "index_conversations_on_artisan_id"
    t.index ["client_id", "artisan_id"], name: "index_conversations_on_client_id_and_artisan_id", unique: true
    t.index ["client_id"], name: "index_conversations_on_client_id"
  end

  create_table "expertises", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_expertises_on_name", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.text "content", null: false
    t.bigint "conversation_id", null: false
    t.string "sender_type", null: false
    t.bigint "sender_id", null: false
    t.string "recipient_type", null: false
    t.bigint "recipient_id", null: false
    t.boolean "read", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["recipient_type", "recipient_id"], name: "index_messages_on_recipient"
    t.index ["recipient_type", "recipient_id"], name: "index_messages_on_recipient_type_and_recipient_id"
    t.index ["sender_type", "sender_id"], name: "index_messages_on_sender"
    t.index ["sender_type", "sender_id"], name: "index_messages_on_sender_type_and_sender_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "artisan_id", null: false
    t.string "message"
    t.string "link"
    t.boolean "read"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "besoin_id"
    t.string "status"
    t.index ["artisan_id"], name: "index_notifications_on_artisan_id"
    t.index ["besoin_id"], name: "index_notifications_on_besoin_id"
  end

  create_table "project_images", force: :cascade do |t|
    t.bigint "artisan_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artisan_id"], name: "index_project_images_on_artisan_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "artisan_id", null: false
    t.bigint "client_notification_id", null: false
    t.integer "rating", null: false
    t.text "comment", null: false
    t.boolean "intervention_successful"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artisan_id"], name: "index_reviews_on_artisan_id"
    t.index ["client_id", "artisan_id", "client_notification_id"], name: "index_reviews_unique_per_mission", unique: true
    t.index ["client_id"], name: "index_reviews_on_client_id"
    t.index ["client_notification_id"], name: "index_reviews_on_client_notification_id"
  end

  create_table "site_statistics", force: :cascade do |t|
    t.date "date", null: false
    t.integer "page_views", default: 0
    t.integer "unique_visitors", default: 0
    t.integer "client_signups", default: 0
    t.integer "artisan_signups", default: 0
    t.integer "client_logins", default: 0
    t.integer "artisan_logins", default: 0
    t.integer "messages_sent", default: 0
    t.integer "announcements_posted", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_site_statistics_on_date", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "artisan_expertises", "artisans"
  add_foreign_key "artisan_expertises", "expertises"
  add_foreign_key "availability_slots", "artisans"
  add_foreign_key "besoins", "clients"
  add_foreign_key "client_notifications", "artisans"
  add_foreign_key "client_notifications", "besoins"
  add_foreign_key "client_notifications", "clients"
  add_foreign_key "conversations", "artisans"
  add_foreign_key "conversations", "clients"
  add_foreign_key "messages", "conversations"
  add_foreign_key "notifications", "artisans"
  add_foreign_key "notifications", "besoins"
  add_foreign_key "project_images", "artisans"
  add_foreign_key "reviews", "artisans"
  add_foreign_key "reviews", "client_notifications"
  add_foreign_key "reviews", "clients"
end
