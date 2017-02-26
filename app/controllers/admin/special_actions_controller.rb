class Admin::SpecialActionsController < ApplicationController
  access_control do
    allow :root
  end

  def index
    @special_actions = SpecialAction.list_admin params[:page]

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @special_actions }
    end
  end

  def new
    @special_action = SpecialAction.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @special_action }
    end
  end

  def edit
    @special_action = SpecialAction.find(params[:id])
  end

  def create
    @special_action = SpecialAction.new(params[:special_action])

    respond_to do |format|
      if @special_action.save
        format.html { redirect_to @special_action, :notice => 'Special action was successfully created.' }
        format.json { render :json => @special_action, :status => :created, :location => @special_action }
      else
        format.html { render :action => "new" }
        format.json { render :json => @special_action.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @special_action = SpecialAction.find(params[:id])

    respond_to do |format|
      if @special_action.update_attributes(params[:special_action])
        format.html { redirect_to @special_action, :notice => 'Special action was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @special_action.errors, :status => :unprocessable_entity }
      end
    end
  end
end
