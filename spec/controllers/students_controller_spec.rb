require 'rails_helper'

RSpec.describe StudentsController, type: :controller do
  let(:student) { create(:user, role: 'student', uni: 'student123') }
  let(:ta) { create(:user, role: 'ta', uni: 'ta123', course_name: 'Engineering SaaS') }

  describe 'GET #show' do
    before { sign_in student }

    it 'assigns saved classes with office hours' do
      student.update(saved_classes: ['Engineering SaaS'])
      oh1 = create(:office_hour, course_name: 'Engineering SaaS')
      oh2 = create(:office_hour, course_name: 'Engineering SaaS')
      oh3 = create(:office_hour, course_name: 'Math 101')
      
      get :show
      expect(assigns(:saved_class_names)).to include('Engineering SaaS')
      expect(assigns(:classes_with_office_hours)).to have_key('Engineering SaaS')
      expect(assigns(:classes_with_office_hours)['Engineering SaaS']).to include(oh1, oh2)
      expect(assigns(:classes_with_office_hours)).not_to have_key('Math 101')
    end

    it 'orders office hours by day and start_time' do
      student.update(saved_classes: ['Engineering SaaS'])
      oh1 = create(:office_hour, course_name: 'Engineering SaaS', day: 'Tuesday', start_time: '2:00PM')
      oh2 = create(:office_hour, course_name: 'Engineering SaaS', day: 'Monday', start_time: '1:00PM')
      oh3 = create(:office_hour, course_name: 'Engineering SaaS', day: 'Monday', start_time: '10:00AM')
      
      get :show
      office_hours = assigns(:classes_with_office_hours)['Engineering SaaS']
      expect(office_hours).to eq([oh3, oh2, oh1])
    end

    it 'renders the show template' do
      get :show
      expect(response).to render_template('show')
    end

    it 'handles empty saved classes' do
      student.update(saved_classes: [])
      get :show
      expect(assigns(:saved_class_names)).to be_empty
      expect(assigns(:classes_with_office_hours)).to be_empty
    end
  end

  describe 'GET #my_hours' do
    before { sign_in student }

    it 'assigns selected office hours (enrollments)' do
      oh1 = create(:office_hour)
      oh2 = create(:office_hour)
      create(:enrollment, user: student, office_hour: oh1)
      # Don't enroll in oh2
      
      get :my_hours
      expect(assigns(:my_office_hours)).to include(oh1)
      expect(assigns(:my_office_hours)).not_to include(oh2)
    end

    it 'filters by days when provided' do
      monday_oh = create(:office_hour, day: 'Monday')
      tuesday_oh = create(:office_hour, day: 'Tuesday')
      create(:enrollment, user: student, office_hour: monday_oh)
      create(:enrollment, user: student, office_hour: tuesday_oh)
      
      get :my_hours, params: { days: { 'Monday' => '1' } }
      expect(assigns(:my_office_hours)).to include(monday_oh)
      expect(assigns(:my_office_hours)).not_to include(tuesday_oh)
    end

    it 'stores filter preferences in session' do
      get :my_hours, params: { days: { 'Monday' => '1', 'Tuesday' => '1' } }
      expect(session[:my_hours_days]).to include('Monday', 'Tuesday')
    end

    it 'sorts by course_name by default' do
      oh1 = create(:office_hour, course_name: 'Zebra')
      oh2 = create(:office_hour, course_name: 'Alpha')
      create(:enrollment, user: student, office_hour: oh1)
      create(:enrollment, user: student, office_hour: oh2)
      
      get :my_hours
      expect(assigns(:sort_by)).to eq('course_name')
    end

    it 'stores sort preference in session' do
      get :my_hours, params: { sort_by: 'instructor' }
      expect(session[:my_hours_sort_by]).to eq('instructor')
    end

    it 'handles ActionController::Parameters for days' do
      monday_oh = create(:office_hour, day: 'Monday')
      create(:enrollment, user: student, office_hour: monday_oh)
      
      get :my_hours, params: { days: { 'Monday' => '1', 'Tuesday' => '1' } }
      expect(assigns(:my_office_hours)).to include(monday_oh)
    end

    it 'renders the my_hours template' do
      get :my_hours
      expect(response).to render_template('my_hours')
    end

    it 'handles empty office hours' do
      get :my_hours
      expect(assigns(:my_office_hours)).to be_empty
    end

    it 'shows all office hours for selected days when student has no saved hours' do
      monday_oh = create(:office_hour, day: 'Monday')
      tuesday_oh = create(:office_hour, day: 'Tuesday')
      
      get :my_hours, params: { days: { 'Monday' => '1' } }
      expect(assigns(:my_office_hours)).to include(monday_oh)
      expect(assigns(:my_office_hours)).not_to include(tuesday_oh)
    end

    it 'sorts by instructor when sort_by is instructor' do
      oh1 = create(:office_hour, instructor: 'Zebra', course_name: 'Math')
      oh2 = create(:office_hour, instructor: 'Alpha', course_name: 'Math')
      create(:enrollment, user: student, office_hour: oh1)
      create(:enrollment, user: student, office_hour: oh2)
      
      get :my_hours, params: { sort_by: 'instructor' }
      expect(assigns(:my_office_hours).first).to eq(oh2)
      expect(assigns(:my_office_hours).last).to eq(oh1)
    end

    it 'sorts by day when sort_by is day' do
      oh1 = create(:office_hour, day: 'Wednesday', start_time: '2:00PM')
      oh2 = create(:office_hour, day: 'Monday', start_time: '1:00PM')
      oh3 = create(:office_hour, day: 'Monday', start_time: '10:00AM')
      create(:enrollment, user: student, office_hour: oh1)
      create(:enrollment, user: student, office_hour: oh2)
      create(:enrollment, user: student, office_hour: oh3)
      
      get :my_hours, params: { sort_by: 'day' }
      sorted = assigns(:my_office_hours)
      expect(sorted.first).to eq(oh3)
      expect(sorted[1]).to eq(oh2)
      expect(sorted.last).to eq(oh1)
    end

    it 'uses session days when no params provided' do
      session[:my_hours_days] = ['Monday']
      monday_oh = create(:office_hour, day: 'Monday')
      tuesday_oh = create(:office_hour, day: 'Tuesday')
      create(:enrollment, user: student, office_hour: monday_oh)
      create(:enrollment, user: student, office_hour: tuesday_oh)
      
      get :my_hours
      expect(assigns(:my_office_hours)).to include(monday_oh)
      expect(assigns(:my_office_hours)).not_to include(tuesday_oh)
    end

    it 'uses session sort_by when no params provided' do
      session[:my_hours_sort_by] = 'instructor'
      get :my_hours
      expect(assigns(:sort_by)).to eq('instructor')
    end

    it 'handles case when saved_scope does not exist' do
      # No enrollments, so saved_scope.exists? will be false
      monday_oh = create(:office_hour, day: 'Monday')
      
      get :my_hours
      expect(assigns(:my_office_hours)).to include(monday_oh)
    end
  end

  describe 'POST #save_class' do
    before { sign_in student }

    it 'adds course to saved_classes' do
      expect {
        post :save_class, params: { course_name: 'Engineering SaaS' }
      }.to change { student.reload.saved_classes }.from([]).to(['Engineering SaaS'])
    end

    it 'redirects with success notice' do
      post :save_class, params: { course_name: 'Engineering SaaS' }
      expect(response).to redirect_to(office_hours_path)
      expect(flash[:notice]).to match(/saved to My Classes/i)
    end

    it 'handles empty course_name' do
      post :save_class, params: { course_name: '' }
      expect(response).to redirect_to(office_hours_path)
      expect(flash[:alert]).to match(/could not save/i)
    end

    it 'handles nil course_name' do
      post :save_class, params: {}
      expect(response).to redirect_to(office_hours_path)
      expect(flash[:alert]).to match(/could not save/i)
    end
  end

  describe 'DELETE #remove_class' do
    before { sign_in student }

    it 'removes course from saved_classes' do
      student.update(saved_classes: ['Engineering SaaS', 'Math 101'])
      expect {
        delete :remove_class, params: { course_name: 'Engineering SaaS' }
      }.to change { student.reload.saved_classes }.from(['Engineering SaaS', 'Math 101']).to(['Math 101'])
    end

    it 'redirects with success notice' do
      student.update(saved_classes: ['Engineering SaaS'])
      delete :remove_class, params: { course_name: 'Engineering SaaS' }
      expect(response).to redirect_to(student_profile_path)
      expect(flash[:notice]).to match(/removed from My Classes/i)
    end

    it 'handles empty course_name' do
      delete :remove_class, params: { course_name: '' }
      expect(response).to redirect_to(student_profile_path)
      expect(flash[:alert]).to match(/could not remove/i)
    end

    it 'handles nil course_name' do
      delete :remove_class, params: {}
      expect(response).to redirect_to(student_profile_path)
      expect(flash[:alert]).to match(/could not remove/i)
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

    it 'filters questions by question type when provided' do
      office_hour = create(:office_hour)
      homework_question = create(:question, user: student, office_hour: office_hour, question_type: 'homework')
      exam_question = create(:question, user: student, office_hour: office_hour, question_type: 'exam')
      
      get :questions, params: { question_type: 'homework' }
      questions = assigns(:my_questions)[office_hour]
      expect(questions).to include(homework_question)
      expect(questions).not_to include(exam_question)
    end

    it 'shows all questions when "all" is selected' do
      office_hour = create(:office_hour)
      homework_question = create(:question, user: student, office_hour: office_hour, question_type: 'homework')
      exam_question = create(:question, user: student, office_hour: office_hour, question_type: 'exam')
      
      get :questions, params: { question_type: 'all' }
      questions = assigns(:my_questions)[office_hour]
      expect(questions).to include(homework_question, exam_question)
      expect(assigns(:selected_question_type)).to eq('all')
    end

    it 'defaults to "all" when no filter is provided' do
      office_hour = create(:office_hour)
      create(:question, user: student, office_hour: office_hour, question_type: 'homework')
      create(:question, user: student, office_hour: office_hour, question_type: 'exam')
      
      get :questions
      expect(assigns(:selected_question_type)).to eq('all')
      expect(assigns(:my_questions)[office_hour].count).to eq(2)
    end

    it 'stores filter preference in session' do
      get :questions, params: { question_type: 'homework' }
      expect(session[:my_questions_type]).to eq('homework')
    end

    it 'clears session when "all" is selected' do
      session[:my_questions_type] = 'homework'
      get :questions, params: { question_type: 'all' }
      expect(session[:my_questions_type]).to be_nil
    end

    it 'uses session value when no params provided' do
      session[:my_questions_type] = 'exam'
      office_hour = create(:office_hour)
      homework_question = create(:question, user: student, office_hour: office_hour, question_type: 'homework')
      exam_question = create(:question, user: student, office_hour: office_hour, question_type: 'exam')
      
      get :questions
      questions = assigns(:my_questions)[office_hour]
      expect(questions).to include(exam_question)
      expect(questions).not_to include(homework_question)
      expect(assigns(:selected_question_type)).to eq('exam')
    end
  end

  describe 'authorization' do
    it 'redirects TAs to office hours index from show' do
      sign_in ta
      get :show
      expect(response).to redirect_to(office_hours_path)
      expect(flash[:alert]).to match(/students only/i)
    end

    it 'redirects TAs from my_hours page' do
      sign_in ta
      get :my_hours
      expect(response).to redirect_to(office_hours_path)
      expect(flash[:alert]).to match(/students only/i)
    end

    it 'redirects TAs from save_class' do
      sign_in ta
      post :save_class, params: { course_name: 'Engineering SaaS' }
      expect(response).to redirect_to(office_hours_path)
      expect(flash[:alert]).to match(/students only/i)
    end

    it 'redirects TAs from remove_class' do
      sign_in ta
      delete :remove_class, params: { course_name: 'Engineering SaaS' }
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

  describe 'POST #save_class' do
    before { sign_in student }

    it 'saves a class to the student profile' do
      post :save_class, params: { course_name: 'Engineering SaaS' }
      student.reload
      expect(student.saved_classes).to include('Engineering SaaS')
    end

    it 'redirects with success notice' do
      post :save_class, params: { course_name: 'Engineering SaaS' }
      expect(response).to redirect_to(office_hours_path)
      expect(flash[:notice]).to match(/saved to My Classes/i)
    end

    it 'handles missing course_name' do
      post :save_class, params: { course_name: '' }
      expect(response).to redirect_to(office_hours_path)
      expect(flash[:alert]).to match(/Could not save/i)
    end
  end

  describe 'DELETE #remove_class' do
    before do
      sign_in student
      student.update(saved_classes: ['Engineering SaaS', 'Math 101'])
    end

    it 'removes a class from the student profile' do
      delete :remove_class, params: { course_name: 'Engineering SaaS' }
      student.reload
      expect(student.saved_classes).not_to include('Engineering SaaS')
      expect(student.saved_classes).to include('Math 101')
    end

    it 'redirects with success notice' do
      delete :remove_class, params: { course_name: 'Engineering SaaS' }
      expect(response).to redirect_to(student_profile_path)
      expect(flash[:notice]).to match(/removed from My Classes/i)
    end

    it 'handles missing course_name' do
      delete :remove_class, params: { course_name: '' }
      expect(response).to redirect_to(student_profile_path)
      expect(flash[:alert]).to match(/Could not remove/i)
    end
  end
end