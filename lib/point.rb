# -*- coding: utf-8 -*-
class Numeric
  def toRad
    self * Math::PI / 180
  end
      
end
    


class Point
  attr_reader :lat, :lon
  def initialize( lat, lon )
    @lat = lat
    @lon = lon
  end
  # Vincenty Inverse Solution of Geodesics on the Ellipsoid (c) Chris Veness
  def dist( rpoint )
    a = 6378137
    b = 6356752.3142
    f = 1 / 298.257223563 

    l = ( rpoint.lon - self.lon ).toRad();
    u1 = Math.atan( ( 1 - f ) * Math.tan( self.lat.toRad() ) );
    u2 = Math.atan( ( 1 - f ) * Math.tan( rpoint.lat.toRad() ) );
    sinU1 = Math.sin( u1 )
    cosU1 = Math.cos( u1 )
    sinU2 = Math.sin( u2 )
    cosU2 = Math.cos( u2 )

    lambda_v = l
    lambdaP = nil
    iterLimit = 100
    cosSqAlpha = nil
    sinSigma = cos2SigmaM = cosSigma = sigma = nil
    loop do
      sinLambda = Math.sin( lambda_v)
      cosLambda = Math.cos( lambda_v)
      sinSigma = Math.sqrt( ( cosU2 * sinLambda ) * ( cosU2 * sinLambda ) + ( cosU1 * sinU2 - sinU1 * cosU2 * cosLambda ) * ( cosU1 * sinU2 - sinU1 * cosU2 * cosLambda ) );
      if sinSigma == 0 
        return 0 # co-incident points
      end
      cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
      sigma = Math.atan2( sinSigma, cosSigma );
      sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
      cosSqAlpha = 1 - sinAlpha * sinAlpha;
      cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha;
      if  cos2SigmaM.nan?
        cos2SigmaM = 0 # equatorial line: cosSqAlpha=0 (Â§6)
      end
      c = f / 16 * cosSqAlpha * ( 4 + f * ( 4 - 3 * cosSqAlpha ) )
      lambdaP = lambda_v;
      lambda_v = l + ( 1 - c ) * f * sinAlpha * ( sigma + c * sinSigma * ( cos2SigmaM + c * cosSigma * ( -1 + 2 * cos2SigmaM * cos2SigmaM ) ) )
      break if ( ( lambda_v- lambdaP ).abs > 1e-12 && --iterLimit > 0 )
    end
    
    if( iterLimit == 0 )
      return nil # NaN; # formula failed to converge
    end
    uSq = cosSqAlpha * ( a * a - b * b ) / ( b * b );
    ga = 1 + uSq / 16384 * ( 4096 + uSq * ( -768 + uSq * ( 320 - 175 * uSq ) ) );
    gb = uSq / 1024 * ( 256 + uSq * ( -128 + uSq * ( 74 - 47 * uSq ) ) );
    deltaSigma = gb * sinSigma * ( cos2SigmaM + gb / 4 * ( cosSigma * ( -1 + 2 * cos2SigmaM * cos2SigmaM ) - gb / 6 * cos2SigmaM * ( -3 + 4 * sinSigma * sinSigma ) * ( -3 + 4 * cos2SigmaM * cos2SigmaM ) ) );
    s = b * ga * ( sigma - deltaSigma );

#    s = s.toFixed( 3 ); # round to 1mm precision
    s = (s * 1000).floor / 1000.0
    return s;
  end
end
