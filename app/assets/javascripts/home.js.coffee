
selected_marker = null

linesInfo = {
        baseUrl: '',
        icons: {}
}

class Singleton
  @get: -> @instance ?= new @

class InfoWindow extends Singleton
    setMap: (map) ->
        @map = map
        @div = $('<div></div>')
        @div.attr 'id', 'infowindow'
        $(document.body).append @div
        @map.controls[google.maps.ControlPosition.RIGHT_CENTER].push @div[0]
    setContent: (content) ->
        @div.empty()
        @div.append content

class Marker
    deselect: ->
        @marker.setIcon this.determineIcon()
    onClick: ->
        if selected_marker != null
            selected_marker.deselect()
        @marker.setIcon this.determineIcon true
        selected_marker = this
        content = $("<div></div>").append(
            $("<h2></h2>").append( @name )
        ).addClass( 'time_display' );
        for trip in @times
            content.append( $("<h3></h3>")
                            .append( $('<span></span>' ).addClass( "bearing ui-icon ui-icon-arrow-1-" + trip.bearing.toLowerCase() ) )
                            .append( trip.direction ) );
            ul = $("<ul></ul>");
            for time in trip.times
                t_link = $('<a href="javascript:false;"></a>').append( time.t )
                    .data('id', time.tid )
                    .addClass('t')
#                    .click( onLineStopTimeFollowup );
                ul.append(
                    $("<li></li>").append( t_link )
                )
            hellip = $('<a>&hellip;</a>' ).attr('href', trip.schedule_url ).attr('title',"Horaires complets").addClass('dir_schedule');
            ul.append( $('<li></li>').append(hellip) );
            content.append( $('<div></div>').addClass('clear') );
            content.append( ul )
                   .append( $('<div></div>').addClass('clear') );
        content.append( $('<div></div>').addClass('clear'));
        if @others
            content.append( $('<h2>Autres lignes</h2>') );
            ul = $('<ul></ul>').addClass("lines");
            for line in @others
                li = $('<li></li>' )
                a = $('<a></a>').attr('href', '/line/' + line + '/at/' + @stop_id )
                a.bind 'click', { line: name, stop: @stop_id }, => this.onOtherLineSelect()
#                var marker = this;
#                a.bind( 'click', { line: name, stop: this.stop_id }, onOtherLineSelect );
                if linesInfo.icons[line]
                    a.append( $('<img>').attr( 'src', linesInfo.icons[line] ) )
                    a.attr('title', line )
                else
                    a.text( line )
                li.append( a );
                ul.append( li );
            content.append( ul );
        content.append( $('<span></span>').addClass('clear') );
        InfoWindow.get().setContent content

    setMap: ( map ) ->
        @marker.setMap( map )
    determineIcon: ( hl= false )->
        if @others != undefined && @others.length > 0
            icon_type = "bus"
        else
            icon_type = "point";
        if @accessible
            icon_type = icon_type + '_access';
        if hl
            basemap = $.dthg.Assets.icons.hl
        else
            basemap = $.dthg.Assets.icons
        if @times != undefined && @times.length > 0
            icon = basemap[icon_type].green;
        else
            icon = basemap[icon_type].red;
        icon

    constructor: (map, point) ->
        @name = point.name
        @stop_id = point.id;
        @times = point.times;
        @schedule_url = point.schedule_url;
        @others = point.others;
        @accessible = point.accessible
        @map = map
        myLatLng = new google.maps.LatLng( point.lat, point.lon )
        icon = this.determineIcon()
        if point.trip_time != undefined
            @marker = new MarkerWithLabel( {
                position: myLatLng,
                map: @map,
                title: point.name,
                icon: icon,
                labelContent: point.trip_time,
                labelAnchor: new google.maps.Point(19, 0),
                labelClass: "timeLabel"
            });
        else
            @marker = new google.maps.Marker( {
                position: myLatLng,
                map: @map,
                title: point.name,
                icon: icon
            })
        google.maps.event.addListener @marker, 'click', => this.onClick()

class MapBus
    constructor: ->
        @markers = []
        @alerts = {}
        @selected_stop_id = null
        $("button").button()
        $("button.alert").button("disable")
        @map = new google.maps.Map($('#map')[0], {
                'scrollwheel': ! $('#disable_scrollwheel:checked').val(),
                'zoom': 12,
                'center': new google.maps.LatLng( 48.11, -1.63 ),
                'mapTypeId': google.maps.MapTypeId.ROADMAP
                zoomControlOptions: {
                    style: google.maps.ZoomControlStyle.SMALL
                },
                panControl: false
        })
        @map.controls[google.maps.ControlPosition.TOP_LEFT].push $('#navigator')[0]
        InfoWindow.get().setMap @map
        $('#lines .list a').click (e) => this.onSelectLine(e)
        $('#lines').tabs({event: 'mouseover',disabled:[5]}).css('visibility','visible');
        $(elem).attr( 'title': $(elem).children('span').text() ) for elem in $('#lines .list a')

    onSelectLine: (e) ->
        e.preventDefault()
        selected_item = $(e.delegateTarget)
        $('#lines .list li.selected').removeClass('selected');
        selected_item.closest('li').addClass('selected');
        line_url = selected_item.attr 'href'
        $.get( line_url , {},
            (d,s,x) => this.onLineGet(d,s,x),
            "json" )
        short = selected_item.data('short')
        $("button.alert").button("enable") if @alerts[short]
        return false
    onLineGet: (d,s,x) ->
        marker.setMap( null ) for marker in @markers
        bounds = null
        selected_marker = null
        @markers = for point in d
            new Marker( @map, point )


loadLines= ->
        for element in $('#lines .list a')
            name = $(element).data('short');
            img = $(element).children('img');
            if ( img.length > 0 )
                linesInfo.icons[name] = img.attr('src');


$.dthg = $.dthg || {}
$.dthg.Bus = {
        init: ->
            loadLines()
            new MapBus()
    }

