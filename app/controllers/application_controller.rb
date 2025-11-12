class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:uni, :role, :course_name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:uni, :role, :course_name])
  end
end
