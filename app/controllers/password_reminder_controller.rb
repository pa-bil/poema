class PasswordReminderController < ApplicationController

  access_control do
    allow anonymous, :to => [:new, :create, :destroy]
  end

  def new
    @password_reminder = PasswordReminder.new
    render :new
  end

  def create
    @password_reminder = PasswordReminder.new(params[:password_reminder])
    if create_reminder @password_reminder
      render :create
    else
      render :new
    end
  end

  def destroy
    @password_reminder = PasswordReminder.find_by_token!(params[:token])
    if complete_reminder @password_reminder
      render :finish
    else
      render :new
    end
  end

  private

  def create_reminder(r)
    perform_in_transaction do
      r.save!
      r.audit!({:user => r.user, :ip => session_ip, :description => "User requested password reminder", :event_type => Audit::EVENT_CREATE})
      UserMailer.password_reminder_create(r).deliver
    end
  end

  def complete_reminder(r)
    perform_in_transaction do
      r.audit_params({:user => r.user, :ip => session_ip, :description => "Send new password to #{r.user.email}"})
      r.completed_at = DateTime.current
      r.save!

      a = r.user.auth
      a.password = (password = SecureRandom.base64(128).gsub(/[^0-9a-z ]/i, '').slice(1..8))
      a.save!

      UserMailer.password_reminder_destroy(r, password).deliver
    end
  end
end
