// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

jQuery.Star = {};

(function($) {
    var map;
    var markers = [];
    var current_marker = null;
    function onStopGet( d, s, x ) {
        
    }
    function onMarkerClick() {
        console.log("hello");
        var directions = {};
        for( var i = 0 ; i < this.times.length; ++i ) {
            if ( directions[this.times[i].direction] === undefined ) {
                directions[this.times[i].direction] = [];
            }
            directions[this.times[i].direction].push( this.times[i].time );
        }
        var content = $("<div></div>").append(
            $("<h2></h2>").append(this.getTitle())
        );
        $.each( directions, function( d, times ){
            content.append( $("<h3></h3>").append( d ) );
            var ul = $("<ul></ul>");
            for( var i =0 ; i < times.length; ++i ) {
                ul.append( $("<li></li>").append( times[i] ) );
            }
            content.append( ul );
        });
        var infow = new google.maps.InfoWindow({
            content: content[0]
        });
        infow.open( map, this );
    }
    function onLineGet( d, s, x) {
        $.each( d, function( idx, point ) {
            var myLatlng = new google.maps.LatLng( point.lat, point.lon );
            var marker = new google.maps.Marker( {
                position: myLatlng,
                map: map,
                title: point.name
            });
            marker.stop_id = point.id;
            marker.times = point.times;
            markers.push( marker );
            google.maps.event.addListener( marker, 'click', onMarkerClick );
        });
    }
    function onSelectLine() {
        $.each( markers, function( idx, marker ) {
            marker.setMap( null );
        });
        markers = [];
        var url = $('#info select').data('line-url');
        $.get( url, { id: $(this).val() }, onLineGet, "json" );
    }
    $.Star.init= function() {
        map = new google.maps.Map($('#map')[0], {
            'zoom': 13,
            'center': new google.maps.LatLng( 48.11, -1.63 ),
            'mapTypeId': google.maps.MapTypeId.ROADMAP
        });
        $('#info select').change(onSelectLine);
    };
})(jQuery);