jQuery.veloStar = {
    getStations: function( key ) {
        if( undefined == key ) {
            return null;
        }
        var API_BASE_URL = 'http://data.keolis-rennes.com/json/';
        var params = {
            version: '1.0',
            key: key,
            cmd: 'getstation'
        };
        var data;
        jQuery.ajax( {
            url: API_BASE_URL,
            data: params,
            async: false,
            success: function( response ) {
                data = response;
            }
        } );
        if( undefined != data
                && undefined != data.opendata
                && undefined != data.opendata.answer
                && undefined != data.opendata.answer.status
                && undefined != data.opendata.answer.status[ "@attributes" ]
                && undefined != data.opendata.answer.status[ "@attributes" ].code
                && 0 == data.opendata.answer.status[ "@attributes" ].code ) {
            jQuery.each( data.opendata.answer.data.station, function( idx, v ) {
                v.latitude = parseFloat( v.latitude );
                v.longitude = parseFloat( v.longitude );
                v.bikesavailable = parseInt( v.bikesavailable );
                v.slotsavailable = parseInt( v.slotsavailable );
            } );
        }
        return data;
    },
    listDistricts: function( data ) {
        if( undefined == data
                || undefined == data.opendata
                || undefined == data.opendata.answer
                || undefined == data.opendata.answer.status
                || undefined == data.opendata.answer.status[ "@attributes" ]
                || undefined == data.opendata.answer.status[ "@attributes" ].code
                || 0 != data.opendata.answer.status[ "@attributes" ].code ) {
            return null;
        }
        var districts = {};
        $.each( data.opendata.answer.data.station, function( idx, v ) {
            if( undefined == districts[ v.district ] ) {
                districts[ v.district ] = [];
            }
            districts[ v.district ].push( v );
        } );
        return districts;
    },
    getBoundingBox: function( list_of_points ) {
        if( ( !jQuery.isArray( list_of_points ) )
                || ( 0 == list_of_points.length ) ) {
            return null;
        }
        var latitudes = jQuery.map( list_of_points, function( x ) {
            return x.latitude;
        } ).sort( function( a, b ) {
            return a - b;
        } );
        var longitudes = jQuery.map( list_of_points, function( x ) {
            return x.longitude;
        } ).sort( function( a, b ) {
            return a - b;
        } );
        var tr = {
            latitude: latitudes[ latitudes.length - 1 ],
            longitude: longitudes[ longitudes.length - 1 ]
        };
        var bl = {
            latitude: latitudes[ 0 ],
            longitude: longitudes[ 0 ]
        };
        return [ bl, tr ];
    },
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
    /*
     * Vincenty Inverse Solution of Geodesics on the Ellipsoid (c) Chris Veness
     * 2002-2010
     */
    /*                                                                                                */
    /*
     * from: Vincenty inverse formula - T Vincenty, "Direct and Inverse
     * Solutions of Geodesics on the
     */
    /*
     * Ellipsoid with application of nested equations", Survey Review, vol XXII
     * no 176, 1975
     */
    /* http://www.ngs.noaa.gov/PUBS_LIB/inverse.pdf */
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

    /**
     * Calculates geodetic distance between two points specified by
     * latitude/longitude using Vincenty inverse formula for ellipsoids
     * 
     * @param {Number}
     *                lat1, lon1: first point in decimal degrees
     * @param {Number}
     *                lat2, lon2: second point in decimal degrees
     * @returns (Number} distance in metres between points
     */
    distVincenty: function( lat1, lon1, lat2, lon2 ) {
        var a = 6378137, b = 6356752.3142, f = 1 / 298.257223563; // WGS-84
        // ellipsoid
        // params
        var L = ( lon2 - lon1 ).toRad();
        var U1 = Math.atan( ( 1 - f ) * Math.tan( lat1.toRad() ) );
        var U2 = Math.atan( ( 1 - f ) * Math.tan( lat2.toRad() ) );
        var sinU1 = Math.sin( U1 ), cosU1 = Math.cos( U1 );
        var sinU2 = Math.sin( U2 ), cosU2 = Math.cos( U2 );

        var lambda = L, lambdaP, iterLimit = 100;
        do {
            var sinLambda = Math.sin( lambda ), cosLambda = Math.cos( lambda );
            var sinSigma = Math.sqrt( ( cosU2 * sinLambda )
                    * ( cosU2 * sinLambda )
                    + ( cosU1 * sinU2 - sinU1 * cosU2 * cosLambda )
                    * ( cosU1 * sinU2 - sinU1 * cosU2 * cosLambda ) );
            if( sinSigma == 0 )
                return 0; // co-incident points
            var cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
            var sigma = Math.atan2( sinSigma, cosSigma );
            var sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
            var cosSqAlpha = 1 - sinAlpha * sinAlpha;
            var cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha;
            if( isNaN( cos2SigmaM ) )
                cos2SigmaM = 0; // equatorial line: cosSqAlpha=0 (§6)
            var C = f / 16 * cosSqAlpha * ( 4 + f * ( 4 - 3 * cosSqAlpha ) );
            lambdaP = lambda;
            lambda = L
                    + ( 1 - C )
                    * f
                    * sinAlpha
                    * ( sigma + C
                            * sinSigma
                            * ( cos2SigmaM + C * cosSigma
                                    * ( -1 + 2 * cos2SigmaM * cos2SigmaM ) ) );
        } while( Math.abs( lambda - lambdaP ) > 1e-12 && --iterLimit > 0 );

        if( iterLimit == 0 )
            return NaN; // formula failed to converge

        var uSq = cosSqAlpha * ( a * a - b * b ) / ( b * b );
        var A = 1 + uSq / 16384
                * ( 4096 + uSq * ( -768 + uSq * ( 320 - 175 * uSq ) ) );
        var B = uSq / 1024 * ( 256 + uSq * ( -128 + uSq * ( 74 - 47 * uSq ) ) );
        var deltaSigma = B
                * sinSigma
                * ( cos2SigmaM + B
                        / 4
                        * ( cosSigma * ( -1 + 2 * cos2SigmaM * cos2SigmaM ) - B
                                / 6 * cos2SigmaM
                                * ( -3 + 4 * sinSigma * sinSigma )
                                * ( -3 + 4 * cos2SigmaM * cos2SigmaM ) ) );
        var s = b * A * ( sigma - deltaSigma );

        s = s.toFixed( 3 ); // round to 1mm precision
        return s;
    },

    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

    drawCircleFromBoudingBox: function( map, bl, tr, opts ) {
        var center = {
            latitude: ( bl.latitude + tr.latitude ) / 2,
            longitude: ( bl.longitude + tr.longitude ) / 2
        };
        var radius = Math.round( jQuery.veloStar.distVincenty( center.latitude,
                center.longitude, bl.latitude, bl.longitude ) );

        var center_on_map = new google.maps.LatLng( center.latitude,
                center.longitude );

        var circle_options = {
            map: map,
            'radius': radius,
            fillColor: '#FF0000',
            strikeColor: '#FF0000',
            center: center_on_map,
            title: opts.title
        };
        jQuery.extend( circle_options, opts );

        // Add a Circle overlay to the map
        var circle = new google.maps.Circle( circle_options );

        return circle;
    },
    drawMarkersForStations: function( map, stations, computeImage ) {
        if( null == computeImage ) {
            computeImage = function() {};
        }
        var markers = [];
        jQuery.each( stations, function( idx, station ) {
            var myLatlng = new google.maps.LatLng( station.latitude,
                    station.longitude );
            var myOptions = {
                zoom: 4,
                center: myLatlng,
                mapTypeId: google.maps.MapTypeId.ROADMAP
            };
            var image = computeImage( station );
            var marker = new google.maps.Marker( {
                position: myLatlng,
                map: map,
                title: station.name,
                icon: image
            });

            google.maps.event.addListener( marker, 'click', function() {
                var content = $('<div class="bike_display">' +
                '<h2>' + station.name + '</h2>' +
                '<p>Actuellement disponibles:</p>' +
                '<table><tr><th>Vélos</th><th>Emplacements</th></tr>' +
                '<tr><td>' + station.bikesavailable + '</td><td>' + station.slotsavailable +'</td></tr></table' +
                '</div>');
                var infow =  new google.maps.InfoWindow({
                    content: content[0]
                });
                infow.open( map, marker );
            });
            
            markers.push( marker );
        } );
        return markers;
    }

};

/** extend Number object with methods for converting degrees/radians */
Number.prototype.toRad = function() { // convert degrees to radians
    return this * Math.PI / 180;
};
