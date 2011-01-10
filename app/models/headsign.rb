class Headsign < ActiveRecord::Base
  
  acts_as_url :name, :url_attribute => :slug

  belongs_to :line
  has_many :trips

  def to_param
    slug
  end
      
end
