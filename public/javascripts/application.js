// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

jQuery.Star = {};




(function($) {
    var map;
    var maptimizeController;
    var markers = [];
    var infowindow = null;
    var current_marker = null;
    var default_colorbox_opts = { width: '40%', maxHeight: '80%' };

    var icons = {
        green: "/images/bus_green.png",
        red: "/images/bus_red.png",
        orange: "/images/bus_orange.png",
        blue: "/images/bus_blue.png"
    };

    function onStopGet( d, s, x ) {
        
    }
    function onLineMarkerClick() {
        if ( null == infowindow ) {
            infowindow = new google.maps.InfoWindow();
        } else {
            infowindow.close();
        }
        if ( this.times === undefined || this.times.length == 0 ) {
            $.colorbox($.extend({href: this.schedule_url,
                title: this.getTitle(),
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
            var url = $('#lineactions select').data('line-url');
            $.get( url, { id: $(this).val() }, onLineGet, "json" );
        }
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
                title: $(this).closest('div').children('h2').text(),
                onComplete: function() {
                    $('div.headsign:first').show();
                    $.colorbox.resize(default_colorbox_opts);
                }}, default_colorbox_opts));

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
          { icon:       { image:            "/images/quant3.png",
                          iconAnchor:       new google.maps.Point(30, 30) },
            labelClass: 'maptimize_cluster_0'},                     
          { icon:       { image:            "/images/quant2.png",
                          iconAnchor:       new google.maps.Point(30, 30) },
            labelClass: 'maptimize_cluster_0'},                     
          { icon:       { image:            "/images/quant1.png",
                          iconAnchor:       new google.maps.Point(30, 30) },
            labelClass: 'maptimize_cluster_0'}
          ];
      }  
    };
    function onMaptiMarkerClick(marker) {
        $.colorbox($.extend({href: '/schedule/at/' + marker.getId(),
                onComplete: function() {
                    $('div.headsign:first').show();
                    $.colorbox.resize(default_colorbox_opts);
                }}, default_colorbox_opts));
    }
    function onFindStops(e) {
        if ( $('#find_stops:checked').val() ) {
            $.each( markers, function( idx, marker ) {
                marker.setMap( null );
            });
            markers = [];
            maptimizeController = new com.maptimize.MapController(map,{theme: $.Star.MaptiTheme,onMarkerClicked: onMaptiMarkerClick});
            maptimizeController.setGroupingDistance(80);
            maptimizeController.refresh();
            $('a.datasource').after( $('<a class="poweredby" href="http://www.maptimize.com">Powered by Maptimize!</a>') );
            $('a.poweredby').fadeIn();
            e.preventDefault();
        } else if ( maptimizeController != null ) {
            maptimizeController.deactivate();
            $.each( maptimizeController.getClusters(), function(i,m){
                m.getGMarker().setMap( null );
            });
            $.each( maptimizeController.getMarkers(), function(i,m){
                m.getGMarker().setMap( null );
            });
            maptimizeController = null;
            $('a.poweredby').fadeOut().remove();
        }
        /*var bounds = map.getBounds().toUrlValue();
        $.get( $(this).attr('href'), { bb: bounds }, onStopsGet, "json" );*/
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
            'zoom': 12,
            'center': new google.maps.LatLng( 48.11, -1.63 ),
            'mapTypeId': google.maps.MapTypeId.ROADMAP
        });
        $('#lineactions select').change(onSelectLine);
        if ( $('#lineactions select').val() != '' ) {
            $('#lineactions select').change();
        }
        $('#stopactions input').change( onFindStops );



    };
})(jQuery);