

require 'net/http'
require 'yajl/http_stream'

require 'opendata_api'

oda = OpenDataKeolisRennesApi.new( ENV['KEOLIS_API_KEY'], '2.0' )
result = Yajl::HttpStream.get( oda.get_lines( :size => "100") )
lines_base_url = result['opendata']['answer']['data']['baseurl']
lines_base_url += '/' unless lines_base_url.end_with?('/')
lines_picto_urls = {}
result['opendata']['answer']['data']['line'].each do|line|
  response = Net::HTTP.get_response( URI.parse( lines_base_url + line['picto'] ) )
  File.open( "tmp/" + line['name'] + ".png", "wb" ) do |file|
    file.write( response.body)
  end
end
