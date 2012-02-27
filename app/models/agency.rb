class Agency < ActiveRecord::Base
  acts_as_url :city, :url_attribute => :slug
  
  has_many :lines
  has_many :stops

  def to_param
    slug
  end
end
