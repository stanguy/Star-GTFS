
class KeolisApiCollector < InfoCollector
  def perform
    oda = OpenDataKeolisRennesApi.new( ENV['KEOLIS_API_KEY'], '2.0' )
    response = Net::HTTP.get_response oda.get_lines_alerts
    if response.code == 200
      oda_response = JSON(response.body)
      if oda_response['opendata']['answer']['status']['@attributes']['code'] == "0"
        oda_response['opendata']['answer']['data']['alert'].each do |alert|
          if ! Incident.find_by_since_and_title( Time.parse( alert["starttime"] ), alert["title"])
            incident = Incident.create( info_collector_id: self.id,
                                        title: alert["title"],
                                        since: Time.parse( alert["starttime"] ), 
                                        expiration: Time.parse( alert["endtime"] ),
                                        detail: alert["detail"])
            ( alert["lines"]["line"].is_a?( Array ) ? alert["lines"]["line"] : [ alert["lines"]["line"] ] ).each do |line_id|
              if l = self.agency.lines.find_by_short_name( line_id )
                l.incidents << incident
                l.save!
              end
            end
          end
        end
      end
    end

  end
end
