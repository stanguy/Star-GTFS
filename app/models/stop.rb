class Stop < ActiveRecord::Base

  acts_as_url :name, :url_attribute => :slug

  include POI

  has_many :stop_aliases
  has_and_belongs_to_many :lines
  has_many :stop_times
  belongs_to :city
  belongs_to :agency

  def to_point
    Point.from_lon_lat( lon, lat, 4326 )
  end

  def to_param
    slug
  end
      
end
