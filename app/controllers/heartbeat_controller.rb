class HeartbeatController < ApplicationController
  prepend_before_filter :skip_session

  def show
    respond_to do |format|
      format.html { }
      format.json { render :json => @forums }
    end

  end
end
