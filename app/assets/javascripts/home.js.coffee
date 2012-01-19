#= require fancybox
#= require hogan.js
#= require_tree ../templates

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
        @container_div.hide()
    setContent: (content) ->
        @container_div.empty()
        @container_div.append content
        this.setVisible true
    setVisible: (visible) ->
        if visible and not @container_div.is(':visible')
            @container_div.show()
        if @container_div.is(':visible') and not visible
            @container_div.hide()

class Marker
    deselect: ->
        InfoWindow.get().setVisible false
        @marker.setIcon this.determineIcon()
    onClick: ->
        if selectedMarker?
            selectedMarker.deselect()
            if selectedMarker == this
                selectedMarker = null
                return
        if this.select()
            History.pushState( {
                lineUrl: currentLineUrl
                stop: @stop_id
            }, '', currentLineUrl + '/at/' + @stop_id )
            window._gaq.push currentLineUrl + '/at/' + @stop_id
    select: ->
        if ( ! @times? ) || @times.length == 0
            selectedMarker = null
            mapBus.loadSchedule @schedule_url
            return false
        @marker.setIcon this.determineIcon true
        selectedMarker = this
        trip.bearing = trip.bearing.toLowerCase() for trip in @times
        others = false
        if @others?
            others = { others: for line in @others
                {
                line: line
                icon: linesInfo.icons[line]
                no_icon: !!! linesInfo.icons[line]
                }
            }
        InfoWindow.get().setContent HoganTemplates.stop.render {
            name: @name
            times: @times
            'others?': others
            stop_id: @stop_id
        }
        true

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
        if ( selectedMarker? and selectedMarker.stop_id == @stop_id ) || point.selected
            this.select()
        google.maps.event.addListener @marker, 'click', => this.onClick()

class MapBus
    constructor: ->
        @markers = []
        @lines = []
        @alerts = {}
        $("button.help").button( icons: { primary: 'ui-icon-help' }, text: false )
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

        adUnitDiv = document.createElement('div');
        adUnitOptions = {
            format: google.maps.adsense.AdFormat.HALF_BANNER
            position: google.maps.ControlPosition.BOTTOM_LEFT
            map: @map
            visible: true
            publisherId: 'pub-2211614128309725'
            channelNumber: '2322968658'
        }
        adUnit = new google.maps.adsense.AdUnit( adUnitDiv, adUnitOptions )
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
        @map.controls[google.maps.ControlPosition.TOP_RIGHT].push $('#ajax-loader')[0]
        $('#ajax-loader').ajaxSend( ->
            $(this).show();
        )
        $('#ajax-loader').ajaxComplete( ->
            $(this).hide();
        )

        if $('#line_data').length > 0
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
        if window.location.pathname.match /\/schedule\//
            History.replaceState( { scheduleUrl: url }, '', url )
            window._gaq.push url
        else
            History.pushState( { scheduleUrl: url }, '', url )
            window._gaq.push url
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
        window._gaq.push line_url
        $.get( line_url , {},
            (d,s,x) => this.onLineGet(d,s,x),
            "json" )
        short = selected_item.data('short')
        return false
    onLineGet: (d,s,x) ->
        marker.setMap( null ) for marker in @markers
        line.setMap( null ) for line in @lines
        bounds = null
        @markers = for point in d.stops
            new Marker( @map, point )
        if -1 == @markers.indexOf selectedMarker
            InfoWindow.get().setVisible false
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
        endUrl = currentLineUrl
        for child in $('#line_data').children('li')
            stop = $(child).find('h2 a')
            selected = false
            if ( stop.data('selected') )
                selected = true
                selected_stop_id = stop.data('id')
                initialLoadingSentinel = true
                endUrl += '/at/' + selected_stop_id
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
                selected: selected
            })
        state = {
            lineUrl: currentLineUrl
        }
        if ( selected_stop_id != undefined )
            $.merge( state, { stop: selected_stop_id } );
        History.replaceState( state, '', endUrl );
        this.onLineGet( {
            stops: line_data
            paths: $(elem).text() for elem in $('ul#line_paths li')
            colors: { bg: $('#line_data').data('bgcolor'), fg: null }
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

