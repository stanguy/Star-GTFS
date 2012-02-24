class Agency < ActiveRecord::Base
  acts_as_url :city, :url_attribute => :slug
  
  has_many :lines

  def to_param
    slug
  end
end
