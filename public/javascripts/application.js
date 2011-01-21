// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

jQuery.Star = {};




(function($) {
    var map;
    var maptimizeController = null;
    var markers = [];
    var infowindow = null;
    var current_marker = null;
    var selected_stop_id = null;
    var issues = {};
    var ANIM_DELAY = 350;

    var browsing_history = [];
    var initial_loading_sentinel = false;

    var icons = {
        bus: {
            green: "/images/bus_green.png",
            red: "/images/bus_red.png",
            orange: "/images/bus_orange.png",
            blue: "/images/bus_blue.png"
        },
        point: {
            green: "/images/point_green.png",
            red: "/images/point_red.png",
            orange: "/images/point_orange.png"          
        }
    };
    var linesInfo = {
        baseUrl: '',
        icons: {}
    };
    
    function goBack() {
        if ( browsing_history.length > 0 ) {
            window.location.hash = browsing_history.pop();
        }
    }
    function goTo( url ) {
        if ( window.location.hash != '' ) {
            browsing_history.push( window.location.hash );          
        }
        window.location.hash = url;
    }
    function lastUrl() {
        if ( window.location.hash != '' ){
            return  window.location.hash;
        } else {
            return window.location.pathname;
        }
    }
    function canGoBack() {
        return browsing_history.length > 0;
    }

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
        goBack();
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
            goTo( this.schedule_url );
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
            ul.append( '<li>&hellip;</li>' );
            content.append( $('<div></div>').addClass('clear'));
            content.append( ul )
                   .append( $('<div></div>').addClass('clear') )
                   .append( 
                $("<a></a>").addClass("dir_schedule").attr('href',this.times[i].schedule_url).text("Horaires complets") 
            );
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
            if( lastUrl().match( /\/at\// ) ) {
                goBack();
            }
            goTo( lastUrl() + '/at/' + this.stop_id );       
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
        goTo( url );
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
        return new google.maps.Marker({ position: marker.getGLatLng(), icon: icons.bus.blue });
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
            // TODO: disable switching tabs
            $('#lines').tabs({ selected: 4 }).tabs("option","disabled",[0,1,2,3,5]);
            $.each( markers, function( idx, marker ) {
                marker.setMap( null );
            });
            markers = [];
            if( maptimizeController != null ) {
                maptimizeController.activate();
            } else {
                maptimizeController = new com.maptimize.MapController(map,{theme: $.Star.MaptiTheme,onMarkerClicked: onMaptiMarkerClick});
                maptimizeController.setGroupingDistance(80);
                maptimizeController.setClusterMinSize(3);
                maptimizeController.refresh();
            }
        } else if ( maptimizeController != null ) {
            goBack();
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
    $.Star.initMap = function() {
        map = new google.maps.Map($('#map')[0], {
            'scrollwheel': false,
            'zoom': 12,
            'center': new google.maps.LatLng( 48.11, -1.63 ),
            'mapTypeId': google.maps.MapTypeId.ROADMAP
        });            
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
                                times: times } );
            });
            onLineGet( line_data );
        }
        $('input#find_stops').change( onFindStops );        
        loadIssues();
    };
    function onBackToMapClick(e) {
        e.preventDefault();
        if( canGoBack() ) {
            goBack();
            $('div.schedule_container').hide('slide', {direction:'right'}, ANIM_DELAY, function(){$(this).remove(); });
            $('#map_browser').show( 'slide', { direction: 'left' }, ANIM_DELAY );
        } else {
            window.location = $(this).attr('href');
        }
    }
    $.Star.init= function() {

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
        $('.back_to_map').live('click', onBackToMapClick );
        if( $('#map').length > 0 ) {
            $.Star.initMap();
        }
        if( $('#find_stops:checked').val() !== 'undefined' ) {
            onFindStops();
        }
        loadLines();
    };
})(jQuery);