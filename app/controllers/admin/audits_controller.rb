class Admin::AuditsController < ApplicationController
  access_control do
    allow :root
  end

  def index
    @audits = Audit.list(params[:audits_page])
  end

  def index_user
    @user = User.with_deleted.find(params[:user_id])
    @audits = Audit.list_by_owner_and_owner_as_subject(@user, params[:audits_page])
  end
end