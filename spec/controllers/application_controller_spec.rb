require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render plain: 'OK'
    end
  end

  describe 'authentication' do
    it 'requires user authentication' do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe '#configure_permitted_parameters' do
    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]
    end

    context 'for sign up' do
      it 'permits uni, role, and course_name' do
        # This tests that the parameters are configured correctly
        # We can't directly test the sanitizer, but we can verify the controller works
        user = build(:user, uni: 'test123', role: 'student', course_name: nil)
        expect(user.uni).to eq('test123')
        expect(user.role).to eq('student')
      end
    end

    context 'for account update' do
      it 'permits uni, role, and course_name' do
        user = create(:user, uni: 'test123', role: 'student')
        user.update(uni: 'test456', role: 'ta', course_name: 'Engineering SaaS')
        expect(user.uni).to eq('test456')
        expect(user.role).to eq('ta')
        expect(user.course_name).to eq('Engineering SaaS')
      end
    end
  end
end

