class Users::PasswordsController < Devise::PasswordsController
  # POST /resource/password
  def create
    uni = params[resource_name][:uni]

    if uni.present?
      email = "#{uni}@columbia.edu"

      self.resource = resource_class.find_by(uni: uni)

      if resource
        resource.email = email if resource.respond_to?(:email=)
        resource.send_reset_password_instructions

        if successfully_sent?(resource)
          flash[:notice] = "Password reset instructions have been sent to #{email}."
          redirect_to new_session_path(resource_name)
        else
          flash[:alert] = "Unable to send reset instructions. Please try again."
          redirect_to new_user_password_path
        end
      else
        flash[:alert] = "No user found with that UNI."
        redirect_to new_user_password_path
      end
    else
      flash[:alert] = "Please enter your UNI."
      redirect_to new_user_password_path
    end
  end

  private

  def resource_params
    params.require(resource_name).permit(:uni)
  end
end
