class Line < ActiveRecord::Base

  acts_as_url :short_long_name, :url_attribute => :slug
  mount_uploader :picto_url, LinePictoUploader

  searchable auto_index: false do 
    string :short_name, :stored => true
    text :long_name, :stored => true
    integer :agency_id
  end


  belongs_to :agency
  has_and_belongs_to_many :stops
  has_and_belongs_to_many :incidents
  has_many :stop_times
  has_many :trips
  has_many :headsigns
  has_many :polylines

  scope :visible, -> { where hidden: false }

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
    slug = ''
    if m = str.match( /^([^_]*)_(.*)$/ )
      str = m[1]
      slug = m[2]
    end
    l = where(:short_name => str)
    if l.count == 0
      raise ActiveRecord::RecordNotFound
    elsif l.count > 1
      l.find{|l_| l_.slug == slug }
    else
      l.first
    end
  end
      

  def to_param
    [ short_name, slug ].join('_')
  end
      
end
