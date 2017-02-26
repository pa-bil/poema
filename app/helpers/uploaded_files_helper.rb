# encoding: utf-8

module UploadedFilesHelper
  def show_user_quota(user)
    quota = user.quota
    if quota.nil?
      "Nie masz ograniczeń dotyczących dostępnej przestrzeni na pliki, możesz przesyłać dowolną ich ilość"
    elsif quota == 0
      "Niestety nie dysponujesz miejscem na pliki, jeśli uważasz, że to błąd skontaktuj sie z redakcją serwisu"
    else
      "#{mfword("Wykorzystałeś", "Wykorzystałaś", user)} #{number_with_precision UploadedFile.get_percent_od_user_space(user), :precision => 1}%
       z dostępnych #{number_to_human_size quota.megabytes} dostępnej przestrzeni na pliki"
    end
  end

  def uploaded_file_path(uploaded_file)
    u = uploaded_file.uploadable
    case u
      when Container
        container_uploaded_file_path u, uploaded_file
      when Publication
        publication_uploaded_file_url u, uploaded_file
      when User
        user_uploaded_file_url u, uploaded_file
      when Calendar
        calendar_uploaded_file_url u, uploaded_file
      else
        raise "Unknown uploadable"
    end
  end

  def uploaded_file_delete_path(uploaded_file)
    url_for(uploaded_file) + delete_path_element
  end

  def new_uploaded_file_path(uploadable)
    case uploadable
      when Container
        new_container_uploaded_file_path
      when Publication
        new_publication_uploaded_file_path
      when User
        new_user_uploaded_file_path
      when Calendar
        new_calendar_uploaded_file_path
      else
        raise "Unknown uploadable"
    end
  end

  def uploaded_file_uploadable_to_human(uploaded_file)
    u = uploaded_file.uploadable
    case u
      when Container
        "Plik dołączony do kontenera #{u.title}"
      when Publication
        "Plik dołączony do publikacji #{u.title}"
      when User
        "Plik dołączony do konta użytkownika #{u.name}"
      when Calendar
        "Plik dołączony do wydarzenia #{u.title}"
      else
        "Komentarz"
    end
  end
end
