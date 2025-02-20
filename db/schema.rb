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

ActiveRecord::Schema[8.0].define(version: 2025_02_20_095318) do
  create_table "campaigns", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "customer_id", null: false, comment: "for different customers"
    t.string "title", limit: 40, null: false
    t.column "currency", "enum('USD','TWD')", null: false
    t.decimal "budget", precision: 65, scale: 2, null: false
    t.string "advertiser_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
