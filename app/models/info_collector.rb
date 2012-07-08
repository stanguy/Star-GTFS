class InfoCollector < ActiveRecord::Base
  attr_accessible :agency_id, :last_called_at, :params, :type

  serialize :params

  belongs_to :agency
  has_many :incidents
end
