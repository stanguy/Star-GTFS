# -*- coding: utf-8 -*-
module Gtfs
  class Bordeaux < Base
    def city
      "Bordeaux"
    end
    def ads_allowed
      true
    end
    def find_city_by_stop stops
      nil
    end
        
    def initialize
      super
      @steps.delete "feed_info"
      @lines_accessible = Hash.new(false)
      @lines_picto_urls = {}
    end
    def line_usage line
      return :urban if line[:route_long_name].match /^Liane/
      return :suburban if line[:route_long_name].match /^Corol/
      return :suburban if line[:route_long_name].match /^Citéis/
      return :special if line[:route_long_name].match /^(Flexo|Résago)/
      return :special if %w{74 78 79 80 86 93 94 95 96}.include? line[:route_short_name]
      return :suburban if (20..29).include? line[:route_short_name].to_i
      return :suburban if (60..92).include? line[:route_short_name].to_i
      :special
    end
        
  end
end
