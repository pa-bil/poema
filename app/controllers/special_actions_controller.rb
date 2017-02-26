class SpecialActionsController < ApplicationController
  before_filter :load_data, :except => [:show]

  access_control do
    allow all, :to => [:show]
    allow :root, :to => [:new, :create, :delete, :destroy]
    allow :special_action_operator, :to => [:new, :create]
  end

  private

  def load_data
    @publication = Publication.find(params[:publication_id])
    @special_action_publication = @publication.special_action_publications.new
  end

  public

  def show
    @special_action = SpecialAction.find(params[:id])
    @default_sort = Publication::SORT_BY_DATE
    @publications = @special_action.list_publications params[:publications_page], params[:publications_sort], @default_sort

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def new
    @special_actions = SpecialAction.list_active

    respond_to do |format|
      format.html
    end
  end

  def create
    @special_actions = SpecialAction.list_active
    @special_action_publication.special_action_id = params[:special_action_id]

    respond_to do |format|
      if @special_action_publication.save
        format.html { redirect_to @publication, :notice => 'Special action was successfully created.' }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def delete
    @special_actions_publications = @publication.special_action_publications.includes(:special_action)
  end

  def destroy
    if params[:special_actions_publication_id]
      params[:special_actions_publication_id].each do |special_actions_publication_id|
        ap = SpecialActionPublication.find(special_actions_publication_id)
        ap.destroy
      end
    end

    respond_to do |format|
      format.html { redirect_to @publication, :notice => 'Special action was successfully deleted.' }
    end
  end
end
