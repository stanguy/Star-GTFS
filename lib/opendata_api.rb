
require 'cgi'
require 'uri'

require 'active_support/core_ext/object/to_query'
require 'active_support/core_ext/object/to_param'


class OpenDataApi

  def initialize key, version 
    @key = key
    unless version.match /^\d+\.\d+$/
      raise ArgumentError.new( "wrong version format")
    end
    @version = version
  end

  def generate_uri cmd, params = nil
    query = { 
      :cmd => cmd,
      :version => @version,
      :key => @key
    }
    unless params.nil?
      query[:param] = params
    end
    return URI.parse base_uri + "?" + query.to_param
  end

  def method_missing method, *args
    generate_uri method.to_s.gsub('_',''), args[0]
  end
      
end

class OpenDataRennesMetropoleApi < OpenDataApi
  BASE_URI = "http://www.data.rennes-metropole.fr/json/"

  def base_uri
    BASE_URI
  end
end

class OpenDataKeolisRennesApi < OpenDataApi
  BASE_URI = "http://data.keolis-rennes.com/json/"

  def base_uri
    BASE_URI
  end
end
