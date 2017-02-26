class Admin::AdminController < ApplicationController
  access_control do
    allow :root
  end
end
