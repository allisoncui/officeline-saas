class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]

  # GET /resource/sign_up
  def new
    @role = params[:role] || 'student'
    super
  end

  # POST /resource
  def create
    # Store the role before calling super
    @role = sign_up_params[:role] || 'student'
    super
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:uni, :role, :course_name])
  end

  # Override to preserve role on validation failure
  def after_sign_up_path_for(resource)
    super(resource)
  end

  # Override to preserve role on validation failure
  def after_inactive_sign_up_path_for(resource)
    super(resource)
  end
end