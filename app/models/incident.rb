class Incident < ActiveRecord::Base
  attr_accessible :detail, :expiration, :since, :info_collector_id, :source_ref, :title

  belongs_to :info_collector

  scope :actual, where( "since <= NOW() AND expiration >= NOW()" )
  
end
