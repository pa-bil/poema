class RolesController < ApplicationController
  before_filter :load_data

  access_control do
    allow :root
  end

  private

  def load_data
    @context = params[:context].constantize.find(params["#{params[:context].to_underscore}_id"])
  end

  public

  def index

  end
end
