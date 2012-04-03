xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Bus de #{@agency.city} en ligne"
    xml.description "Carte et horaires des bus de #{@agency.city}"
    xml.link agency_url(@agency)
    if @results.length > 0
      @results.each do |result|
        xml.item do
          xml.title result[:name]
          xml.link result[:type] == :stop ? result[:schedule_url] : home_line_url( @agency, result[:short] )
        end
      end
    end
  end
end
