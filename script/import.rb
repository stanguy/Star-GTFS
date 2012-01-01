#! /usr/bin/env ruby

require 'gtfs/base'
require 'gtfs/rennes'


r = Gtfs::Rennes.new
r.run
