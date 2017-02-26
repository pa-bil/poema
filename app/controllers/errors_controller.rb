class ErrorsController < ApplicationController
  def error_404
    raise Poema::Exception::NotFound
  end
end
