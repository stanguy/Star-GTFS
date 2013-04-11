# -*- coding: utf-8 -*-
class Numeric
  def toRad
    self * Math::PI / 180
  end
  def toDeg
    self * 180 / Math::PI;
  end
end
    


module GTFSPoint
  def self.bearing lpoint, rpoint
    lat1 = lpoint.lat.toRad();
    lat2 = rpoint.lat.toRad();
    lon1 = lpoint.lon;
    lon2 = rpoint.lon;

    dLat = (lat2-lat1).toRad();
    dLon = (lon2-lon1).toRad(); 
    y = Math.sin(dLon) * Math.cos(lat2);
    x = Math.cos(lat1)*Math.sin(lat2) -
        Math.sin(lat1)*Math.cos(lat2)*Math.cos(dLon);
    return nil if x == y
    brng = Math.atan2(y, x).toDeg();
    return brng;
  end
end
