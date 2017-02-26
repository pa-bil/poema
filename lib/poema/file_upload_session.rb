# Rozszerzenie implementuje metody związane z obsługą uploadu pliku via JSowy plupload
# Plik zapisywany jest w sesji, można do odczytać lub zapisać na stałe w bazie danych

require 'RMagick'
module Poema
  module FileUploadSession

    def save_file_session_from_net(url)
      uri = URI.parse(url)
      redirects = 0
      while (request = Net::HTTP.get_response(uri)).code.to_i == 302
        raise "Too many redirects" if redirects > 5
        uri = URI.parse(request.header['location'])
        redirects = redirects + 1
      end

      content_type = request.header['content-type']
      image = request.body

      file = {
        :content   => image,
        :filename  => File.basename(uri.path) ? File.basename(uri.path) : 'Avatar',
        :type      => content_type
      }

      session[JsController::USER_STATE_SESSION_PREFIX + :file_session_present.to_s] = true
      session[:file_upload_session_file_avatar] = session[:file_upload_session_file] = file
    end

    def save_file_session(file)
      d = UploadedFile::AVATAR_DIM
      m = Magick::Image.read(file.tempfile.path).first.resize_to_fill!(d, d)

      t = File.open(file.tempfile.path, "rb")

      session[JsController::USER_STATE_SESSION_PREFIX + :file_session_present.to_s] = true
      session[:file_upload_session_file_avatar] = {
        :content   => m.to_blob,
        :filename  => file.original_filename,
        :type      => file.content_type
      }
      session[:file_upload_session_file] = {
        :content   => t.read,
        :filename  => file.original_filename,
        :type      => file.content_type
      }

      t.close
      m.destroy!
    end

    def get_file_session
      session[:file_upload_session_file] if session[:file_upload_session_file].instance_of?(Hash)
    end

    def get_file_session_avatar
      session[:file_upload_session_file_avatar] if session[:file_upload_session_file_avatar].instance_of?(Hash)
    end

    def persist_destroy_file_session(session_file, file, uploadable, content_copyright, is_avatar)
      persist_file_session(session_file, file, uploadable, content_copyright, is_avatar)
      destroy_file_session
    end

    def persist_file_session(session_file, file, uploadable, content_copyright, is_avatar)
      # Używam StringIO do utworzenia pliku ze String, potrzebne są dodatkowe metody
      # emulujące File
      StringIO.send(:define_method, "content_type", proc { session_file[:type] })
      StringIO.send(:define_method, "original_filename", proc { session_file[:filename] })

      uploadable.uploaded_files << file

      file.content_copyright = content_copyright
      file.file_file_name = session_file[:filename]
      file.file_content_type = session_file[:type]
      file.file = StringIO.new(session_file[:content])
      file.save!

      if is_avatar
        old_avatar = uploadable.avatar
        uploadable.avatar = file
        uploadable.save!
        old_avatar.destroy unless old_avatar.nil?
      end

      StatCounterObject.increment_counter :uploaded_file
    end

    def destroy_file_session
      session[JsController::USER_STATE_SESSION_PREFIX + :file_session_present.to_s] = false
      session[:file_upload_session_file] = nil
      session[:file_upload_session_file_avatar] = nil
    end
  end
end
