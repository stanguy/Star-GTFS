class StLoImporter
  attr_accessor :first_trip_col, :default_calendar, :stops_range, :stop_col

  def initialize stop_registry
    @time_exceptions = {}
    @stop_registry = stop_registry
  end
      
  def add_exception calendar, cell
    cells = []
    if cell[0].is_a? Range
      cell[0].each do |l|
        cells << [l,cell[1]]
      end
    else
      cells << cell
    end
    cells.each do |icell|
      @time_exceptions[icell] = calendar
    end
  end
      

  def import data

    valid_stop_indexes = self.stops_range.select do |idx|
      self.stop_col < data[idx].length && ! data[idx][self.stop_col].blank?
    end
    trips = []
    trip_indexes = []
    trip_i = self.first_trip_col
    head = data[valid_stop_indexes.first]
    while trip_i < head.length
      unless head[trip_i].nil? 
        if head[trip_i].strip.match(/^(\d+:\d+|-|\|)[A-Z]?$/)
          trip_indexes << trip_i
        elsif !head[trip_i].blank?
          break
        end
      end
      trip_i += 1
    end
    trip_indexes.each do |idx|
      trip_calendar = self.default_calendar
      trip_result = { trip_calendar => [] }
      valid_stop_indexes.each do |line_idx|
        next if data[line_idx][idx].nil?
        next unless matches = data[line_idx][idx].strip.match(/^(\d+:\d+)[A-Z]?$/)
        trip_time = { :t => matches[1].split(':').inject(0) { |m,v| m = m * 60 + v.to_i } * 60, 
          :s => @stop_registry[data[line_idx][self.stop_col]] }
        if @time_exceptions.has_key? [line_idx,idx]
          exception_calendar = @time_exceptions[[line_idx,idx]]
          if trip_calendar & exception_calendar > 0
            new_calendar = trip_calendar ^ exception_calendar
            trip_result[new_calendar] = trip_result.delete trip_calendar
            trip_result[exception_calendar] = trip_result[new_calendar].clone
            trip_calendar = new_calendar
          end
          trip_result[exception_calendar] << trip_time
        else
          trip_result.values.each do |times|
            times << trip_time
          end
        end
      end
      trips << trip_result
    end
    trips
  end
end
