class Headsign < ActiveRecord::Base
  belongs_to :line
  has_many :trips
end
