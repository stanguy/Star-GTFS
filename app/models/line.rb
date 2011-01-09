class Line < ActiveRecord::Base

  acts_as_url :long_name, :url_attribute => :slug

  has_and_belongs_to_many :stops
  has_many :stop_times
  has_many :trips
  has_many :headsigns

  scope :by_usage, lambda{ |what_usage|
    ( ( what_usage == :all ) ? scoped : where( :usage => what_usage ) ).order('short_name ASC')
  }
  def full_name
    short_name + " " + long_name
  end
  
  def is_express?
    usage == "express"
  end
  def is_suburban?
    usage == "suburban"
  end
  def is_urban?
    usage == "urban"
  end
  def is_special?
    usage == "special"
  end

  def self.by_short_name str
    if m = str.match( /^([^_]*)_/ )
      str = m[1]
    end
    first( :conditions => { :short_name => m[1] } )
  end
      

  def to_param
    [ short_name, slug ].join('_')
  end
      
end
