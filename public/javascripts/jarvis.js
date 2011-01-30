
/* 
 * The following is some kind of implementation of Jarvis march algorithm.
 * It is used to compute the outer hull of a set of points.
 * 
 * We start from the lowest point and we try to find the rightmost point
 * (that is, the smallest angle between the last hull segment and the line 
 * formed with the point we test). We halt when we have reached the
 * first point.
 * 
 * Some of the code was mishandled here and originates from:
 *
 * Latitude/longitude spherical geodesy formulae & scripts (c) Chris Veness 2002-2010
 *   - www.movable-type.co.uk/scripts/latlong.html
 *           
 */

var jarvis = {
        
    bearing: function( p1, p2 ) {
        var lat1 = p1.y.toRad();
        var lat2 = p2.y.toRad();
        var lon1 = p1.x;
        var lon2 = p2.x;
        
        var dLat = (lat2-lat1).toRad();
        var dLon = (lon2-lon1).toRad(); 
        var y = Math.sin(dLon) * Math.cos(lat2);
        var x = Math.cos(lat1)*Math.sin(lat2) -
                Math.sin(lat1)*Math.cos(lat2)*Math.cos(dLon);
        var brng = Math.atan2(y, x).toDeg();
        return brng;
    },
        
    min_element: function( list_of_points ) {
        if( list_of_points.length == 1 ) {
            return 0;
        }
        var selected_idx = 0;
        var l = list_of_points.length;
        for( var i = 1; i < l; i++ ){
            if( list_of_points[selected_idx].y > list_of_points[i].y
                || ( list_of_points[selected_idx].y == list_of_points[i].y 
                        && list_of_points[selected_idx].x > list_of_points[i].x ) ) {
                selected_idx = i;
            }
        }
        return selected_idx;
    },
    jarvis_angle: function( p1, p2 ) {
        var bearing = jarvis.bearing( p1, p2 );
        var my_angle = bearing - 90;
        if( my_angle > 0 ) {
            my_angle = 360 - my_angle;
        }
        return Math.abs( my_angle );
    },
    walk: function( list_of_points ) {
        var start_idx = jarvis.min_element( list_of_points );
        var P = []; // sorted list of points on hull
        var P_bool = []; // "is a point on hull"
        var i ;
        for( i = 0; i < list_of_points.length; ++i ) {
            P_bool[i] = false;
        }
        var current_point = start_idx;
        //console.log( " initial point is " + list_of_points[start_idx].x + " x " + list_of_points[start_idx].y );
        var previous_angle = 0;
        do {
            P_bool[current_point] = true;
            P.push( current_point );
            var angle = 360;
            var real_angle = 360;
            var next_point = null; 
            for( var j = 0; j < list_of_points.length; ++j ) {
                //console.log( "inner loop" );
                if( j != current_point && ( j == P[0] || ! P_bool[j] ) ) {
                    //console.log( current_point + " / " + j );
                    var tested_line_angle = jarvis.jarvis_angle(
                        list_of_points[current_point],
                        list_of_points[j]
                    );
                    var tested_angle = tested_line_angle - previous_angle;
                    if( tested_angle < 0 ) {
                        tested_angle = 360 - tested_angle;
                    }
                    if( tested_angle < angle && j != P[P.length-1]) {
                        //console.log( "ang: " + tested_angle + " (" + tested_line_angle + ") " + j + " " + P[P.length-1]);
                        next_point = j;
                        angle = tested_angle;
                        real_angle = tested_line_angle;
                    }                    
                }
            }
            if( P.length > list_of_points.length ) {
                console.error( "failed to compute");
                console.log( list_of_points );
                console.log( "Current polygon is " );
                console.log( P );
                return null;
            }
            previous_angle = real_angle;
            current_point = next_point;
        } while( next_point != null && current_point != P[0]);
        return P;
    }
};

/** Convert numeric degrees to radians */
if (typeof(String.prototype.toRad) === "undefined") {
  Number.prototype.toRad = function() {
    return this * Math.PI / 180;
  };
}

/** Convert radians to numeric (signed) degrees */
if (typeof(String.prototype.toDeg) === "undefined") {
  Number.prototype.toDeg = function() {
    return this * 180 / Math.PI;
  };
}
