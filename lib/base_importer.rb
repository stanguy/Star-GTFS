class BaseImporter
    attr_accessor :root
    def mlog msg
      puts Time.now.to_s(:db) + " " + msg
    end

    def initialize
      @root = File.join Rails.root, "tmp"
      if ENV.has_key?( "STARGTFS_IMPORT_BASE" ) && File.directory?( ENV["STARGTFS_IMPORT_BASE"] )
        @root = ENV["STARGTFS_IMPORT_BASE"]
        city_specific = File.join( @root, self.class.name.split('::').last.downcase )
        if File.directory?( city_specific )
          @root = city_specific
        end
      end
    end

    def run
      raise NotImplementedError 
    end

end
