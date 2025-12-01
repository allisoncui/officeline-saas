class Users::SessionsController < Devise::SessionsController
  # GET /users/sign_in
  def new
    @uni = params[:uni]
    
    if @uni.present?
      @available_accounts = User.where(uni: @uni)
      
      if @available_accounts.count > 1
        # Multiple accounts - will show selector
        self.resource = resource_class.new
      elsif @available_accounts.count == 1
        # Single account - set default role
        @default_role = @available_accounts.first.role
        self.resource = resource_class.new
      else
        # No accounts found
        flash.now[:alert] = "No account found for UNI: #{@uni}"
        @available_accounts = nil
        super
        return
      end
    end
    
    super
  end

  # POST /users/sign_in
  def create
    # Handle the case where params[:user] might not exist
    if params[:user].blank?
      flash[:alert] = "Please provide login credentials."
      redirect_to new_user_session_path
      return
    end
    
    uni = params[:user][:uni]
    role = params[:user][:role]
    password = params[:user][:password]
    
    # If no password provided, redirect back
    if password.blank?
      flash[:alert] = "Please enter your password."
      redirect_to new_user_session_path(uni: uni)
      return
    end
    
    # Find the user account
    self.resource = User.find_by(uni: uni, role: role)

    if resource.nil?
      flash[:alert] = "No #{role || 'account'} found for this UNI."
      redirect_to new_user_session_path(uni: uni)
      return
    end

    if resource.valid_password?(password)
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      flash[:alert] = "Invalid password."
      redirect_to new_user_session_path(uni: uni)
    end
  end

  # DELETE /users/sign_out
  def destroy
    switch_to_role = params[:switch_to]
    current_uni = current_user&.uni
    
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    
    if switch_to_role.present? && current_uni.present?
      other_account = User.find_by(uni: current_uni, role: switch_to_role)
      if other_account
        sign_in(other_account)
        flash[:notice] = "Switched to #{switch_to_role} account"
        redirect_to after_sign_in_path_for(other_account)
        return
      end
    end
    
    set_flash_message! :notice, :signed_out if signed_out
    respond_to_on_destroy
  end

  private

  def sign_in_params
    if params[:user].present?
      params.require(:user).permit(:uni, :password, :remember_me, :role)
    else
      {}
    end
  end
end