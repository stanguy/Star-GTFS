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
        var url = $('#info select').data('stop-url');
        var line_id =  $('#info select').val();
        var stop_id = this.stop_id;
        current_marker = this;
        $.get( url, { line: line_id, stop: stop_id }, onStopGet );
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