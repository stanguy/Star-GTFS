// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

jQuery.Star = {};




(function($) {
    var map;
    var maptimizeController = null;
    var markers = [];
    var infowindow = null;
    var current_marker = null;

    var browsing_history = [];

    var icons = {
        green: "/images/bus_green.png",
        red: "/images/bus_red.png",
        orange: "/images/bus_orange.png",
        blue: "/images/bus_blue.png"
    };

    
    function goBack() {
        if ( browsing_history.length > 0 ) {
            window.location.hash = browsing_history.pop();
        }
    }
    function goTo( url ) {
        browsing_history.push( window.location.hash );
        window.location.hash = url;
    }
    function canGoBack() {
        return browsing_history.length > 0;
    }

    function onScheduleGet(d,s,x) {
        var sched_container = $(d);
        sched_container.hide();
        $('#map_browser').after( sched_container );
        $('#map_browser').hide( 'slide', { direction: 'left' }, 500 );
        sched_container.show('slide', {direction:'right'}, 500);
    }
    function fetchSchedule( url ) {
        $.get( url, onScheduleGet, "html" );
    }
    function onLineMarkerClick() {
        if ( null == infowindow ) {
            infowindow = new google.maps.InfoWindow();
        } else {
            infowindow.close();
        }
        if ( this.times === undefined || this.times.length == 0 ) {
            goTo( this.schedule_url );
            fetchSchedule( this.schedule_url );
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
                icon = icons.green;
            } else {
                icon = icons.red;
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
            google.maps.event.addListener( marker, 'click', onLineMarkerClick );
        });
    }
    function onSelectLine() {
        $.each( markers, function( idx, marker ) {
            marker.setMap( null );
        });
        markers = [];
        if( $(this).val() != '' ) {
            var url = $('#lineactions select').data('line-url').replace( /0/, $(this).val() );
            goTo( url );
            $.get( url, {}, onLineGet, "json" );
        } else {
            goTo( '' );
        }
    }
    function onHeadingChange() {
        $('.headsign:visible').hide();
        $('#heading_' + $('#heading').val() ).show();
    }
    function onStopDirScheduleClick(e) {
        e.preventDefault();
        if ( null != infowindow ) {
            infowindow.close();
        }
        goTo( $(this).attr('href') );
        fetchSchedule( $(this).attr('href') );
    }
    function onStopsGet(d,x,s) {
        $.each( d, function( idx, point ) {
            var myLatlng = new google.maps.LatLng( point.lat, point.lon );
            var icon;
            var marker = new google.maps.Marker( {
                position: myLatlng,
                map: map,
                title: point.name
            });
            marker.stop_id = point.id;
            markers.push( marker );
        });
    }
    $.Star.MaptiTheme = {
      createMarker: function(marker) {
        return new google.maps.Marker({ position: marker.getGLatLng(), icon: icons.blue });
      },
 
      createCluster: function(cluster) {
        var count = cluster.getPointsCount(),
            index = parseInt(Math.log(count) / Math.log(10)),
            options;
        options = $.Star.MaptiTheme._getClusterOptions();
        options = options[Math.min(options.length - 1, index)];
        options.labelText = count;
        return new com.maptimize.LabeledMarker(cluster.getGLatLng(), options);
      },
 
      _getClusterOptions: function() {
        return this._clusterOptions = this._clusterOptions || [
          { icon:       { image:            "/images/quant1.png",
                          iconAnchor:       new google.maps.Point(30, 30) },
            labelClass: 'maptimize_cluster_0'},                     
          { icon:       { image:            "/images/quant2.png",
                          iconAnchor:       new google.maps.Point(30, 30) },
            labelClass: 'maptimize_cluster_0'},                     
          { icon:       { image:            "/images/quant3.png",
                          iconAnchor:       new google.maps.Point(30, 30) },
            labelClass: 'maptimize_cluster_0'}
          ];
      }  
    };
    function onMaptiMarkerClick(marker) {
        var url = '/schedule/at/' + marker.getId();
        goTo( url );
        fetchSchedule( url );
    }
    function onFindStops(e) {
        if ( $('#find_stops:checked').val() ) {
            if ( e != null ) {
                goTo( '/stops' );
            }
            $('#lineactions select').val('');
            $('#lineactions select').attr('disabled', true);
            $.each( markers, function( idx, marker ) {
                marker.setMap( null );
            });
            markers = [];
            if( maptimizeController != null ) {
                maptimizeController.activate();
            } else {
                maptimizeController = new com.maptimize.MapController(map,{theme: $.Star.MaptiTheme,onMarkerClicked: onMaptiMarkerClick});
                maptimizeController.setGroupingDistance(80);
                maptimizeController.setClusterMinSize(3)
                maptimizeController.refresh();
            }
        } else if ( maptimizeController != null ) {
            goBack();
            $('#lineactions select').removeAttr('disabled');
            maptimizeController.deactivate();
        }
    }
    $.Star.initMap = function() {
        map = new google.maps.Map($('#map')[0], {
            'scrollwheel': false,
            'zoom': 12,
            'center': new google.maps.LatLng( 48.11, -1.63 ),
            'mapTypeId': google.maps.MapTypeId.ROADMAP
        });            
        $('#lineactions select').change(onSelectLine);
        if ( typeof line_data !== 'undefined' ) {
            onLineGet( line_data );
        }
        $('#stopactions input').change( onFindStops );        
    };
    function onBackToMapClick(e) {
        e.preventDefault();
        if( canGoBack() ) {
            goBack();
            $('div.schedule_container').hide('slide', {direction:'right'}, 500, function(){$(this).remove(); });
            $('#map_browser').show( 'slide', { direction: 'left' }, 500 );
        } else {
            window.location = $(this).attr('href');
        }
    }
    $.Star.init= function() {

        if ( window.location.hash != '' && window.location.hash != null ) {
            window.location = window.location.hash.substr(1);
            return;
        }

        $('#ajax-loader').ajaxSend(function(){
            $(this).show();
        });
        $('#ajax-loader').ajaxComplete(function(){
            $(this).hide();
        });

        $('#heading').live( 'change', onHeadingChange );
        $('a.dir_schedule').live( 'click', onStopDirScheduleClick );
        $('.back_to_map').live('click', onBackToMapClick );
        if( $('#map').length > 0 ) {
            console.log("map");
            $.Star.initMap();
        }
        if( $('#find_stops:checked').val() !== 'undefined' ) {
            onFindStops();
        }
    };
})(jQuery);