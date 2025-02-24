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

ActiveRecord::Schema[8.0].define(version: 2025_02_24_090148) do
  create_table "advertisers", charset: "utf8mb3", force: :cascade do |t|
    t.integer "customer_id"
    t.integer "platform_id"
    t.string "platform_advertiser_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "platform_id", "platform_advertiser_id"], name: "idx_on_customer_id_platform_id_platform_advertiser__e6c2ee718c", unique: true
  end

  create_table "agents_tables", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "campaigns", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "customer_id", null: false, comment: "for different customers"
    t.integer "platform_id"
    t.string "platform_campaign_id"
    t.string "title", null: false
    t.string "currency", null: false
    t.decimal "budget_cents", precision: 65, scale: 2, null: false
    t.string "advertiser_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false

    t.index ["title"], name: "index_campaigns_on_title"
    t.index ["budget_cents"], name: "index_campaigns_on_budget_cents"
    t.index ["currency"], name: "index_campaigns_on_currency"
    t.index ["advertiser_id"], name: "index_campaigns_on_advertiser_id"
    t.index ["created_at"], name: "index_campaigns_on_created_at"
    t.index ["customer_id", "platform_id", "platform_campaign_id"], name: "idx_on_customer_id_platform_id_platform_campaign_id_0009bccddc", unique: true
  end

  create_table "platforms", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
