// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

jQuery.Star = {};

(function($) {
    var map;
    var markers = [];
    var infowindow = null;
    var current_marker = null;
    var default_colorbox_opts = { width: '40%', maxHeight: '80%' };

    var greenIcon = "http://www.google.com/intl/en_us/mapfiles/ms/micons/green-dot.png";
    var redIcon = "http://www.google.com/intl/en_us/mapfiles/ms/micons/red-dot.png";

    function onStopGet( d, s, x ) {
        
    }
    function onMarkerClick() {
        if ( null == infowindow ) {
            infowindow = new google.maps.InfoWindow();
        } else {
            infowindow.close();
        }
        if ( this.times === undefined || this.times.length == 0 ) {
            $.colorbox($.extend({href: this.schedule_url,
                onComplete: function() {
                    $('div.headsign:first').show();
                    $.colorbox.resize(default_colorbox_opts);
                }}, default_colorbox_opts));
            return;
        }
        var content = $("<div></div>").append(
            $("<h2></h2>").append(this.getTitle())
        ).addClass( 'time_display');
        for( var i = 0; i < this.times.length; ++i ) {
            content.append( $("<h3></h3>").append( this.times[i].direction ) );
            var ul = $("<ul></ul>");
            for( var j = 0; j < this.times[i].times.length; ++j ) {
                ul.append( $("<li></li>").append( this.times[i].times[j] ) );              
            }
            content.append( $('<div></div>').addClass('clear'));
            content.append( ul ).append( 
                $("<a></a>").addClass("dir_schedule").attr('href',this.times[i].schedule_url).text("Horaires complets") 
            );
        }
        content.append( $('<div></div>').addClass('clear'));
        infowindow.setContent( content[0] );
        infowindow.open( map, this );
    }
    function onLineGet( d, s, x) {
        $.each( d, function( idx, point ) {
            var myLatlng = new google.maps.LatLng( point.lat, point.lon );
            var icon;
            if( point.times != undefined && point.times.length > 0 ) {
                icon = greenIcon;
            } else {
                icon = redIcon;
            }
            var marker = new google.maps.Marker( {
                position: myLatlng,
                map: map,
                title: point.name,
                icon: icon
            });
            marker.stop_id = point.id;
            marker.times = point.times;
            marker.schedule_url = point.schedule_url;
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
    function onHeadingChange() {
        $('.headsign:visible').hide();
        $('#heading_' + $('#heading').val() ).show();
        $.colorbox.resize(default_colorbox_opts);
    }
    function onStopDirScheduleClick(e) {
        e.preventDefault();
        if ( null != infowindow ) {
            infowindow.close();
        }
        $.colorbox($.extend({href: $(this).attr('href'),
                onComplete: function() {
                    $('div.headsign:first').show();
                    $.colorbox.resize(default_colorbox_opts);
                }}, default_colorbox_opts));

    }
    $.Star.init= function() {
        $('#ajax-loader').ajaxSend(function(){
            $(this).show();
        });
        $('#heading').live( 'change', onHeadingChange );
        $('a.dir_schedule').live( 'click', onStopDirScheduleClick );
        $('#ajax-loader').ajaxComplete(function(){
            $(this).hide();
        });
        map = new google.maps.Map($('#map')[0], {
            'scrollwheel': false,
            'zoom': 13,
            'center': new google.maps.LatLng( 48.11, -1.63 ),
            'mapTypeId': google.maps.MapTypeId.ROADMAP
        });
        $('#info select').change(onSelectLine);
        if ( $('#info select').val() != '' ) {
            $('#info select').change();
        }
    };
})(jQuery);