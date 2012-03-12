# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "http://maps.dthg.net"

SitemapGenerator::Sitemap.create do
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end
  Agency.all.each do |agency|
    add agency_path(agency)
    agency.lines.each do |line|
      add home_line_path( agency, line ), :priority => 0.75
      line.stops.each do |stop|
        add line_stop_schedule_path( agency, line, stop ), :priority => 0.25
      end
    end
    agency.stops.each do |stop|
      add stop_schedule_path( agency, stop ), :priority => 0.5
    end
  end
end
