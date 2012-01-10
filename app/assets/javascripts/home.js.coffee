#= require fancybox

History = window.history

selectedMarker = null
currentLineUrl = null
mapBus = null
initialLoadingSentinel = false;

linesInfo = {
        baseUrl: '',
        icons: {}
}

class Singleton
  @get: -> @instance ?= new @

class InfoWindow extends Singleton
    setMap: (map) ->
        @map = map
        @container_div = $('<div></div>')
        @container_div.attr 'id', 'infowindow'
        $(document.body).append @container_div
        @map.controls[google.maps.ControlPosition.RIGHT_CENTER].push @container_div[0]
    setContent: (content) ->
        @container_div.empty()
        @container_div.append content

class Marker
    deselect: ->
        @marker.setIcon this.determineIcon()
    onClick: ->
        if selectedMarker?
            selectedMarker.deselect()
        if ( ! @times? ) || @times.length == 0
            mapBus.loadSchedule @schedule_url
            return
        @marker.setIcon this.determineIcon true
        selectedMarker = this
        content = $("<div></div>").append(
            $("<h2></h2>").append( @name )
        ).addClass( 'time_display' );
        for trip in @times
            content.append( $("<h3></h3>")
                            .append( $('<span></span>' ).addClass( "bearing ui-icon ui-icon-arrow-1-" + trip.bearing.toLowerCase() ) )
                            .append( trip.direction ) );
            ul = $("<ul></ul>");
            for time in trip.times
                t_link = $('<a></a>').append( time.t )
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
        if @others? and @others.length > 0
            content.append( $('<h2>Autres lignes</h2>') );
            ul = $('<ul></ul>').addClass("lines");
            for line in @others
                li = $('<li></li>' )
                a = $('<a></a>').attr('href', '/line/' + line + '/at/' + @stop_id )
#                a.bind 'click', { line: name, stop: @stop_id }, => this.onOtherLineSelect()
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
        unless initialLoadingSentinel
            History.pushState( { lineUrl: currentLineUrl, stop: @stop_id }, '',
                               currentLineUrl + '/at/' + @stop_id )

    setMap: ( map ) ->
        @marker.setMap( map )
    determineIcon: ( hl= false )->
        if @others? && @others.length > 0
            icon_type = "bus"
        else
            icon_type = "point";
        if @accessible
            icon_type = icon_type + '_access';
        if hl
            basemap = $.dthg.Assets.icons.hl
        else
            basemap = $.dthg.Assets.icons
        if @times? && @times.length > 0
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
        if point.trip_time
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
        if selectedMarker? and selectedMarker.stop_id == @stop_id
            this.onClick()
        google.maps.event.addListener @marker, 'click', => this.onClick()

class MapBus
    constructor: ->
        @markers = []
        @lines = []
        @alerts = {}
        $("button").button()
        $("button.alert").button("disable")
        $("button.help").click => this.onHelp()
        $("#navigator h1").click => this.onAbout()
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
        $('#lines').tabs({event: 'mouseover'}).css('visibility','visible');
        $(elem).attr( 'title': $(elem).children('span').text() ) for elem in $('#lines .list a')
        $('#navigator').show()
        $('body').on 'click', ".time_display a.t", (e) => this.onFollowupLine(e)
        $('body').on 'click', 'a.dir_schedule, .schedule_container .other_lines a', (e) => this.onStopDirScheduleClick(e)
        $('body').on 'click', '.time_display .lines a', (e) =>
            e.preventDefault()
            $('#lines .list li a[data-short="' + $(e.currentTarget).attr('title') + '"]').click()
            false
        if $('#line_data')
            this.loadLineData()
        window.onpopstate = (e) => this.historyCallback(e)
    onHelp: ->
        $.fancybox({
            autoDimensions: false
            width: 990
            height: '90%'
            type: 'inline'
            href: "#help"
        })
    onAbout: ->
        $.fancybox({
            type: 'inline'
            href: "#about"
        })
    onFollowupLine: (e) ->
        e.preventDefault()
        url = $('#lines .list li.selected a').attr('href');
        $.get( url, { trip_id: $(e.target).data('id') },
                (d,s,x) => this.onLineGet( d,s,x ),
                "json" )
        false
    onStopDirScheduleClick: (e) ->
        e.preventDefault()
        url = $(e.currentTarget).attr( 'href' )
        this.loadSchedule url
    loadSchedule: (url) ->
        if History.state['scheduleUrl']?
            History.replaceState( { scheduleUrl: url }, '', url )
        else
            History.pushState( { scheduleUrl: url }, '', url );
        $.fancybox({
            autoDimensions: false
            width: 990
            height: '90%'
            type: 'ajax'
            href: url
            onComplete: -> $('.accordion').accordion()
            onClosed: -> History.back()
        })
        false
    historyCallback: (e) ->
        if e.state
            if e.state.lineUrl
                $.fancybox.close()
                if( e.state.lineUrl != currentLineUrl )
                    $('a[href="' + e.state.lineUrl + '"]').click()
            else if e.state.scheduleUrl
                this.loadSchedule e.state.scheduleUrl
    onSelectLine: (e) ->
        e.preventDefault()
        currentLineUrl = $(e.delegateTarget).attr('href');
        selected_item = $(e.delegateTarget)
        $('#lines .list li.selected').removeClass('selected');
        selected_item.closest('li').addClass('selected');
        line_url = selected_item.attr 'href'
        History.pushState( { lineUrl: line_url }, null, line_url );
        $.get( line_url , {},
            (d,s,x) => this.onLineGet(d,s,x),
            "json" )
        short = selected_item.data('short')
        $("button.alert").button("enable") if @alerts[short]
        return false
    onLineGet: (d,s,x) ->
        marker.setMap( null ) for marker in @markers
        line.setMap( null ) for line in @lines
        bounds = null
        @markers = for point in d.stops
            new Marker( @map, point )
        @lines = for line in d.paths
            new google.maps.Polyline({
                map: @map,
                path: google.maps.geometry.encoding.decodePath( line ),
                strokeColor: '#' + d.colors.bg,
                clickable: false
            })
    loadLineData: ->
        line_data = []
        currentLineUrl = $('#line_data').data('line-url')
        for child in $('#line_data').children('li')
            stop = $(child).find('h2 a')
            if ( stop.data('selected') )
                selected_stop_id = stop.data('id')
                initialLoadingSentinel = true
            others = stop.data('others') + ''
            if ( others != '' )
                others = others.split(',')
            else
                others = []
            times = [];
            for subchild in $(child).children('div')
                direction = $(subchild).find('h3 a')
                stop_times = [];
                for subsubchild in $(subchild).children('span')
                    stop_times.push({ t: $(subsubchild).text(), tid: $(subsubchild).data('tid')});
                times.push({
                        direction: direction.text(),
                        bearing: direction.data('bearing'),
                        schedule_url: direction.attr('href'),
                        times: stop_times
                    })
            line_data.push({
                name: stop.text(),
                id: stop.data('id'),
                lat: stop.data('lat'),
                lon: stop.data('lon'),
                schedule_url: stop.attr('href'),
                others: others,
                accessible: stop.data('accessible'),
                times: times
            })
        state = {
            lineUrl: currentLineUrl
        }
        if ( selected_stop_id != undefined )
            $.merge( state, { stop: selected_stop_id } );
        History.replaceState( state, '', currentLineUrl );
        this.onLineGet( {
            stops: line_data
            paths: []
        })


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
            mapBus = new MapBus()
    }

