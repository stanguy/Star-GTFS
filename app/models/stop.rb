class Stop < ActiveRecord::Base
  has_many :stop_aliases
  has_and_belongs_to_many :lines
  has_many :stop_times
end
