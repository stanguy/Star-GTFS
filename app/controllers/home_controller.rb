# -*- coding: utf-8 -*-
class HomeController < ApplicationController
  before_filter :set_agency, :except => :redirect_root

  def redirect_root
    redirect_to agency_path(Agency.order(:id).first)
  end

  def offline
    render :layout => 'container'
  end

  def show
  end

  def stops
    @stops = true
    render :show
  end

  def line
    l = @agency.lines.by_short_name(params[:id])

    if params[:stop_id]
      @selected_stop_id = params[:stop_id]
    end

    headsigns = {}
    l.headsigns.each {|h| headsigns[h.id] = h }
    stop_times = {}
    bearings = {}
    time_ref = nil
    unless params[:t].nil?
      time_ref = Time.zone.at(params[:t].to_i)
    end
    original_stop_times = StopTime.coming(l.id,time_ref).order(:arrival)
    original_stop_times.each do |st|
      stop_times[st.stop_id] = {}
      headsigns.keys.each do|k|
        stop_times[st.stop_id][k] = []
      end
    end
    original_stop_times.each do |st|
      stop_times[st.stop_id][st.headsign_id] << st
      unless bearings.has_key? st.headsign_id
        bearings[st.headsign_id] = st.trip.bearing
      end
    end
    
    stops_of_trip = nil
    if params[:trip_id]
      ref_trip = Trip.find(params[:trip_id])
      stops_of_trip = {}
      ref_trip.stop_times.each do |st|
        stops_of_trip[st.stop_id] = st.arrival.to_formatted_time
      end
    end
    
    other_lines = {}
    Line.
      select( "id,short_name").
      where( :id => l.stops.collect(&:line_ids_cache).
                      map {|ids| ids.split(',') }.flatten.uniq ).each { |vl| other_lines[vl.id] = vl.short_name }
    data = l.stops.collect do|stop|
      if stop.slug == @selected_stop_id
        @selected_stop = stop
      end
      stop_info = {
        :name => stop.name,
        :id => stop.slug, :lat => stop.lat, :lon => stop.lon,
        :accessible => ( l.accessible && stop.accessible ),
        :schedule_url => url_for({ :agency_id => @agency, :action => 'schedule', :line_id => l, :stop_id => stop, :only_path => true }),
        
      }
      stop_info[:trip_time] = stops_of_trip[stop.id] unless stops_of_trip.nil?
      stop_info[:others] = stop.line_ids_cache.split(',').delete_if{|olid| olid.to_i == l.id }.collect{|olid|
        other_lines[olid.to_i]
      }.compact
      if stop_times.has_key? stop.id
        stop_info[:times] = stop_times[stop.id].keys.collect do |headsign_id|
          {
            :direction => headsigns[headsign_id].name,
            :bearing => bearings[headsign_id],
            :times => stop_times[stop.id][headsign_id].collect {|st| { :t => st.arrival.to_formatted_time, :t_dep => st.departure.to_formatted_time, :tid => st.trip_id } }[0,9],
            :schedule_url => url_for({ :action => 'schedule', :agency_id => @agency, :line_id => l, :stop_id => stop, :headsign_id => headsigns[headsign_id], :only_path => true })
          }
        end.reject {|x| x[:times].empty? }
      end
      stop_info
    end
    @incidents = l.incidents.actual
    if request.xhr?
      expires_now
      render json: { 
        stops: data, 
        paths: l.polylines.collect(&:path), 
        colors: { :fg => l.fgcolor, :bg => l.bgcolor },
        incidents: @incidents.collect { |i| { id: i.id, title: i.title } }
      }, callback: params[:callback]
    else
      @line_data = data
      @line_paths = l.polylines.collect(&:path)
      @line_bgcolor = l.bgcolor
      @line_id = l.id
      @line = l
      @title = l.full_name
      if @selected_stop.nil?
        @canonical = home_line_url( @agency, @line )
      else
        @canonical = home_line_stop_url( @agency, @line, @selected_stop )
      end
      render :show
    end
  end
  
  def line_incidents
    @line = @agency.lines.by_short_name(params[:id])
    @incidents = @line.incidents.actual
    if request.xhr?
      render :layout => 'bare_container' and return
    end
    render :layout => 'container'
  end
  
  before_filter :check_legacy, :only => :schedule
  before_filter :check_old_ids, :only => :schedule

  def schedule
    @headsigns = {}
    stop_signs = nil
    @stop = @agency.stops.find_by_slug(params[:stop_id]) or raise ActiveRecord::RecordNotFound.new
    @other_lines = nil
    if params[:line_id]
      @line = @agency.lines.by_short_name(params[:line_id])
      @title = "Horaires de la ligne #{@line.short_name} à l'arrêt #{@stop.name}"
      process_headsigns @line

      stop_signs = StopTime.where( :line_id => @line.id ).
        where( :stop_id => @stop.id )
      if params[:headsign_id]
        headsign = Headsign.find_by_slug(params[:headsign_id])
        unless headsign.nil?
          stop_signs = stop_signs.where( :headsign_id => headsign.id )
          @title = @title + " direction #{headsign.name}"
        end
      end
      @other_lines = @stop.lines.select( "id,short_name,picto_url,slug").collect{|sl|
        if sl.id != @line.id
          sl
        end
      }.compact
    else
      @title = "Horaires à l'arrêt #{@stop.name}"
      @headsigns = {}
      @stop.lines.each {|l|
        process_headsigns l
      }
      stop_signs = StopTime.where( :stop_id => @stop ).
        where( :line_id => @stop.lines )
    end
    @schedule = {}
    @all_calendars = {}

    stop_signs.each do |st|
      unless @schedule.has_key? st.headsign_id
        @schedule[st.headsign_id] = {}
        @all_calendars[st.headsign_id] = {}
      end
      ( hours, mins ) = st.arrival.to_hm false
      unless @schedule[st.headsign_id].has_key? hours
        @schedule[st.headsign_id][hours] = {}
      end
      unless @schedule[st.headsign_id][hours].has_key? st.calendar
        @schedule[st.headsign_id][hours][st.calendar] = []
        @all_calendars[st.headsign_id][st.calendar] = 1
      end
      @schedule[st.headsign_id][hours][st.calendar] << mins
    end
    @headsigns.delete_if{|id,v| ! @schedule.has_key? id }
    if request.xhr?
      render :layout => 'bare_container' and return
    else

      if @line && headsign
        @canonical = line_stop_schedule_url( @agency, @line, @stop, headsign )
      elsif @line
        @canonical = line_stop_schedule_url( @agency, @line, @stop )        
      elsif @stop
        @canonical = stop_schedule_url( @agency, @stop )
      end


      render :layout => 'container'
    end
  end

  def search
    agency = @agency
    search = Sunspot.search [Stop,Line] { 
      fulltext params[:term] 
      with :agency_id, agency.id
      paginate :page => 1, :per_page => 10
    }
    @results = search.hits.collect {|h|
      case h.class_name
      when "Stop"
        stop = h.result
        v = {
          :type => :stop,
          :name => stop.name,
          :id => stop.id,
          :schedule_url => stop_schedule_url(@agency,stop),
          :times => nil,
          :others => nil,
          :accessible => stop.accessible
        }
        if stop.geom? 
          v[:lat]= stop.geom.lat
          v[:lon]= stop.geom.lon
        end
        v
      when "Line"
        { 
          :type => :line,
          :name => [h.stored(:short_name), h.stored(:long_name).shift].join( " " ),
          :short => h.stored(:short_name),
          :id => h.primary_key,
        }
      end
    }
    respond_to do |format|
      format.html { render :layout => 'container'}
      format.rss {  render :layout => false }
      format.suggestions { 
        render :json => [ params[:term],
                          @results.collect {|r| r[:name] },
                          @results.collect { "" },
                          @results.collect {|r| r[:type] == :stop ? r[:schedule_url] : home_line_url(@agency,r[:short])}
                        ]
      }
      format.json { render :json => @results }
    end
  end

  def opensearch
    response.headers["Content-Type"] = 'application/opensearchdescription+xml'
    render :layout => false
  end
      

  private
  def check_old_ids
    if params[:line_id].nil? && params[:stop_id].match(/^[0-9]*$/)
      redirect_to( { :stop_id => Stop.find(params[:stop_id])},:status=>:moved_permanently ) and return false      
    elsif (!params[:line_id].nil?) && params[:line_id].match(/^[0-9]*$/) && params[:stop_id].match(/^[0-9]*$/)
      redirect_to( { :line_id => Line.find(params[:line_id]), :stop_id => Stop.find(params[:stop_id])},:status=>:moved_permanently ) and return false
    end
    
  end
      
  def process_headsigns line
    line.headsigns.each do |h|
      if h.name.match( Regexp.new( "^#{line.short_name} " ) )
        @headsigns[h.id] = h.name
      else
        @headsigns[h.id] = "#{line.short_name} vers #{h.name}"
      end
      unless line.picto_url.blank?
        @headsigns[h.id] = self.class.helpers.image_tag( line.picto_url ) + @headsigns[h.id]
      end
    end
  end

  def check_legacy
    if params[:route_id]
      # someone is using a legacy route
      params[:line_id] = Line.first( :conditions => { :src_id => params[:route_id] } ).to_param
      params[:stop_id] = StopAlias.first( :conditions => { :src_id => params[:stop_id] } ).stop.to_param
    end
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def set_agency
    if params[:agency_id]
      @agency = Agency.find_by_slug( params[:agency_id] )
      if @agency.nil?
        not_found
      end
    else
      not_found
    end
  end

end
