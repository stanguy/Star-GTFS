module POI
  def self.included(base)
    base.class_eval do  
      scope :close_to, lambda { |point,distance|
        select( "*,postgis.st_distance( Transform( geom::geometry, 900913 ), transform( ST_GeomFromText('POINT(#{point.x} #{point.y})', 4326), 900913)) as distance").
        where( "postgis.ST_DWithin(transform( geom::geometry, 900913 ), transform( ST_GeomFromText('POINT(? ?)', ?), 900913), ?)",
               point.x, point.y, 4326, distance ).order( "distance ASC" )
      }
    end
  end
end
