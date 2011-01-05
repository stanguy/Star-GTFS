

require 'net/http'

Line.all.each do |line|
  next if line.picto_url.blank?
  response = Net::HTTP.get_response( URI.parse( line.picto_url ) )
  # this is slightly wrong, as we also have .gif files
  File.open( "tmp/" + line.short_name + ".png", "wb" ) do |file|
    file.write( response.body )
  end
end
