require 'rails_helper'

RSpec.describe Users::PasswordsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe 'POST #create' do
    let!(:user) { create(:user, uni: 'test123', role: 'student') }

    context 'with valid UNI' do
      it 'sends reset instructions' do
        expect_any_instance_of(User).to receive(:send_reset_password_instructions)
        post :create, params: { user: { uni: 'test123' } }
      end

      it 'sets email to uni@columbia.edu if user responds to email=' do
        allow_any_instance_of(User).to receive(:send_reset_password_instructions)
        if User.instance_methods.include?(:email=)
          expect_any_instance_of(User).to receive(:email=).with('test123@columbia.edu')
        end
        post :create, params: { user: { uni: 'test123' } }
      end

      it 'redirects with success notice' do
        post :create, params: { user: { uni: 'test123' } }
        expect(flash[:notice]).to match(/password reset instructions/i)
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'includes email in success message' do
        post :create, params: { user: { uni: 'test123' } }
        expect(flash[:notice]).to include('test123@columbia.edu')
      end
    end

    context 'when reset instructions fail to send' do
      it 'redirects with error alert' do
        allow_any_instance_of(User).to receive(:send_reset_password_instructions)
        allow(controller).to receive(:successfully_sent?).and_return(false)
        post :create, params: { user: { uni: 'test123' } }
        expect(flash[:alert]).to match(/unable to send/i)
        expect(response).to redirect_to(new_user_password_path)
      end
    end

    context 'with invalid UNI' do
      it 'redirects with alert' do
        post :create, params: { user: { uni: 'nonexistent' } }
        expect(flash[:alert]).to eq("No user found with that UNI.")
        expect(response).to redirect_to(new_user_password_path)
      end
    end

    context 'with blank UNI' do
      it 'redirects with alert' do
        post :create, params: { user: { uni: '' } }
        expect(flash[:alert]).to match(/enter your uni/i)
        expect(response).to redirect_to(new_user_password_path)
      end
    end

    context 'with nil UNI' do
      it 'redirects with alert' do
        post :create, params: { user: { uni: nil } }
        expect(flash[:alert]).to match(/enter your uni/i)
        expect(response).to redirect_to(new_user_password_path)
      end
    end
  end

  describe 'private methods' do
    describe '#resource_params' do
      it 'permits uni parameter' do
        controller.params = ActionController::Parameters.new(user: { uni: 'test123' })
        result = controller.send(:resource_params)
        expect(result['uni']).to eq('test123')
        expect(result).to be_permitted
      end
    end
  end
end