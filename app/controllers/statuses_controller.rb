class StatusesController < ApplicationController
  def show
    render plain: [
      "APPLICATION: hesabu",
      "RELEASE_TAG: #{ENV['RELEASE_TAG']}",
      "RELEASE_TIME: #{ENV['RELEASE_TIME']}"
    ].join("\n")
  end
end
