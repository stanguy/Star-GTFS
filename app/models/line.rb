class Line < ActiveRecord::Base

  has_and_belongs_to_many :stops
  has_many :stop_times
  has_many :trips
  has_many :headsigns

  def full_name
    short_name + " " + long_name
  end
  
  def is_express?
    if short_name.match(/^\d+$/)
      num_id = short_name.to_i
      return num_id.between?( 40, 49 ) || num_id.between?( 150, 200 ) 
    end
    [ "40ex", "KL" ].include? short_name
  end
  def is_suburban?
    short_name.match(/^\d+$/) && short_name.to_i.between?( 50, 100 )
  end
  def is_urban?
    short_name.match(/^\d+$/) && short_name.to_i.between?( 1, 39 )
  end
  def is_special?
    ! ( is_express? || is_suburban? || is_urban? )
  end
end
