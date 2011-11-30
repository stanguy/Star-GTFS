

class MapBus
    constructor: ->
        this.markers = []
        this.alerts = {}
        this.selected_stop_id = null
        $("button").button()
        $("button.alert").button("disable")
        this.map = new google.maps.Map($('#map')[0], {
                'scrollwheel': ! $('#disable_scrollwheel:checked').val(),
                'zoom': 12,
                'center': new google.maps.LatLng( 48.11, -1.63 ),
                'mapTypeId': google.maps.MapTypeId.ROADMAP
        })
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
        $("button.alert").button("enable") if this.alerts[short]
        return false
    onLineGet: (d,s,x) ->
        marker.setMap( null ) for marker in this.markers
        bounds = null
        selected_marker = null
        this.markers = for point in d
            myLatLng = new google.maps.LatLng( point.lat, point.lon )
            if point.others != undefined && point.others.length > 0
                icon_type = "bus"
            else
                icon_type = "point";
            if ( point.accessible )
                icon_type = icon_type + '_access';
            if( point.times != undefined && point.times.length > 0 )
                icon = $.dthg.Assets.icons[icon_type].green;
            else
                icon = $.dthg.Assets.icons[icon_type].red;
            if point.trip_time != undefined
                marker = new MarkerWithLabel( {
                    position: myLatLng,
                    map: this.map,
                    title: point.name,
                    icon: icon,
                    labelContent: point.trip_time,
                    labelAnchor: new google.maps.Point(19, 0),
                    labelClass: "timeLabel"
                });
            else
                marker = new google.maps.Marker( {
                    position: myLatLng,
                    map: this.map,
                    title: point.name,
                    icon: icon
                })
            if ( bounds == null )
                bounds = new google.maps.LatLngBounds( myLatLng, myLatLng );
            else if ( ! bounds.contains( myLatLng ) )
                bounds.extend( myLatLng );
            marker.stop_id = point.id;
            marker.times = point.times;
            marker.schedule_url = point.schedule_url;
            marker.others = point.others;
            google.maps.event.addListener( marker, 'click', -> false );
            if ( this.selected_stop_id != null && point.id == this.selected_stop_id )
                selected_marker = marker;
            marker
        if ( this.map.getBounds() != undefined && ! this.map.getBounds().intersects( bounds ) )
            this.map.panToBounds( bounds );
        if ( selected_marker != null )
            google.maps.event.trigger( selected_marker, 'click' );


$.dthg = $.dthg || {}
$.dthg.Bus = {
        init: ->
            new MapBus()
    }

