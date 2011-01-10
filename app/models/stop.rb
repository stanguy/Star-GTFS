class Stop < ActiveRecord::Base

  acts_as_url :name, :url_attribute => :slug

  has_many :stop_aliases
  has_and_belongs_to_many :lines
  has_many :stop_times
  belongs_to :city

  scope :within, lambda {|se,nw|
    where( :lat => (se[:lat])..(nw[:lat]) ).
    where( :lon => (se[:lon])..(nw[:lon]) )
  }

  def to_point
    Point.new( self.lat, self.lon )
  end

  def to_param
    slug
  end
      
end
