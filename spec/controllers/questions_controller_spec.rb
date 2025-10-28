require 'rails_helper'

RSpec.describe QuestionsController, type: :controller do
  let(:office_hour) { create(:office_hour) }
  let(:valid_attributes) { { question_text: 'How do I implement authentication?' } }
  let(:invalid_attributes) { { question_text: '' } }

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
        expect(flash[:notice]).to eq('Question submitted successfully!')
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
        expect(flash[:alert]).to eq('Failed to submit question. Please try again.')
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

    describe '#question_params' do
      it 'permits question_text' do
        controller.params = ActionController::Parameters.new(question: { question_text: 'test' })
        result = controller.send(:question_params)
        expect(result['question_text']).to eq('test')
        expect(result).to be_permitted
      end
    end
  end
end
