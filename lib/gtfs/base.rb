
require 'csv'

module Gtfs
  class Base
    def mlog msg
      puts Time.now.to_s(:db) + " " + msg
    end

    def read_tmp_csv file
      CSV.foreach( File.join( Rails.root, "/tmp/#{file}.txt" ),
                   :headers => true,
                   :header_converters => :symbol,
                   :encoding => 'UTF-8' ) do |line|
        yield line.to_hash
      end
    end
    
    def line_usage line
      raise NotImplementedError 
    end

    def initialize
      @steps = [ "agency", "feed_info", "stops", "routes", "calendar", "calendar_dates", "trips", "stop_times" ]
    end
    
    def run
      self.pre_run if self.respond_to?(:pre_run)
      @steps.each do |step|
        mlog step
        [ "pre_", "", "post_" ].each do |prefix|
          method_name = (prefix + step).to_sym
          if self.respond_to? method_name
            ActiveRecord::Base.transaction do
              self.send method_name
            end
          end
        end
      end
      self.post_run if self.respond_to?(:post_run)
      center_agency
    end

    def center_agency
      return if @agency.nil?
      @agency.bbox = MultiPoint.from_points( MultiPoint.from_points( Stop.where("geom IS NOT NULL").collect(&:geom), 4326 ).bounding_box.map { |p| p.srid = 4326; p }, 4326 )
      @agency.center = Geometry.from_ewkt( Stop.connection.select_one( "SELECT AsText(ST_Centroid(ST_Collect(geom))) AS center FROM stops WHERE geom IS NOT NULL" )["center"] )
      @agency.center.srid = 4326
      @agency.save
    end
    
    class << self
      def handle file_name, &block
        handling_method = file_name.to_s + "_handle"
        send :define_method, handling_method, &block
        send :define_method, file_name.to_sym do
          read_tmp_csv file_name.to_s do |line|
            self.send handling_method, line
          end
        end
      end
    end

  end

end
