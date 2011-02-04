// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

if ( undefined == jQuery.Star ) {
    jQuery.Star = {};    
}
jQuery.Star.Bus = {};
jQuery.Star.Bikes = {};
jQuery.SHistory = {};

(function($){
    var browsing_history = [];
    if ( "replaceState" in window.history  && window.history.replaceState !== null && ! $.browser.safari ) {
        $.SHistory.goBack = function () {
            if ( browsing_history.length > 0 ) {
                window.history.replaceState( null, '', browsing_history.pop() );
            }
        };
        $.SHistory.goTo = function ( url ) {
            if ( window.location.pathname != '/' ) {
                browsing_history.push( window.location.pathname );          
            }
            window.history.replaceState( null, '', url );
        };
        $.SHistory.lastUrl= function () {
            return window.location.pathname;
        };
    } else {
        $.SHistory.goBack = function () {
            if ( browsing_history.length > 0 ) {
                window.location.hash = browsing_history.pop();
            }
        };
        $.SHistory.goTo = function ( url ) {
            if ( window.location.hash != '' ) {
                browsing_history.push( window.location.hash );          
            }
            window.location.hash = url;
        };
        $.SHistory.lastUrl= function () {
            if ( window.location.hash != '' ){
                return  window.location.hash;
            } else {
                return window.location.pathname;
            }
        };
    }
    $.SHistory.canGoBack= function () {
        return browsing_history.length > 0;
    };
    
})(jQuery);




(function($) {
    var map;
    var maptimizeController = null;
    var markers = [];
    var infowindow = null;
    var current_marker = null;
    var selected_stop_id = null;
    var issues = {};
    var ANIM_DELAY = 350;

    var initial_loading_sentinel = false;

    var icons = {
        bus: {
            green: "/images/bus_green.png",
            red: "/images/bus_red.png",
            orange: "/images/bus_orange.png",
            blue: "/images/bus_blue.png"
        },
        bus_access: {
            green: "/images/bus_green_access.png",
            red: "/images/bus_red_access.png",
            orange: "/images/bus_orange_access.png",
            blue: "/images/bus_blue.png"
        },
        point: {
            green: "/images/point_green.png",
            red: "/images/point_red.png",
            orange: "/images/point_orange.png"          
        },
        point_access: {
            green: "/images/point_green_access.png",
            red: "/images/point_red_access.png",
            orange: "/images/point_orange_access.png"          
        }
    };
    var linesInfo = {
        baseUrl: '',
        icons: {}
    };
    
    function onScheduleGet(d,s,x) {
        var sched_container = $(d);
        sched_container.hide();
        $('#map_browser').after( sched_container );
        $('#map_browser').hide( 'slide', { direction: 'left' }, ANIM_DELAY );
        sched_container.show('slide', {direction:'right'}, ANIM_DELAY );
        $('.accordion').accordion();
    }
    function fetchSchedule( url ) {
        $.get( url, onScheduleGet, "html" );
    }
    function onCloseInfoWindow() {
        selected_stop_id = null;
        $.SHistory.goBack();
    }
    function onOtherLineSelect( e ) {
        e.preventDefault();
        infowindow.close();
        selected_stop_id = e.data.stop;
        $('#lines .list li a[data-short="' + e.data.line + '"]').click();
    }
    function onLineStopTimeFollowup( e ) {
        var url = $('#lines .list li.selected a').attr('href');
        $.get( url, { trip_id: $(this).data('id') }, onLineGet, "json" );
    }
    function onLineMarkerClick() {
        if ( null == infowindow ) {
            infowindow = new google.maps.InfoWindow();
            google.maps.event.addListener( infowindow, 'closeclick', onCloseInfoWindow );
        } else {
            infowindow.close();
        }
        if ( this.times === undefined || this.times.length == 0 ) {
            $.SHistory.goTo( this.schedule_url );
            fetchSchedule( this.schedule_url );
            return;
        }
        var content = $("<div></div>").append(
            $("<h2></h2>").append(this.getTitle())
        ).addClass( 'time_display');
        for( var i = 0; i < this.times.length; ++i ) {
            content.append( $("<h3></h3>")
                            .append( $('<span></span>' ).addClass( "bearing ui-icon ui-icon-arrow-1-" + this.times[i].bearing.toLowerCase() ) )
                            .append( this.times[i].direction ) );
            var ul = $("<ul></ul>");
            for( var j = 0; j < this.times[i].times.length; ++j ) {
                ul.append( 
                    $("<li></li>").append( this.times[i].times[j].t )
                                  .append( $('<span> &rarr;</span>').data('id',this.times[i].times[j].tid ).click( onLineStopTimeFollowup ) )   
                );
            }
            var hellip = $('<a>&hellip;</a>' ).attr('href', this.times[i].schedule_url ).attr('title',"Horaires complets").addClass('dir_schedule');
            ul.append( $('<li></li>').append(hellip) );
            content.append( $('<div></div>').addClass('clear') );
            content.append( ul )
                   .append( $('<div></div>').addClass('clear') );
        }
        content.append( $('<div></div>').addClass('clear'));
        if ( this.others.length > 0 ) {
            content.append( $('<h2>Autres lignes</h2>') );
            var ul = $('<ul></ul>').addClass("lines");
            for( var x = 0; x < this.others.length; ++x ) {
                var name = this.others[x];
                var li = $('<li></li>' );
                var a = $('<a></a>').attr('href', '/line/' + name + '/at/' + this.stop_id );
                var marker = this;
                a.bind( 'click', { line: name, stop: this.stop_id }, onOtherLineSelect );
                if ( linesInfo.icons[name] != undefined ) {
                    a.append( $('<img>').attr( 'src', linesInfo.icons[name] ) );
                    a.attr('title', name );
                } else {
                    a.text( name );
                }
                li.append( a );
                ul.append( li );
            }
            content.append( ul );
        }
        content.append( $('<div>x</div>').addClass('clear') );
        infowindow.setContent( content[0] );
        if( ! initial_loading_sentinel ) {
            if( $.SHistory.lastUrl().match( /\/at\// ) ) {
                $.SHistory.goBack();
            }
            $.SHistory.goTo( $.SHistory.lastUrl() + '/at/' + this.stop_id );       
        }
        infowindow.open( map, this );
    }
    function onLineGet( d, s, x) {
        $.each( markers, function( idx, marker ) {
            marker.setMap( null );
        });
        markers = [];
        
        var bounds = null;
        var selected_marker = null;
        $.each( d, function( idx, point ) {
            var myLatlng = new google.maps.LatLng( point.lat, point.lon );
            var icon;
            var icon_type = ( point.others != undefined && point.others.length > 0 ) ? "bus" : "point";
            if ( point.accessible ) {
                icon_type = icon_type + '_access';
            }
            if( point.times != undefined && point.times.length > 0 ) {
                icon = icons[icon_type].green;
            } else {
                icon = icons[icon_type].red;
            }
            var marker ;
            if ( point.trip_time == undefined ) {
                marker = new google.maps.Marker( {
                    position: myLatlng,
                    map: map,
                    title: point.name,
                    icon: icon
                });
            } else {
                marker = new MarkerWithLabel( {
                    position: myLatlng,
                    map: map,
                    title: point.name,
                    icon: icon,
                    labelContent: point.trip_time,
                    labelAnchor: new google.maps.Point(19, 0),
                    labelClass: "timeLabel"
                });
            }   
            if ( bounds == undefined ) {
                bounds = new google.maps.LatLngBounds( myLatlng, myLatlng );
            } else if ( ! bounds.contains( myLatlng ) ) {
                bounds.extend( myLatlng );
            }
            marker.stop_id = point.id;
            marker.times = point.times;
            marker.schedule_url = point.schedule_url;
            marker.others = point.others;
            markers.push( marker );
            google.maps.event.addListener( marker, 'click', onLineMarkerClick );
            if ( selected_stop_id != undefined && point.id == selected_stop_id ) {
                selected_marker = marker;
            }
        });
        if ( map.getBounds() != undefined && ! map.getBounds().intersects( bounds ) ) {
            map.panToBounds( bounds );
        }
        if ( selected_marker != null ) {
            google.maps.event.trigger( selected_marker, 'click' );
        }
    }
    function displayIssues() {
        var short_id = $('#lineactions select option:selected').text().split(' ', 1 );
        var issues_display = $('<div></div>');
        var converter = new Showdown.converter();
        if ( issues[short_id] == undefined ) {
            return;
        }
        for( var i = 0; i < issues[short_id].length; ++i ) {
            issues_display.append( $('<h3></h3>').text( issues[short_id][i].title ) )
                    .append( converter.makeHtml( issues[short_id][i].body ) );
        }
        $(issues_display).dialog({ title: 'Erreurs sur la ligne ' + short_id });
    }
    function onSelectLine(e) {
        e.preventDefault();
        var url = $(this).attr('href');
        $('#lines .list li.selected').removeClass('selected');
        $(this).closest('li').addClass('selected');
        $.SHistory.goTo( url );
        $.get( url, {}, onLineGet, "json" );
        var short_id = $(this).data('short');
        if( issues[short_id] != undefined ) {
            $('.icons img').first().show();
            $('.icons img').first().attr('title', issues[short_id][0].title );
        } else {
            $('.icons img').first().hide();
        }
    }
    function onHeadingChange() {
        $('.headsign:visible').hide();
        $('#heading_' + $('#heading').val() ).show();
    }
    function onStopDirScheduleClick(e) {
        e.preventDefault();
        $.SHistory.goTo( $(this).attr('href') );
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
    $.Star.Bus.MaptiTheme = {
      createMarker: function(marker) {
        return new google.maps.Marker({ position: marker.getGLatLng(), icon: icons.bus.blue });
      },
 
      createCluster: function(cluster) {
        var count = cluster.getPointsCount(),
            index = parseInt(Math.log(count) / Math.log(10)),
            options;
        options = $.Star.Bus.MaptiTheme._getClusterOptions();
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
        $.SHistory.goTo( url );
        fetchSchedule( url );
    }
    function onFindStops(e) {
        if ( $('#find_stops:checked').val() ) {
            if ( e != null ) {
                $.SHistory.goTo( '/stops' );
            }
            // TODO: disable switching tabs
            $('#lines').tabs({ selected: 4 }).tabs("option","disabled",[0,1,2,3,5]);
            $.each( markers, function( idx, marker ) {
                marker.setMap( null );
            });
            markers = [];
            if( maptimizeController != null ) {
                maptimizeController.activate();
            } else {
                maptimizeController = new com.maptimize.MapController(map,{theme: $.Star.Bus.MaptiTheme,onMarkerClicked: onMaptiMarkerClick});
                maptimizeController.setGroupingDistance(80);
                maptimizeController.setClusterMinSize(3);
                maptimizeController.refresh();
            }
        } else if ( maptimizeController != null ) {
            $.SHistory.goBack();
            $('#lines').tabs("option","disabled",[]);
            maptimizeController.deactivate();
        }
    }
    function onIssuesGet(d,h,x) {
        for( var i = 0; i < d.issues.length; ++i ) {
            if( d.issues[i].state == "closed" ) {
                continue;
            }
            var title_info = d.issues[i].title.split(':');
            var body = d.issues[i].body;
            var title = title_info[1];
            var lines = title_info[0].split(',');
            for( var j = 0; j < lines.length; ++j ) {
                if ( issues[lines[j]] == undefined ) {
                    issues[lines[j]] = [];
                }
                issues[lines[j]].push( { title: title, body: body } );
            }
            
        }
    }
    function loadIssues() {
        var url = 'http://github.com/api/v2/json/issues/list/stanguy/star-gtfs/label/datasource?callback=?';
        $.getJSON( url, onIssuesGet );
    }
    function loadLines() {
        $('#lines .list a').each(function(){
            var name = $(this).data('short');
            var img = $(this).children('img');
            if ( img.length > 0 ) {
                linesInfo.icons[name] = img.attr('src');
            }
        });
    }
    $.Star.Bus.initMap = function() {
        map = new google.maps.Map($('#map')[0], {
            'scrollwheel': false,
            'zoom': 12,
            'center': new google.maps.LatLng( 48.11, -1.63 ),
            'mapTypeId': google.maps.MapTypeId.ROADMAP
        });
        $.Star.map = map;
        $('#lines .list a').click(onSelectLine);
        if ( $('#line_data').length > 0 ) {
            var line_data = [];
            $('#line_data').children('li').each( function() {
                var stop = $(this).find('h2 a');
                if ( stop.data('selected') ) {
                    selected_stop_id = stop.data('id');
                    initial_loading_sentinel = true;
                }
                var others = stop.data('others') + '';
                if ( others !== '' ) {
                    others = others.split(',');
                } else {
                    others = [];
                }
                var times = [];
                $(this).children('div').each( function() {
                    var direction = $(this).find('h3 a');
                    var stop_times = [];
                    $(this).children('span').each( function() {
                        stop_times.push({ t: $(this).text(), tid: $(this).data('tid')});
                    });
                    times.push({
                        direction: direction.text(),
                        bearing: direction.data('bearing'),
                        schedule_url: direction.attr('href'),
                        times: stop_times
                    });
                });
                line_data.push({ name: stop.text(), 
                                   id: stop.data('id'), 
                                  lat: stop.data('lat'), 
                                  lon: stop.data('lon'),
                         schedule_url: stop.attr('href'),
                               others: others,
                            accessible: stop.data('accessible'),
                                times: times } );
            });
            onLineGet( line_data );
        }
        $('input#find_stops').change( onFindStops );        
        loadIssues();
    };
    function onBackToMapClick(e) {
        e.preventDefault();
        if( $.SHistory.canGoBack() ) {
            $.SHistory.goBack();
            $('div.schedule_container').hide('slide', {direction:'right'}, ANIM_DELAY, function(){$(this).remove(); });
            $('#map_browser').show( 'slide', { direction: 'left' }, ANIM_DELAY );
        } else {
            window.location = $(this).attr('href');
        }
    }
    $.Star.Bus.init= function() {

        if ( window.location.hash != '' && window.location.hash != null ) {
            window.location = window.location.hash.substr(1);
            return;
        }
        $('#lines').tabs({event: 'mouseover'}).css('visibility','visible');
        $('#lines .list a').each( function() {
          $(this).attr('title', $(this).children('span').text() );
        });

        $('#ajax-loader').ajaxSend(function(){
            $(this).show();
        });
        $('#ajax-loader').ajaxComplete(function(){
            $(this).hide();
        });
        $('.icons img').first().click( displayIssues );

        $('#heading').live( 'change', onHeadingChange );
        $('a.dir_schedule').live( 'click', onStopDirScheduleClick );
        $('a.back_to_map').live('click', onBackToMapClick );
        if( $('#map').length > 0 ) {
            $.Star.Bus.initMap();
        }
        if( $('#find_stops:checked').val() !== 'undefined' ) {
            onFindStops();
        }
        loadLines();
    };
})(jQuery);

(function($) {
    var markers = [];
    var areas = [];
    function onFindBikes(){
        if ( $('#find_bikes:checked').val() ) {
            var stations = $.veloStar.getStations( 'AO7UR4OL1ICTKWL' );
            var districts = $.veloStar.listDistricts( stations );
            var Colors = [ '#A4DBAC', '#8ED197', '#78C482', '#78C4A2', '#78C4AF', '#8BC1CC',
                           '#7AB8C4', '#88BEDB', '#88AFDB', '#888FDB', '#5E67CC', '#3742B3', '#3742B3'  ];
            var Images = [ 'cycling0.png', 'cycling33.png', 'cycling66.png', 'cycling100.png' ];
            var computeImage = function( station ) {
                var img_idx = Math.round( station.bikesavailable / ( station.bikesavailable + station.slotsavailable ) * ( Images.length - 1 ) );
                return '/images/' + Images[img_idx];
            };
            $.each( districts, function(k,v) {
                var nb_stations = 0;
                $.each( v, function() { nb_stations++; });
                if( nb_stations > 2 ) {
                    var points = $.map( v, function(p){ return { x: p.longitude, y: p.latitude }; }); 
                    var poly_slots = jarvis.walk( points );
                    var bikes = 0;
                    var slots = 0;
                    $.each( v, function( i, v ) { bikes += v.bikesavailable; slots += v.slotsavailable; } );
                    var color_idx = Math.round( bikes / ( bikes+slots )  * ( Colors.length - 1 ) );

                    var poly_coords = $.map( poly_slots, function(pidx) { 
                        return new google.maps.LatLng( v[pidx].latitude, v[pidx].longitude );
                    });
                    var area = new google.maps.Polygon({
                        paths: poly_coords,
                        strokeColor: "#000",
                        strokeOpacity: 0.8,
                        strokeWeight: 1,
                        fillColor: Colors[ color_idx ],
                        fillOpacity: 0.8
                    });
                    area.setMap( $.Star.map );
                    areas.push( area );

                    google.maps.event.addListener( area, 'click', function( evt ) {
                        area.setMap( null );
                        var bbox = $.veloStar.getBoundingBox( v );
                        var gbounds = new google.maps.LatLngBounds( 
                            new google.maps.LatLng( bbox[0].latitude, bbox[0].longitude ),
                            new google.maps.LatLng( bbox[1].latitude, bbox[1].longitude )
                        );
                        $.Star.map.fitBounds( gbounds );
                        $.merge( markers, $.veloStar.drawMarkersForStations( $.Star.map, v, computeImage ) );
                    });
                } else {
                    $.merge( markers, $.veloStar.drawMarkersForStations( $.Star.map, v, computeImage ) );
                }
            });
        } else {           
        $.each( markers, function( idx, marker ) {
            marker.setMap( null );
        });
        markers = [];
        $.each( areas, function( idx, area ) {
            area.setMap( null );
        });
        areas = [];
            
        }
    }
    $.Star.Bikes.init = function() {
        $('input#find_bikes').change( onFindBikes );
    };
})(jQuery);
