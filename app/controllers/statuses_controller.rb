class StatusesController < ApplicationController
  def show
    render plain: "hesabu: #{ENV['RELEASE_TAG']}"
  end
end
