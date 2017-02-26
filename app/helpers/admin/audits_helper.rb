# encoding: utf-8

module Admin::AuditsHelper
  def audit_human_description(audit)
    audit_event_to_human(audit) + ' ' + audit_auditable_to_human(audit).uncapitalize
  end

  def audit_auditable_to_human(audit)
    case audit.auditable
      when User
        "Konto użytkownika #{audit.auditable.name}"
      when Auth
        "Konto użytkownika #{audit.auditable.login}"
      when Container
        "Kontener #{audit.auditable.title}"
      when Publication
        "Publikacja #{audit.auditable.title}"
      when Comment
        comment_commentable_to_human(audit.auditable)
      when UploadedFile
        uploaded_file_uploadable_to_human(audit.auditable)
      when ForumThread
        "Wątek forum #{audit.auditable.title}"
      when ForumPost
        "Odpowiedź na wątek forum #{audit.auditable.forum_thread.title}"
      when TermsAcceptLog
        "Akceptacja regulaminu w wersji #{audit.auditable.terms_version.id}"
      else
        "#{audit.auditable_type}::#{audit.auditable_id}"
    end
  end

  def audit_event_to_human(audit)
    case audit.event_type
      when Audit::EVENT_ERROR
        "Błąd"
      when Audit::EVENT_CREATE
        "Utworzenie elementu"
      when Audit::EVENT_UPDATE
        "Aktualizacja elementu"
      when Audit::EVENT_DESTROY
        "Usunięcie elementu"
      when Audit::EVENT_MOVE
        "Zmiana położenia elementu"
      when Audit::EVENT_AUTH
        "Próba logowania"
      when Audit::EVENT_APPLICATION_ERROR
        "Błąd aplikacji"
      when Audit::EVENT_OTHER
        "Inne"
      else
        raise "Unable to determine audit.event_type"
    end
  end
end