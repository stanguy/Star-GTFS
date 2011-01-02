class LinesController < ApplicationController
  def index
    usage = params[:id_or_type].to_sym
    if [ :all, :urban, :suburban, :express, :special ].include? usage
      @lines = Line.by_usage(usage)
    else
      @line = Line.find(usage)
      @stops = @line.stops
      render :stops and return
    end
  end

end
