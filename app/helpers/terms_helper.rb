module TermsHelper
  def terms_version_format(v)
    render 'terms/version_format', :v => v
  end
end
