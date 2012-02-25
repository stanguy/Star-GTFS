# encoding: UTF-8
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

ActiveRecord::Schema.define(:version => 20120225001112) do

  create_table "agencies", :force => true do |t|
    t.string      "name"
    t.string      "url"
    t.string      "tz"
    t.string      "phone"
    t.string      "lang"
    t.string      "city"
    t.boolean     "ads_allowed"
    t.datetime    "created_at",                 :null => false
    t.datetime    "updated_at",                 :null => false
    t.string      "slug"
    t.multi_point "bbox",        :limit => nil,                 :srid => 4326
    t.point       "center",      :limit => nil,                 :srid => 4326
    t.string      "publisher"
    t.string      "feed_url"
    t.string      "feed_ref"
  end

  create_table "bike_stations", :force => true do |t|
    t.integer  "number"
    t.string   "name"
    t.string   "address"
    t.float    "lat"
    t.float    "lon"
    t.boolean  "pos"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.point    "geom",       :limit => nil, :srid => 4326
  end

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
    t.string   "slug"
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
    t.string   "picto_url"
    t.string   "short_long_name"
    t.string   "slug"
    t.boolean  "accessible"
    t.string   "old_src_id"
    t.integer  "agency_id"
    t.point    "center",          :limit => nil, :srid => 4326
  end

  add_index "lines", ["agency_id"], :name => "index_lines_on_agency_id"
  add_index "lines", ["short_name"], :name => "index_lines_on_short_name"

  create_table "lines_stops", :id => false, :force => true do |t|
    t.integer "line_id"
    t.integer "stop_id"
  end

  create_table "metro_stations", :force => true do |t|
    t.string   "src_id"
    t.string   "name"
    t.string   "address"
    t.float    "lat"
    t.float    "lon"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.point    "geom",       :limit => nil, :srid => 4326
  end

  create_table "polylines", :force => true do |t|
    t.integer  "line_id"
    t.text     "path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pos", :force => true do |t|
    t.string   "name"
    t.string   "type"
    t.text     "address"
    t.string   "zipcode"
    t.string   "city"
    t.string   "schedule"
    t.float    "lat"
    t.float    "lon"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.point    "geom",       :limit => nil, :srid => 4326
  end

  create_table "quartiers", :force => true do |t|
    t.integer       "nuquart"
    t.string        "nmquart"
    t.string        "numnom"
    t.string        "nom"
    t.multi_polygon "the_geom", :limit => nil
  end

  add_index "quartiers", ["the_geom"], :name => "index_quartiers_on_the_geom", :spatial => true

  create_table "stop_aliases", :force => true do |t|
    t.integer  "stop_id"
    t.string   "src_id"
    t.string   "src_code"
    t.string   "src_name"
    t.float    "src_lat"
    t.float    "src_lon"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "accessible"
    t.string   "description"
    t.string   "old_src_id"
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
    t.integer  "stop_sequence"
  end

  add_index "stop_times", ["line_id", "calendar", "arrival"], :name => "index_stop_times_on_line_id_and_calendar_and_arrival"
  add_index "stop_times", ["trip_id"], :name => "index_stop_times_on_trip_id"

  create_table "stops", :force => true do |t|
    t.string   "name"
    t.float    "lat"
    t.float    "lon"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "city_id"
    t.string   "line_ids_cache"
    t.string   "slug"
    t.boolean  "accessible"
    t.integer  "agency_id"
    t.point    "geom",           :limit => nil, :srid => 4326
  end

  add_index "stops", ["slug"], :name => "index_stops_on_slug"

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
