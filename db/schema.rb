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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110101092025) do

  create_table "cities", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "headsigns", :force => true do |t|
    t.string   "name"
    t.integer  "line_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lines", :force => true do |t|
    t.string   "src_id"
    t.string   "short_name"
    t.string   "long_name"
    t.string   "bgcolor"
    t.string   "fgcolor"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "usage"
  end

  create_table "lines_stops", :id => false, :force => true do |t|
    t.integer "line_id"
    t.integer "stop_id"
  end

  create_table "stop_aliases", :force => true do |t|
    t.integer  "stop_id"
    t.string   "src_id"
    t.string   "src_code"
    t.string   "src_name"
    t.float    "src_lat"
    t.float    "src_lon"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stop_times", :force => true do |t|
    t.integer  "stop_id"
    t.integer  "line_id"
    t.integer  "trip_id"
    t.integer  "headsign_id"
    t.integer  "arrival"
    t.integer  "departure"
    t.integer  "calendar"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

## Schema is used before import, thus index will be added "later"
#  add_index "stop_times", ["line_id", "calendar", "arrival"], :name => "index_stop_times_on_line_id_and_calendar_and_arrival"
#  add_index "stop_times", ["trip_id"], :name => "index_stop_times_on_trip_id"

  create_table "stops", :force => true do |t|
    t.string   "name"
    t.float    "lat"
    t.float    "lon"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "city_id"
    t.string   "line_ids_cache"
  end

  create_table "trips", :force => true do |t|
    t.integer  "line_id"
    t.integer  "src_id"
    t.integer  "calendar"
    t.string   "src_route_id"
    t.integer  "headsign_id"
    t.integer  "block_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "bearing"
  end

end
