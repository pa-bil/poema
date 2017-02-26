Poema::Application.routes.draw do
  root :to => "frontpage#index"
  get '/feed', to: 'frontpage#feed'

  scope :path_names =>  { :new => 'dodaj', :edit => 'edytuj', :delete => 'usun' } do

    # Uwaga!
    # Kolejność ma znaczenie, wcześniejsze wpisy resolwują się szybciej, zatem te najczęsciej używane
    # dokładam sobie na samą górę.
    
    # Strona użytkownika, (karta informacyjna nie dashboard)
    resources :users, :path => 'profil', :only => [:show, :index_owned, :index_commented] do
      member do
        get :index_publications, :path => 'publikacje'
        get :index_commented, :path => 'komentowane'
      end
      resources :comments, :path => "komentarz", :only => [:index, :new, :create], :context => User.name do
        resource :moderations, :path => "moderacja", :only => [:new, :create, :delete, :destroy], :context => Comment.name do
          collection do
            get :delete
          end
        end
      end
      resource :moderations, :path => "moderacja", :only => [:new, :create, :delete, :destroy], :context => User.name do
        collection do
          get :delete
        end
      end
      resource :user_blacklists, :path => 'czarna_lista', :only => [:new, :create, :delete, :destroy] do
        collection do
          get :delete
        end
      end
    end
    
    # Kontener
    resources :containers, :path => 'kontener' do
      collection do
        get 'wybierz',     :to => 'containers#picker', :as => :picker_top
        get 'wybierz/:id', :to => 'containers#picker', :as => :picker
      end
      member do
        get :delete
        get :index_publications_since, :path => 'nowe_publikacje'
        get :index_publications_last,  :path => 'ostatnie_publikacje'
      end
      resources :comments, :path => "komentarz", :only => [:index, :new, :create], :context  => Container.name do
        resource :moderations, :path => "moderacja", :only => [:new, :create, :delete, :destroy], :context => Comment.name do
          collection do
            get :delete
          end
        end
      end
      resources :roles,          :path => 'uprawnienia', :context  => Container.name
      resources :containers,     :path => 'kontener'
      resources :publications,   :path => 'publikacja', :only => [:new, :create]
      resources :uploaded_files, :path => 'plik', :only => [:index, :new, :create, :delete, :destroy], :context  => Container.name do
        member do
          get :delete
        end
      end
    end
    
    # Publikacje
    resources :publications, :path => 'publikacja', :only => [:show, :edit, :update, :delete, :destroy] do
      member do
        get :delete
      end
      resources :comments, :path => "komentarz", :only => [:index, :new, :create], :context  => Publication.name do
        resource :moderations, :path => "moderacja", :only => [:new, :create, :delete, :destroy], :context => Comment.name do
          collection do
            get :delete
          end
        end
      end
      resources :uploaded_files, :path => "plik", :only => [:index, :new, :create, :delete, :destroy], :context => Publication.name do
        member do
          get :delete
        end
      end
      resource :special_actions, :path => 'akcje_promocyjne', :only => [:new, :create, :delete, :destroy] do
        member do
          get :delete
        end
      end
    end
    
    # Signup
    get  '/nowe_konto',             :to => "signup#new",                               :as => :new_signup
    post '/nowe_konto',             :to => "signup#create"
    get  '/nowe_konto/gratulacje',  :to => "signup#thanks",                            :as => :complete_signup
    get  '/nowe_konto/:token',      :to => "signup#activation",                        :as => :new_signup_activation

    # Logowanie
    get  '/zaloguj',                :to => "session#login",                            :as => :new_session
    post '/zaloguj',                :to => "session#authenticate_via_login_pass"
    get  '/wyloguj',                :to => "session#logout",                           :as => :delete_session

    # Popatrz także do initializers/omniauth.rb gdzie zdefiniowane są domyślne ścieżki
    match "/zaloguj/:provider/callback", :to => "session#authenticate_via_omniauth"
    match "/zaloguj/niepowodzenie",      :to => "session#login"

    # reset hasła
    get  '/haslo',                  :to => "password_reminder#new",                    :as => :new_password_reminder
    post '/haslo',                  :to => "password_reminder#create"
    put  '/haslo',                  :to => "password_reminder#create"
    get  '/haslo/:token',           :to => "password_reminder#destroy",                :as => :delete_password_reminder

    # Obsługa zapisywania stanu elementów aplikacji JS, eg, zaznaczonych zakładek, kolejności elementów
    # wszelkich backendów używanych wyłącznie przez JS
    get  "/js",                     :to => "js#index",                                 :as => :js_backend
    get  "/js/state",               :to => "js#get_state"
    post "/js/state",               :to => "js#set_state"
    post "/js/file_upload/session", :to => "js#file_upload_session"
    get  "/js/:action",             :controller => "js"
    
    # Wizard publikacji
    get  '/publikuj/start',         :to => 'publication_wizard#content_type',          :as => :publication_wizard
    post '/publikuj/start',         :to => 'publication_wizard#content_type_save'
    get  '/publikuj/kontener',      :to => 'publication_wizard#choose_container',      :as => :publication_wizard_choose_container
    post '/publikuj/kontener',      :to => 'publication_wizard#choose_container_save'

    # RSS
    get "/rss",                    :to => 'rss#publications',                         :as => :rss_publication, :defaults => { :format => 'rss' }

    # Wyszukiwarka treści
    resource :search, :path => '/szukaj', :only => [:index, :result] do
      collection do
        post :result, :path => 'wyniki'
      end
    end

    # Strony statyczne
    get "/strona",                 :to => "static_page#index",                        :as => :static_page
    get "/strona/:page",           :to => "static_page#show"
    
    # A tu magia z dynamicznym robots txt, na staging chcemy mieć inny, na produkcji inny
    get '/robots.txt',             :to => "static_page#robots"
    
    # Profil użytkownika
    namespace :user, :path => '' do
      resource :profile, :path => 'konto', :only => [:show, :update, :destroy] do
        collection do
          get :delete
        end
      end
    end
    # Akcje dotyczące regulaminu serwisu
    resources :terms, :path => 'regulamin', :only => [:index, :show] do
      resources :terms_accept, :path => 'akceptacja', :only => [:new, :update]
    end

    # Akcje dotyczące forum, wątków i postów
    resources :forums, :path => 'forum', :only => [:index, :show] do
      resources :forum_threads, :path => 'tematy', :only => [:show, :new, :create, :edit, :update] do
        resource :moderations, :path => "moderacja", :only => [:new, :create, :delete, :destroy], :context => ForumThread.name do
          collection do
            get :delete
          end
        end
        resources :forum_posts, :path => 'odpowiedzi', :only => [:new, :create] do
          resource :moderations, :path => "moderacja", :only => [:new, :create, :delete, :destroy], :context => ForumPost.name do
            collection do
              get :delete
            end
          end
        end
      end
    end

    resources :calendars, :path => 'wydarzenia' do
      resources :comments, :path => "komentarz", :only => [:index, :new, :create], :context  => Calendar.name do
        resource :moderations, :path => "moderacja", :only => [:new, :create, :delete, :destroy], :context => Comment.name do
          collection do
            get :delete
          end
        end
      end
      resources :uploaded_files, :path => "plik", :only => [:index, :new, :create, :delete, :destroy], :context  => Calendar.name do
        member do
          get :delete
        end
      end
    end

    resources :special_actions, :only => [:show], :path => 'akcje_promocyjne'

    get '/admin', :to => 'admin/admin#index'
    namespace :admin do
      get 'audits', :to => "audits#index"
      resources :special_actions

      resource :charts, :only => [:show] do
        collection do
          get :data
        end
      end
     
      # To w całości kontekst użytkownika
      resources :users, :only => [:index, :show, :edit, :update, :delete, :destroy] do
        get 'audits', :to => "audits#index_user"
        member do
          get :delete
        end
        collection do
          get :search
        end
      end
    end

    get 'heartbeat', :to => 'heartbeat#show'

    # Routing error, musi być obsługiwany osobno i MUSI BYĆ OSTATNIM elementem tablicy routingu
    match '*routing_error', :to => 'errors#error_404'
  end
end
