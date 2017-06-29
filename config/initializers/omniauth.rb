Rails.application.config.middleware.use OmniAuth::Builder do
  if Rails.env == 'development'
    require 'openssl'
    OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
  end

  OmniAuth.config.on_failure do |env| [302, {'Location' => "#{env['SCRIPT_NAME']}#{OmniAuth.config.path_prefix}/niepowodzenie?message=#{env['omniauth.error.type']}", 'Content-Type'=> 'text/html'}, []] end
  OmniAuth.config.path_prefix = '/zaloguj'
  OmniAuth.config.full_host = 'http://' + Poema::Application::custom_config(:site_hostname)

  provider :nk, Poema::Application::custom_config(:nkconnect_key), Poema::Application::custom_config(:nkconnect_secret), :scope => 'BASIC_PROFILE_ROLE,EMAIL_PROFILE_ROLE,CREATE_SHOUTS_ROLE'
  provider :facebook, Poema::Application::custom_config(:facebook_key), Poema::Application::custom_config(:facebook_secret), :scope => 'email,user_location,user_hometown,publish_actions,user_website'
end
