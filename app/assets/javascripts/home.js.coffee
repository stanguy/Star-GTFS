

class MapBus



    constructor: ->
        this.markers = [];
        $("button").button();
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
        line_url = selected_item.attr 'href'
        $.get( line_url , {},
            (d,s,x) => this.onLineGet(d,s,x),
            "json" )
        return false
    onLineGet: (d,s,x) ->
        console.log("get");
        marker.setMap( null ) for marker in this.markers
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
            marker = new google.maps.Marker( {
                position: myLatLng,
                map: this.map,
                title: point.name,
                icon: icon
            })
            marker

$.dthg = $.dthg || {}
$.dthg.Bus = {
        init: ->
            new MapBus()
    }

