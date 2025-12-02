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

      it 'redirects with success notice' do
        post :create, params: { user: { uni: 'test123' } }
        expect(flash[:notice]).to match(/password reset instructions/i)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'with invalid UNI' do
      it 'redirects with alert' do
        post :create, params: { user: { uni: 'nonexistent' } }
        expect(flash[:alert]).to eq("No user found with that UNI.")
      end
    end

    context 'with blank UNI' do
      it 'redirects with alert' do
        post :create, params: { user: { uni: '' } }
        expect(flash[:alert]).to match(/enter your uni/i)
      end
    end
  end
end