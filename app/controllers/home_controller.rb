# -*- coding: utf-8 -*-
class HomeController < ApplicationController
  def show
  end

  def stops
    @stops = true
    render :show
  end

  def line
    l = Line.by_short_name(params[:id])

    if params[:stop_id]
      @selected_stop = params[:stop_id]
    end

    headsigns = {}
    l.headsigns.each {|h| headsigns[h.id] = h }
    stop_times = {}
    bearings = {}
    original_stop_times = StopTime.coming(l.id).includes(:trip).order(:arrival)
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
      stop_info = {
        :name => stop.name,
        :id => stop.slug, :lat => stop.lat, :lon => stop.lon,
        :accessible => ( l.accessible && stop.accessible ),
        :schedule_url => url_for({ :action => 'schedule', :line_id => l, :stop_id => stop, :only_path => true }),
        
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
            :times => stop_times[stop.id][headsign_id].collect {|st| { :t => st.arrival.to_formatted_time, :tid => st.trip_id } }[0,9],
            :schedule_url => url_for({ :action => 'schedule', :line_id => l, :stop_id => stop, :headsign_id => headsigns[headsign_id], :only_path => true })
          }
        end.reject {|x| x[:times].empty? }
      end
      stop_info
    end
    if request.xhr?
      expires_now
      render :json => { stops: data, paths: l.polylines.collect(&:path), :colors => { :fg => l.fgcolor, :bg => l.bgcolor } }, :callback => params[:callback]
    else
      @line_data = data
      @line_paths = l.polylines.collect(&:path)
      @line_bgcolor = l.bgcolor
      @line_id = l.id
      @line = l
      @title = l.full_name
      render :show
    end
  end
  
  before_filter :check_legacy, :only => :schedule
  before_filter :check_old_ids, :only => :schedule

  def schedule
    @headsigns = {}
    stop_signs = nil
    @stop = Stop.find_by_slug(params[:stop_id]) or raise ActiveRecord::RecordNotFound.new
    @other_lines = nil
    if params[:line_id]
      @line = Line.by_short_name(params[:line_id])
      @title = "Horaires de la ligne #{@line.short_name} à l'arrêt #{@stop.name}"
      process_headsigns @line

      stop_signs = StopTime.where( :line_id => @line.id ).
        where( :stop_id => @stop.id )
      if params[:headsign_id]
        headsign = Headsign.find_by_slug(params[:headsign_id])
        unless headsign.nil?
          stop_signs = stop_signs.where( :headsign_id => headsign.id )
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
      render :layout => false and return
    end
  end

  def alt
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
      
end
