require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe 'GET #new' do
    context 'with no UNI parameter' do
      it 'renders the normal sign in page' do
        get :new
        expect(response).to render_template(:new)
      end
    end

    context 'with UNI that has multiple accounts' do
      let!(:student) { create(:user, uni: 'test123', role: 'student') }
      let!(:ta) { create(:user, uni: 'test123', role: 'ta', course_name: 'CS 101') }

      it 'assigns available accounts' do
        get :new, params: { uni: 'test123' }
        expect(assigns(:available_accounts).count).to eq(2)
      end

      it 'assigns the uni' do
        get :new, params: { uni: 'test123' }
        expect(assigns(:uni)).to eq('test123')
      end
    end

    context 'with UNI that has single account' do
      let!(:student) { create(:user, uni: 'test456', role: 'student') }

      it 'sets default role' do
        get :new, params: { uni: 'test456' }
        expect(assigns(:default_role)).to eq('student')
      end
    end

    context 'with UNI that has no accounts' do
      it 'shows alert' do
        get :new, params: { uni: 'nonexistent' }
        expect(flash.now[:alert]).to match(/no account found/i)
      end
    end
  end

  describe 'POST #create' do
    let!(:user) { create(:user, uni: 'test123', role: 'student', password: 'password123') }

    context 'with valid credentials' do
      it 'signs in the user' do
        post :create, params: { user: { uni: 'test123', password: 'password123', role: 'student' } }
        expect(controller.current_user).to eq(user)
      end

      it 'redirects after sign in' do
        post :create, params: { user: { uni: 'test123', password: 'password123', role: 'student' } }
        expect(response).to redirect_to(root_path)
      end
    end

    context 'with invalid password' do
      it 'redirects with alert' do
        post :create, params: { user: { uni: 'test123', password: 'wrong', role: 'student' } }
        expect(flash[:alert]).to match(/invalid password/i)
      end
    end

    context 'with non-existent account' do
      it 'redirects with alert' do
        post :create, params: { user: { uni: 'test123', password: 'password123', role: 'ta' } }
        expect(flash[:alert]).to eq("No ta found for this UNI.")
      end
    end

    context 'with blank password' do
      it 'redirects with alert' do
        post :create, params: { user: { uni: 'test123', password: '', role: 'student' } }
        expect(flash[:alert]).to match(/enter your password/i)
      end
    end

    context 'with blank user params' do
      it 'redirects with alert' do
        post :create, params: {}
        expect(flash[:alert]).to match(/provide login credentials/i)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:student) { create(:user, uni: 'test123', role: 'student', password: 'password123') }
    let!(:ta) { create(:user, uni: 'test123', role: 'ta', course_name: 'CS 101', password: 'password123') }

    context 'switching accounts' do
      before { sign_in student }

      it 'switches to the other account' do
        delete :destroy, params: { switch_to: 'ta' }
        expect(controller.current_user).to eq(ta)
      end

      it 'shows success message' do
        delete :destroy, params: { switch_to: 'ta' }
        expect(flash[:notice]).to match(/switched to ta account/i)
      end
    end

    context 'normal sign out' do
      before { sign_in student }

      it 'signs out the user' do
        delete :destroy
        expect(controller.current_user).to be_nil
      end
    end
  end
end