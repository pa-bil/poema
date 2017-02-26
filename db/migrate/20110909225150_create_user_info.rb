# encoding: utf-8

class CreateUserInfo < ActiveRecord::Migration
  def up

    # Właściwa tabela użytkowników
    create_table :users do |t|
      t.references :auth,                       :null => false

      t.boolean    :locked,                     :null => false, :default => 1 # Locked: flaga administracyjna, mówi, że treść została
                                                                              # zablokowana systemowo (eg konto nie aktywowane) - to NIE oznacza usuniętętego konta, tak jak w v3
      t.boolean    :banned,                     :null => false, :default => 0 # Banned: flaga administracyjna, mówi, że treść została
                                                                              # zbanowana z powodów regulaminowych

      t.string     :name,                       :null => false, :limit => 100
      t.string     :gender,                     :null => false, :limit => 1
      t.text       :intro
      t.text       :description

      t.string     :email,                      :null => false, :limit => 100
      t.string     :im_gadugadu,                :limit => 50
      t.string     :im_tlen,                    :limit => 100
      t.string     :website,                    :limit => 254

      t.string     :localisation,               :limit => 254
      t.string     :localisation_geocoder,      :limit => 254
      t.float      :longitude
      t.float      :latitude

      t.boolean    :visible,                    :null => false, :default => 1  # Visible: flaga użytkownika (ustawienie) mówi
                                                                               # że z jakiegoś powodu (prywatność) nie chcemy prezentować tej treści
                                                                               # lub prezentować ją możemy w ograniczonym zakresie

      t.string     :allow_comments,             :null => false, :default => 'D', :limit => 1
      t.boolean    :sendmails,                  :null => false, :default => 1

      t.datetime   :last_comment                                               # data otrzymania ostatniego komentarza
      t.integer    :counter_comment_neutral,    :null => false, :default => 0  # to liczniki komentarzy otrzymanych (commentable)
      t.integer    :counter_comment_positive,   :null => false, :default => 0
      t.integer    :counter_comment_negative,   :null => false, :default => 0

      t.references :terms_version               # Może być nullem, jeśli user nie zgodził się na żadną z wersji
                                                # w takim przypadku nie może komentować, publikować, ani przejawiać
                                                # żadnej innej aktywności związanej z udostępnieniem danych

      t.integer    :avatar_uploaded_file_id
      t.integer    :quota,                      :default => 0                   # null oznacza brak ograniczenia

      t.datetime   :deleted_at
      t.timestamps
    end

    add_foreign_key(:users, :auths)
    add_foreign_key(:users, :terms_versions)

    add_index(:users, [:id, :deleted_at])
    add_index(:users, [:locked, :banned, :visible, :deleted_at])

    ContentObject.find_or_create_by_id(User.name)

    # Aktywacje rejestracji
    create_table :user_signup_activations do |t|
      t.references :user,                       :null => false
      t.string     :code,                       :null => false, :limit => 64
      t.datetime   :signup_on,                  :null => false
      t.datetime   :activation_on
    end

    add_index(:user_signup_activations, :code, :unique => true)

    add_foreign_key(:user_signup_activations, :users)
  end

  def down
  end
end
