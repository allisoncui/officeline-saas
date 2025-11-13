require 'rails_helper'

RSpec.describe StudentsController, type: :controller do
  let(:student) { create(:user, role: 'student', uni: 'student123') }
  let(:ta) { create(:user, role: 'ta', uni: 'ta123') }

  describe 'GET #show' do
    before { sign_in student }

    it 'assigns saved office hours' do
      office_hour1 = create(:office_hour)
      office_hour2 = create(:office_hour)
      create(:enrollment, user: student, office_hour: office_hour1)
      
      get :show
      expect(assigns(:saved_office_hours)).to include(office_hour1)
      expect(assigns(:saved_office_hours)).not_to include(office_hour2)
    end

    it 'filters by days when provided' do
      monday_oh = create(:office_hour, day: 'Monday')
      tuesday_oh = create(:office_hour, day: 'Tuesday')
      create(:enrollment, user: student, office_hour: monday_oh)
      create(:enrollment, user: student, office_hour: tuesday_oh)
      
      get :show, params: { days: { 'Monday' => '1' } }
      expect(assigns(:saved_office_hours)).to include(monday_oh)
      expect(assigns(:saved_office_hours)).not_to include(tuesday_oh)
    end

    it 'stores filter preferences in session' do
      get :show, params: { days: { 'Monday' => '1', 'Tuesday' => '1' } }
      expect(session[:my_classes_days]).to include('Monday', 'Tuesday')
    end

    it 'sorts by course_name by default' do
      oh1 = create(:office_hour, course_name: 'Zebra')
      oh2 = create(:office_hour, course_name: 'Alpha')
      create(:enrollment, user: student, office_hour: oh1)
      create(:enrollment, user: student, office_hour: oh2)
      
      get :show
      expect(assigns(:sort_by)).to eq('course_name')
    end

    it 'stores sort preference in session' do
      get :show, params: { sort_by: 'instructor' }
      expect(session[:my_classes_sort_by]).to eq('instructor')
    end

    it 'handles ActionController::Parameters for days' do
      monday_oh = create(:office_hour, day: 'Monday')
      create(:enrollment, user: student, office_hour: monday_oh)
      
      # Use a hash that will be converted to ActionController::Parameters
      get :show, params: { days: { 'Monday' => '1', 'Tuesday' => '1' } }
      expect(assigns(:saved_office_hours)).to include(monday_oh)
    end

    it 'executes raw_days.keys when days is ActionController::Parameters' do
      # This tests line 9-10: raw_days = raw_days.keys if raw_days.is_a?(ActionController::Parameters)
      monday_oh = create(:office_hour, day: 'Monday')
      create(:enrollment, user: student, office_hour: monday_oh)
      # Use a hash that Rails will convert to ActionController::Parameters
      get :show, params: { days: { 'Monday' => '1' } }
      expect(assigns(:saved_office_hours)).to include(monday_oh)
    end

    it 'executes raw_days.keys when days is a Hash' do
      # This tests line 10: raw_days.is_a?(Hash)
      monday_oh = create(:office_hour, day: 'Monday')
      create(:enrollment, user: student, office_hour: monday_oh)
      hash_days = { 'Monday' => '1' }
      get :show, params: { days: hash_days }
      expect(assigns(:saved_office_hours)).to include(monday_oh)
    end

    it 'executes where(id: base_office_hours.pluck(:id)) line' do
      # This tests line 31-32: .where(id: base_office_hours.pluck(:id))
      oh1 = create(:office_hour, day: 'Monday')
      oh2 = create(:office_hour, day: 'Tuesday')
      create(:enrollment, user: student, office_hour: oh1)
      # Don't enroll in oh2
      
      get :show
      # Should only include oh1, not oh2
      expect(assigns(:saved_office_hours)).to include(oh1)
      expect(assigns(:saved_office_hours)).not_to include(oh2)
    end

    it 'renders the show template' do
      get :show
      expect(response).to render_template('show')
    end
  end

  describe 'GET #questions' do
    before { sign_in student }

    it 'assigns questions grouped by office hour' do
      office_hour1 = create(:office_hour)
      office_hour2 = create(:office_hour)
      question1 = create(:question, user: student, office_hour: office_hour1)
      question2 = create(:question, user: student, office_hour: office_hour1)
      question3 = create(:question, user: student, office_hour: office_hour2)
      
      get :questions
      expect(assigns(:my_questions)).to have_key(office_hour1)
      expect(assigns(:my_questions)).to have_key(office_hour2)
      expect(assigns(:my_questions)[office_hour1]).to include(question1, question2)
      expect(assigns(:my_questions)[office_hour2]).to include(question3)
    end

    it 'orders questions by created_at desc' do
      office_hour = create(:office_hour)
      question1 = create(:question, user: student, office_hour: office_hour, created_at: 1.day.ago)
      question2 = create(:question, user: student, office_hour: office_hour, created_at: 2.days.ago)
      
      get :questions
      questions = assigns(:my_questions)[office_hour]
      expect(questions).to eq([question1, question2])
    end

    it 'renders the questions template' do
      get :questions
      expect(response).to render_template('questions')
    end

    it 'handles empty questions list' do
      get :questions
      expect(assigns(:my_questions)).to be_empty
    end
  end

  describe 'authorization' do
    it 'redirects TAs to office hours index' do
      sign_in ta
      get :show
      expect(response).to redirect_to(office_hours_path)
      expect(flash[:alert]).to match(/students only/i)
    end

    it 'redirects TAs from questions page' do
      sign_in ta
      get :questions
      expect(response).to redirect_to(office_hours_path)
      expect(flash[:alert]).to match(/students only/i)
    end
  end
end

