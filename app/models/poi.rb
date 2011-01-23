module POI
  def self.included(base)
    base.class_eval do  
      scope :close_to, lambda { |point,distance|
        where( "ST_DWithin(transform( geom, 900913 ), transform( ST_GeomFromText('POINT(? ?)', ?), 900913), ?)",
               point.x, point.y, 4326, distance )
      }
    end
  end
end
