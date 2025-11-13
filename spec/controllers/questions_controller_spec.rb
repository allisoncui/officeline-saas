require 'rails_helper'

RSpec.describe QuestionsController, type: :controller do
  let(:user) { create(:user, uni: 'test123', role: 'student') }
  let(:office_hour) { create(:office_hour) }
  let(:valid_attributes) { { question_text: 'How do I implement authentication?' } }
  let(:invalid_attributes) { { question_text: '' } }
  
  before :each do
    sign_in user
  end

  describe 'GET #index' do
    it 'assigns the office hour' do
      get :index, params: { office_hour_id: office_hour.id }
      expect(assigns(:office_hour)).to eq(office_hour)
    end

    it 'assigns questions for the office hour' do
      question1 = create(:question, office_hour: office_hour)
      question2 = create(:question, office_hour: office_hour)
      
      get :index, params: { office_hour_id: office_hour.id }
      expect(assigns(:questions)).to match_array([question1, question2])
    end

    it 'orders questions by created_at desc' do
      question1 = create(:question, office_hour: office_hour, created_at: 1.day.ago)
      question2 = create(:question, office_hour: office_hour, created_at: 2.days.ago)
      
      get :index, params: { office_hour_id: office_hour.id }
      expect(assigns(:questions)).to eq([question1, question2])
    end

    it 'redirects to the office hour' do
      get :index, params: { office_hour_id: office_hour.id }
      expect(response).to redirect_to(office_hour)
    end
  end

  describe 'POST #create' do
    context 'with valid attributes' do
      it 'creates a new question' do
        expect {
          post :create, params: { office_hour_id: office_hour.id, question: valid_attributes }
        }.to change(Question, :count).by(1)
      end

      it 'assigns the correct office hour' do
        post :create, params: { office_hour_id: office_hour.id, question: valid_attributes }
        expect(assigns(:question).office_hour).to eq(office_hour)
      end

      it 'redirects to the office hour' do
        post :create, params: { office_hour_id: office_hour.id, question: valid_attributes }
        expect(response).to redirect_to(office_hour)
      end

      it 'sets a success notice' do
        post :create, params: { office_hour_id: office_hour.id, question: valid_attributes }
        expect(flash[:notice]).to match(/successfully/i)
      end
    end

    context 'with invalid attributes' do
      it 'does not create a new question' do
        expect {
          post :create, params: { office_hour_id: office_hour.id, question: invalid_attributes }
        }.not_to change(Question, :count)
      end

      it 'redirects to the office hour' do
        post :create, params: { office_hour_id: office_hour.id, question: invalid_attributes }
        expect(response).to redirect_to(office_hour)
      end

      it 'sets an error alert' do
        post :create, params: { office_hour_id: office_hour.id, question: invalid_attributes }
        expect(flash[:alert]).to match(/failed|error/i)
      end
    end
  end

  describe 'GET #edit' do
    let(:question) { create(:question, office_hour: office_hour, user: user) }

    it 'assigns the question' do
      get :edit, params: { office_hour_id: office_hour.id, id: question.id }
      expect(assigns(:question)).to eq(question)
    end

    it 'renders the edit template' do
      get :edit, params: { office_hour_id: office_hour.id, id: question.id }
      expect(response).to render_template('edit')
    end

    context 'when question belongs to another user' do
      let(:other_user) { create(:user) }
      let(:other_question) { create(:question, office_hour: office_hour, user: other_user) }

      it 'redirects with alert' do
        get :edit, params: { office_hour_id: office_hour.id, id: other_question.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/only edit or delete your own/i)
      end
    end
  end

  describe 'PATCH #update' do
    let(:question) { create(:question, office_hour: office_hour, user: user, question_text: 'Original') }

    context 'with valid attributes' do
      it 'updates the question' do
        patch :update, params: {
          office_hour_id: office_hour.id,
          id: question.id,
          question: { question_text: 'Updated question' }
        }
        question.reload
        expect(question.question_text).to eq('Updated question')
      end

      it 'redirects to office hour with success notice' do
        patch :update, params: {
          office_hour_id: office_hour.id,
          id: question.id,
          question: { question_text: 'Updated question' }
        }
        expect(response).to redirect_to(office_hour)
        expect(flash[:notice]).to match(/updated successfully/i)
      end
    end

    context 'with invalid attributes' do
      it 'does not update the question' do
        original_text = question.question_text
        patch :update, params: {
          office_hour_id: office_hour.id,
          id: question.id,
          question: { question_text: '' }
        }
        question.reload
        expect(question.question_text).to eq(original_text)
      end

      it 're-renders edit template' do
        patch :update, params: {
          office_hour_id: office_hour.id,
          id: question.id,
          question: { question_text: '' }
        }
        expect(response).to render_template('edit')
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns unprocessable_entity status on validation failure' do
        patch :update, params: {
          office_hour_id: office_hour.id,
          id: question.id,
          question: { question_text: '' }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when question belongs to another user' do
      let(:other_user) { create(:user) }
      let(:other_question) { create(:question, office_hour: office_hour, user: other_user) }

      it 'redirects with alert' do
        patch :update, params: {
          office_hour_id: office_hour.id,
          id: other_question.id,
          question: { question_text: 'Hacked' }
        }
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/only edit or delete your own/i)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:question) { create(:question, office_hour: office_hour, user: user) }

    it 'destroys the question' do
      expect {
        delete :destroy, params: { office_hour_id: office_hour.id, id: question.id }
      }.to change(Question, :count).by(-1)
    end

    it 'redirects to office hour with success notice' do
      delete :destroy, params: { office_hour_id: office_hour.id, id: question.id }
      expect(response).to redirect_to(office_hour)
      expect(flash[:notice]).to match(/deleted successfully/i)
    end

    context 'when question belongs to another user' do
      let(:other_user) { create(:user) }
      let!(:other_question) { create(:question, office_hour: office_hour, user: other_user) }

      it 'redirects with alert' do
        delete :destroy, params: { office_hour_id: office_hour.id, id: other_question.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/only edit or delete your own/i)
      end
    end
  end

  describe 'private methods' do
    describe '#set_office_hour' do
      it 'finds the correct office hour' do
        get :index, params: { office_hour_id: office_hour.id }
        expect(assigns(:office_hour)).to eq(office_hour)
      end
    end

    describe '#set_question' do
      let(:question) { create(:question, office_hour: office_hour, user: user) }

      it 'finds the correct question' do
        get :edit, params: { office_hour_id: office_hour.id, id: question.id }
        expect(assigns(:question)).to eq(question)
      end
    end

    describe '#question_params' do
      it 'permits question_text' do
        controller.params = ActionController::Parameters.new(question: { question_text: 'test' })
        result = controller.send(:question_params)
        expect(result['question_text']).to eq('test')
        expect(result).to be_permitted
      end
    end

    describe '#ensure_question_owner' do
      let(:other_user) { create(:user) }
      let(:other_question) { create(:question, office_hour: office_hour, user: other_user) }

      it 'redirects when trying to update another user\'s question' do
        patch :update, params: {
          office_hour_id: office_hour.id,
          id: other_question.id,
          question: { question_text: 'Hacked' }
        }
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/only edit or delete your own/i)
      end

      it 'redirects when trying to delete another user\'s question' do
        delete :destroy, params: { office_hour_id: office_hour.id, id: other_question.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/only edit or delete your own/i)
      end
    end
  end
end
