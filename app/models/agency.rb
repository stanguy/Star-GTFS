class Agency < ActiveRecord::Base
  acts_as_url :city, :url_attribute => :slug
  
  has_many :lines
  has_many :stops
  has_many :info_collectors

  def to_param
    slug
  end

  def centerize
#    self.bbox = MultiPoint.from_points( MultiPoint.from_points( self.stops.where("geom IS NOT NULL").collect(&:geom), 4326 ).bounding_box.map { |p| p.srid = 4326; p }, 4326 )
    self.center = self.stops.where("geom IS NOT NULL").select( "AsText(ST_Centroid(ST_Collect(geom::geometry))) AS center" )[0].center
  end

  def centerize!
    self.centerize
    self.save
  end
      
  def db_slug
    slug.gsub "-", "" 
  end
      

end
