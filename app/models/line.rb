class Line < ActiveRecord::Base

  has_and_belongs_to_many :stops
  has_many :stop_times

  def full_name
    short_name + " " + long_name
  end  
end
