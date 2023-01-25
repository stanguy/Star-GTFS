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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20130410194933) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "fuzzystrmatch"
  enable_extension "postgis"

  create_table "agencies", force: :cascade do |t|
    t.string    "name",        limit: 255
    t.string    "url",         limit: 255
    t.string    "tz",          limit: 255
    t.string    "phone",       limit: 255
    t.string    "lang",        limit: 255
    t.string    "city",        limit: 255
    t.boolean   "ads_allowed"
    t.datetime  "created_at",                                                                 null: false
    t.datetime  "updated_at",                                                                 null: false
    t.string    "slug",        limit: 255
    t.string    "publisher",   limit: 255
    t.string    "feed_url",    limit: 255
    t.string    "feed_ref",    limit: 255
    t.geography "center",      limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.geography "bbox",        limit: {:srid=>4326, :type=>"multi_point", :geographic=>true}
  end

  create_table "bike_stations", force: :cascade do |t|
    t.integer   "number"
    t.string    "name",       limit: 255
    t.string    "address",    limit: 255
    t.float     "lat"
    t.float     "lon"
    t.boolean   "pos"
    t.datetime  "created_at",                                                             null: false
    t.datetime  "updated_at",                                                             null: false
    t.geography "geom",       limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
  end

  create_table "calendar_dates", force: :cascade do |t|
    t.integer "calendar_id"
    t.date    "exception_date"
    t.boolean "exclusion"
  end

  create_table "calendars", force: :cascade do |t|
    t.string  "src_id",     limit: 255
    t.integer "days"
    t.date    "start_date"
    t.date    "end_date"
  end

  create_table "cities", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "headsigns", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "line_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "slug",       limit: 255
  end

  create_table "incidents", force: :cascade do |t|
    t.integer  "info_collector_id"
    t.string   "source_ref",        limit: 255
    t.datetime "since"
    t.datetime "expiration"
    t.string   "title",             limit: 255
    t.text     "detail"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "incidents_lines", id: false, force: :cascade do |t|
    t.integer "incident_id"
    t.integer "line_id"
  end

  create_table "info_collectors", force: :cascade do |t|
    t.string   "type",           limit: 255
    t.datetime "last_called_at"
    t.text     "params"
    t.integer  "agency_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "lines", force: :cascade do |t|
    t.string    "src_id",          limit: 255
    t.string    "short_name",      limit: 255
    t.string    "long_name",       limit: 255
    t.string    "bgcolor",         limit: 255
    t.string    "fgcolor",         limit: 255
    t.datetime  "created_at",                                                                                  null: false
    t.datetime  "updated_at",                                                                                  null: false
    t.string    "usage",           limit: 255
    t.string    "picto_url",       limit: 255
    t.string    "short_long_name", limit: 255
    t.string    "slug",            limit: 255
    t.boolean   "accessible"
    t.string    "old_src_id",      limit: 255
    t.integer   "agency_id"
    t.boolean   "hidden",                                                                      default: false
    t.geography "center",          limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
  end

  add_index "lines", ["agency_id"], name: "index_lines_on_agency_id", using: :btree

  create_table "lines_stops", id: false, force: :cascade do |t|
    t.integer "line_id"
    t.integer "stop_id"
  end

  create_table "metro_stations", force: :cascade do |t|
    t.string    "src_id",     limit: 255
    t.string    "name",       limit: 255
    t.string    "address",    limit: 255
    t.float     "lat"
    t.float     "lon"
    t.datetime  "created_at",                                                             null: false
    t.datetime  "updated_at",                                                             null: false
    t.geography "geom",       limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
  end

  create_table "polylines", force: :cascade do |t|
    t.integer  "line_id"
    t.text     "path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pos", force: :cascade do |t|
    t.string    "name",       limit: 255
    t.string    "type",       limit: 255
    t.text      "address"
    t.string    "zipcode",    limit: 255
    t.string    "city",       limit: 255
    t.string    "schedule",   limit: 255
    t.float     "lat"
    t.float     "lon"
    t.datetime  "created_at",                                                             null: false
    t.datetime  "updated_at",                                                             null: false
    t.geography "geom",       limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
  end

  create_table "stop_aliases", force: :cascade do |t|
    t.integer   "stop_id"
    t.string    "src_id",      limit: 255
    t.string    "src_code",    limit: 255
    t.string    "src_name",    limit: 255
    t.float     "src_lat"
    t.float     "src_lon"
    t.datetime  "created_at",                                                              null: false
    t.datetime  "updated_at",                                                              null: false
    t.boolean   "accessible"
    t.string    "description", limit: 255
    t.string    "old_src_id",  limit: 255
    t.geography "geom",        limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
  end

  create_table "stop_times", id: false, force: :cascade do |t|
    t.integer "stop_id"
    t.integer "line_id"
    t.integer "trip_id"
    t.integer "headsign_id"
    t.integer "arrival"
    t.integer "departure"
    t.integer "stop_sequence"
    t.integer "calendar_id"
  end

  create_table "stops", force: :cascade do |t|
    t.string    "name",           limit: 255
    t.float     "lat"
    t.float     "lon"
    t.datetime  "created_at",                                                                 null: false
    t.datetime  "updated_at",                                                                 null: false
    t.integer   "city_id"
    t.string    "line_ids_cache", limit: 255
    t.string    "slug",           limit: 255
    t.boolean   "accessible"
    t.integer   "agency_id"
    t.geography "geom",           limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
  end

  create_table "trips", force: :cascade do |t|
    t.integer  "line_id"
    t.integer  "src_id"
    t.string   "src_route_id", limit: 255
    t.integer  "headsign_id"
    t.integer  "block_id"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "bearing",      limit: 255
    t.integer  "calendar_id"
  end

end
