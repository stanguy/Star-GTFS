class Agency < ActiveRecord::Base
  acts_as_url :city, :url_attribute => :slug
  
  has_many :lines
  has_many :stops
  has_many :info_collectors

  def to_param
    slug
  end

  def centerize
    self.bbox = MultiPoint.from_points( MultiPoint.from_points( Stop.where("geom IS NOT NULL AND agency_id = ?", self.id ).collect(&:geom), 4326 ).bounding_box.map { |p| p.srid = 4326; p }, 4326 )
    self.center = Geometry.from_ewkt( Stop.connection.select_one( "SELECT AsText(ST_Centroid(ST_Collect(geom))) AS center FROM stops WHERE geom IS NOT NULL AND agency_id = #{self.id}" )["center"] )
    self.center.srid = 4326
  end

  def centerize!
    self.centerize
    self.save
  end
      
      

end
