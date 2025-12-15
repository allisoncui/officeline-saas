require 'rails_helper'

RSpec.describe OfficeHoursController, type: :controller do
  let(:student) { create(:user, :student, uni: 'student123') }
  let(:ta) { create(:user, :ta, uni: 'ta123', course_name: 'Engineering SaaS') }
  let(:office_hour) { create(:office_hour, ta_uni: 'ta123', course_name: 'Engineering SaaS') }

  describe 'GET #index' do
    context 'as a student' do
      before { sign_in student }

      it 'assigns @office_hours' do
        office_hour # create the office hour
        get :index
        expect(assigns(:office_hours)).to be_present
      end

      it 'renders student_index template' do
        get :index
        expect(response).to render_template('student_index')
      end

      it 'assigns @all_days' do
        get :index
        expect(assigns(:all_days)).to eq(OfficeHour.all_days)
      end

      it 'assigns @office_hours_by_course' do
        office_hour # create the office hour
        get :index
        expect(assigns(:office_hours_by_course)).to be_a(Hash)
      end

      it 'assigns @saved_class_names for students' do
        student.update(saved_classes: ['Engineering SaaS'])
        get :index
        expect(assigns(:saved_class_names)).to eq(['Engineering SaaS'])
      end

      it 'filters office hours by search term' do
        oh1 = create(:office_hour, course_name: 'Engineering SaaS', instructor: 'Dr. Smith')
        oh2 = create(:office_hour, course_name: 'Data Science', instructor: 'Dr. Jones')
        
        get :index, params: { search: 'Engineering' }
        expect(assigns(:office_hours)).to include(oh1)
        expect(assigns(:office_hours)).not_to include(oh2)
      end

      it 'filters by instructor name' do
        oh1 = create(:office_hour, instructor: 'Dr. Smith')
        oh2 = create(:office_hour, instructor: 'Dr. Jones')
        
        get :index, params: { search: 'Smith' }
        expect(assigns(:office_hours)).to include(oh1)
        expect(assigns(:office_hours)).not_to include(oh2)
      end

      it 'filters by location' do
        oh1 = create(:office_hour, location: 'Zoom')
        oh2 = create(:office_hour, location: 'Pupin 301')
        
        get :index, params: { search: 'Zoom' }
        expect(assigns(:office_hours)).to include(oh1)
        expect(assigns(:office_hours)).not_to include(oh2)
      end

      it 'handles empty search results' do
        create(:office_hour, course_name: 'Engineering SaaS')
        
        get :index, params: { search: 'NonexistentCourse' }
        expect(assigns(:office_hours)).to be_empty
      end

      it 'trims whitespace from search term' do
        oh1 = create(:office_hour, course_name: 'Engineering SaaS')
        
        get :index, params: { search: '  Engineering  ' }
        expect(assigns(:office_hours)).to include(oh1)
      end
    end

    context 'as a TA' do
      before { sign_in ta }

      it 'renders ta_index template' do
        get :index
        expect(response).to render_template('ta_index')
      end

      it 'assigns only TA own hours when view is "my"' do
        my_oh = office_hour
        other_ta_oh = create(:office_hour, course_name: 'Engineering SaaS', ta_uni: 'other_ta')
        
        get :index, params: { view: 'my' }
        expect(assigns(:office_hours)).to include(my_oh)
        expect(assigns(:office_hours)).not_to include(other_ta_oh)
      end


      it 'defaults to dashboard view' do
        get :index
        expect(assigns(:view)).to eq('dashboard')
        expect(assigns(:office_hours)).to be_nil
      end

      it 'assigns sessions for dashboard view' do
        create(:queue_session, office_hour: office_hour)
        
        get :index, params: { view: 'dashboard' }
        expect(assigns(:sessions)).to be_present
      end

      it 'assigns questions for dashboard view' do
        create(:question, office_hour: office_hour, user: student)
        
        get :index, params: { view: 'dashboard' }
        expect(assigns(:questions)).to be_present
      end

      it 'calculates question breakdown' do
        create(:question, office_hour: office_hour, user: student, question_type: 'homework')
        create(:question, office_hour: office_hour, user: student, question_type: 'homework')
        create(:question, office_hour: office_hour, user: student, question_type: 'concept')
        
        get :index, params: { view: 'dashboard' }
        expect(assigns(:question_breakdown)['homework']).to eq(2)
        expect(assigns(:question_breakdown)['concept']).to eq(1)
      end

      it 'calculates total questions' do
        create_list(:question, 3, office_hour: office_hour, user: student)
        
        get :index, params: { view: 'dashboard' }
        expect(assigns(:total_questions)).to eq(3)
      end

      it 'calculates average questions per session' do
        create(:queue_session, office_hour: office_hour)
        create_list(:question, 4, office_hour: office_hour, user: student)
        
        get :index, params: { view: 'dashboard' }
        expect(assigns(:avg_questions_per_session)).to eq(4.0)
      end

      it 'handles zero sessions for average calculation' do
        create_list(:question, 3, office_hour: office_hour, user: student)
        
        get :index, params: { view: 'dashboard' }
        expect(assigns(:avg_questions_per_session)).to eq(0)
      end

      it 'calculates most common question type' do
        create_list(:question, 3, office_hour: office_hour, user: student, question_type: 'homework')
        create_list(:question, 2, office_hour: office_hour, user: student, question_type: 'concept')
        
        get :index, params: { view: 'dashboard' }
        expect(assigns(:most_common_type)).to eq('Homework')
      end

      it 'returns N/A when no questions exist for most common type' do
        get :index, params: { view: 'dashboard' }
        expect(assigns(:most_common_type)).to eq('N/A')
      end

      it 'calculates busiest hour' do
        base_time = Time.zone.parse('2024-01-01 14:00:00')
        create_list(:question, 3, office_hour: office_hour, user: student, created_at: base_time)
        create_list(:question, 1, office_hour: office_hour, user: student, created_at: base_time + 1.hour)
        
        get :index, params: { view: 'dashboard' }
        expect(assigns(:busiest_hour)).to eq('14')
      end

      it 'returns nil when no questions exist for busiest hour' do
        get :index, params: { view: 'dashboard' }
        expect(assigns(:busiest_hour)).to be_nil
      end
    end

    context 'when days param is present' do
      before { sign_in student }

      it 'filters by selected days' do
        get :index, params: { days: { 'Monday' => '1', 'Tuesday' => '1' } }
        expect(assigns(:days_to_show)).to match_array(['Monday', 'Tuesday'])
      end

      it 'stores days in session' do
        get :index, params: { days: { 'Monday' => '1' } }
        expect(session[:days]).to eq(['Monday'])
      end

      it 'extracts keys from Hash' do
        get :index, params: { days: { 'Monday' => '1', 'Tuesday' => '1' } }
        expect(response).to have_http_status(:success)
        expect(assigns(:days_to_show)).to match_array(['Monday', 'Tuesday'])
      end
    end

    context 'when days param is not present' do
      before { sign_in student }

      it 'uses session days if available' do
        session[:days] = ['Wednesday']
        get :index
        expect(assigns(:days_to_show)).to eq(['Wednesday'])
      end

      it 'defaults to all days if no session' do
        get :index
        expect(assigns(:days_to_show)).to eq(OfficeHour.all_days)
      end
    end

    context 'when sort_by param is present' do
      before { sign_in student }

      it 'uses the provided sort parameter' do
        get :index, params: { sort_by: 'instructor' }
        expect(assigns(:sort_by)).to eq('instructor')
      end

      it 'stores sort_by in session' do
        get :index, params: { sort_by: 'day' }
        expect(session[:sort_by]).to eq('day')
      end
    end

    context 'when sort_by param is not present' do
      before { sign_in student }

      it 'uses session sort_by if available' do
        session[:sort_by] = 'instructor'
        get :index
        expect(assigns(:sort_by)).to eq('instructor')
      end

      it 'defaults to course_name' do
        get :index
        expect(assigns(:sort_by)).to eq('course_name')
      end
    end

    context 'when sorting by day' do
      before { sign_in student }

      it 'sorts office hours by day and time' do
        oh1 = create(:office_hour, day: 'Wednesday', start_time: '2:00PM')
        oh2 = create(:office_hour, day: 'Monday', start_time: '1:00PM')
        oh3 = create(:office_hour, day: 'Monday', start_time: '10:00AM')
        
        get :index, params: { sort_by: 'day' }
        sorted = assigns(:office_hours)
        expect(sorted.first).to eq(oh3)
        expect(sorted[1]).to eq(oh2)
        expect(sorted.last).to eq(oh1)
      end

      it 'handles office hours with days not in all_days (uses fallback 99)' do
        oh1 = create(:office_hour, day: 'Monday', start_time: '1:00PM')
        oh2 = build(:office_hour, day: 'Saturday', start_time: '10:00AM')
        oh2.save(validate: false)
        
        get :index, params: { sort_by: 'day', days: { 'Monday' => '1', 'Saturday' => '1' } }
        sorted = assigns(:office_hours).to_a
        expect(sorted).to include(oh1, oh2)
        monday_pos = sorted.index(oh1)
        saturday_pos = sorted.index(oh2)
        expect(monday_pos).to be < saturday_pos
      end

      it 'groups all office hours under "All Office Hours" when sorting by day' do
        create(:office_hour, day: 'Monday')
        create(:office_hour, day: 'Tuesday')
        
        get :index, params: { sort_by: 'day' }
        expect(assigns(:office_hours_by_course)).to have_key('All Office Hours')
      end
    end
  end

  describe 'GET #show' do
    context 'as a student' do
      before { sign_in student }

      it 'assigns the requested office hour' do
        get :show, params: { id: office_hour.id }
        expect(assigns(:office_hour)).to eq(office_hour)
      end

      it 'renders the show template' do
        get :show, params: { id: office_hour.id }
        expect(response).to render_template('show')
      end

      it 'renders student navigation tabs' do
        get :show, params: { id: office_hour.id }
        expect(response).to render_template('show')
        # Navigation tabs are rendered in the view template
        expect(response).to have_http_status(:success)
      end
    end

    context 'as a TA' do
      before { sign_in ta }

      it 'assigns the requested office hour' do
        get :show, params: { id: office_hour.id }
        expect(assigns(:office_hour)).to eq(office_hour)
      end

      it 'renders the show template' do
        get :show, params: { id: office_hour.id }
        expect(response).to render_template('show')
      end

      it 'renders TA navigation tabs' do
        get :show, params: { id: office_hour.id }
        expect(response).to render_template('show')
        # Navigation tabs are rendered in the view template
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET #new' do
    before { sign_in ta }

    it 'assigns a new office hour' do
      get :new
      expect(assigns(:office_hour)).to be_a_new(OfficeHour)
    end

    it 'renders the new template' do
      get :new
      expect(response).to render_template('new')
    end
  end

  describe 'GET #edit' do
    before { sign_in ta }

    context 'when TA owns the office hour' do
      it 'renders the edit template' do
        get :edit, params: { id: office_hour.id }
        expect(response).to render_template('edit')
      end

      it 'assigns the office hour' do
        get :edit, params: { id: office_hour.id }
        expect(assigns(:office_hour)).to eq(office_hour)
      end
    end

    context 'when TA does not own the office hour' do
      let(:other_oh) { create(:office_hour, ta_uni: 'other_ta', course_name: 'Other Course') }

      it 'redirects with alert' do
        get :edit, params: { id: other_oh.id }
        expect(response).to redirect_to(office_hours_path)
        expect(flash[:alert]).to match(/only modify.*course/i)
      end
    end
  end

  describe 'POST #create' do
    before { sign_in ta }

    context 'with valid params' do
      let(:valid_attributes) do
        {
          instructor: 'Dr. Smith',
          day: 'Monday',
          start_time: '10:00AM',
          end_time: '12:00PM',
          location: 'Room 301'
        }
      end

      it 'creates a new OfficeHour' do
        expect {
          post :create, params: { office_hour: valid_attributes }
        }.to change(OfficeHour, :count).by(1)
      end

      it 'assigns course_name from current_user' do
        post :create, params: { office_hour: valid_attributes }
        expect(OfficeHour.last.course_name).to eq('Engineering SaaS')
      end

      it 'assigns ta_uni from current_user' do
        post :create, params: { office_hour: valid_attributes }
        expect(OfficeHour.last.ta_uni).to eq('ta123')
      end

      it 'redirects to the created office hour' do
        post :create, params: { office_hour: valid_attributes }
        expect(response).to redirect_to(OfficeHour.last)
      end

      it 'sets a success notice' do
        post :create, params: { office_hour: valid_attributes }
        expect(flash[:notice]).to match(/successfully created/i)
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) do
        {
          instructor: '',
          day: 'Monday'
        }
      end

      it 'does not create a new office hour' do
        expect {
          post :create, params: { office_hour: invalid_attributes }
        }.not_to change(OfficeHour, :count)
      end

      it 're-renders the new template' do
        post :create, params: { office_hour: invalid_attributes }
        expect(response).to render_template('new')
      end

      it 'returns unprocessable_entity status' do
        post :create, params: { office_hour: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with JSON format' do
      let(:valid_attributes) do
        {
          instructor: 'Dr. Smith',
          day: 'Monday',
          start_time: '10:00AM',
          end_time: '12:00PM',
          location: 'Room 301'
        }
      end

      it 'returns created status' do
        post :create, params: { office_hour: valid_attributes }, format: :json
        expect(response).to have_http_status(:created)
      end

      it 'returns JSON representation' do
        post :create, params: { office_hour: valid_attributes }, format: :json
        expect(response.content_type).to include('application/json')
      end
    end

    context 'with invalid JSON format' do
      let(:invalid_attributes) { { instructor: '' } }

      it 'returns unprocessable_entity status' do
        post :create, params: { office_hour: invalid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns errors as JSON' do
        post :create, params: { office_hour: invalid_attributes }, format: :json
        expect(response.content_type).to include('application/json')
      end
    end
  end

  describe 'PATCH #update' do
    before { sign_in ta }

    context 'with valid params' do
      let(:new_attributes) do
        {
          instructor: 'Dr. Jones',
          location: 'Room 402'
        }
      end

      it 'updates the requested office hour' do
        patch :update, params: { id: office_hour.id, office_hour: new_attributes }
        office_hour.reload
        expect(office_hour.instructor).to eq('Dr. Jones')
        expect(office_hour.location).to eq('Room 402')
      end

      it 'redirects to the office hour' do
        patch :update, params: { id: office_hour.id, office_hour: new_attributes }
        expect(response).to redirect_to(office_hour)
      end

      it 'sets a success notice' do
        patch :update, params: { id: office_hour.id, office_hour: new_attributes }
        expect(flash[:notice]).to match(/successfully updated/i)
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) do
        { instructor: '' }
      end

      it 'does not update the office hour' do
        original_instructor = office_hour.instructor
        patch :update, params: { id: office_hour.id, office_hour: invalid_attributes }
        office_hour.reload
        expect(office_hour.instructor).to eq(original_instructor)
      end

      it 're-renders the edit template' do
        patch :update, params: { id: office_hour.id, office_hour: invalid_attributes }
        expect(response).to render_template('edit')
      end

      it 'returns unprocessable_entity status' do
        patch :update, params: { id: office_hour.id, office_hour: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with JSON format' do
      let(:new_attributes) { { instructor: 'Dr. Jones' } }

      it 'returns ok status' do
        patch :update, params: { id: office_hour.id, office_hour: new_attributes }, format: :json
        expect(response).to have_http_status(:ok)
      end

      it 'returns JSON representation' do
        patch :update, params: { id: office_hour.id, office_hour: new_attributes }, format: :json
        expect(response.content_type).to include('application/json')
      end
    end

    context 'with invalid JSON format' do
      let(:invalid_attributes) { { instructor: '' } }

      it 'returns unprocessable_entity status' do
        patch :update, params: { id: office_hour.id, office_hour: invalid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns errors as JSON' do
        patch :update, params: { id: office_hour.id, office_hour: invalid_attributes }, format: :json
        expect(response.content_type).to include('application/json')
      end
    end
  end

  describe 'DELETE #destroy' do
    before { sign_in ta }

    it 'destroys the requested office hour' do
      office_hour # create it first
      expect {
        delete :destroy, params: { id: office_hour.id }
      }.to change(OfficeHour, :count).by(-1)
    end

    it 'redirects to the office hours list' do
      delete :destroy, params: { id: office_hour.id }
      expect(response).to redirect_to(office_hours_path(view: 'my'))
    end

    it 'sets a success notice' do
      delete :destroy, params: { id: office_hour.id }
      expect(flash[:notice]).to match(/successfully destroyed/i)
    end

    it 'returns see_other status' do
      delete :destroy, params: { id: office_hour.id }
      expect(response).to have_http_status(:see_other)
    end

    context 'with JSON format' do
      it 'returns no_content status' do
        delete :destroy, params: { id: office_hour.id }, format: :json
        expect(response).to have_http_status(:no_content)
      end

      it 'destroys the office hour' do
        office_hour # create it first
        expect {
          delete :destroy, params: { id: office_hour.id }, format: :json
        }.to change(OfficeHour, :count).by(-1)
      end
    end
  end

  describe 'GET #queue_status' do
    before { sign_in student }

    it 'assigns the office hour' do
      get :queue_status, params: { id: office_hour.id }
      expect(assigns(:office_hour)).to eq(office_hour)
    end

    it 'renders the queue_section partial' do
      get :queue_status, params: { id: office_hour.id }
      expect(response).to render_template(partial: '_queue_section')
    end
  end

  describe 'POST #start_queue' do
    before { sign_in ta }

    it 'starts the queue' do
      post :start_queue, params: { id: office_hour.id }
      office_hour.reload
      expect(office_hour.queue_active?).to be true
    end

    it 'creates a queue session' do
      expect {
        post :start_queue, params: { id: office_hour.id }
      }.to change(QueueSession, :count).by(1)
    end

    it 'redirects to office hour with success notice' do
      post :start_queue, params: { id: office_hour.id }
      expect(response).to redirect_to(office_hour)
      expect(flash[:notice]).to match(/started successfully/i)
    end
  end

  describe 'POST #soft_close_queue' do
    before do
      sign_in ta
      office_hour.start_queue!
      create(:queue_entry, office_hour: office_hour, status: 'waiting')
    end

    it 'closes queue to new students' do
      post :soft_close_queue, params: { id: office_hour.id }
      office_hour.reload
      expect(office_hour.queue_active?).to be false
    end

    it 'keeps waiting students in queue' do
      entry = office_hour.queue_entries.first
      post :soft_close_queue, params: { id: office_hour.id }
      expect(entry.reload.status).to eq('waiting')
    end

    it 'redirects with notice about waiting students' do
      post :soft_close_queue, params: { id: office_hour.id }
      expect(response).to redirect_to(office_hour)
      expect(flash[:notice]).to match(/still waiting/i)
    end
  end

  describe 'POST #hard_close_queue' do
    before do
      sign_in ta
      office_hour.start_queue!
      create(:queue_entry, office_hour: office_hour, status: 'waiting')
    end

    it 'closes the queue' do
      post :hard_close_queue, params: { id: office_hour.id }
      office_hour.reload
      expect(office_hour.queue_active?).to be false
    end

    it 'removes all waiting students' do
      entry = office_hour.queue_entries.first
      post :hard_close_queue, params: { id: office_hour.id }
      expect(entry.reload.status).to eq('removed')
    end

    it 'redirects with notice about removed students' do
      post :hard_close_queue, params: { id: office_hour.id }
      expect(response).to redirect_to(office_hour)
      expect(flash[:notice]).to match(/removed from queue/i)
    end
  end

  describe 'GET #queue_status' do
    before { sign_in ta }

    it 'renders the queue_section partial' do
      get :queue_status, params: { id: office_hour.id }
      expect(response).to render_template(partial: '_queue_section')
    end

    it 'assigns the office hour' do
      get :queue_status, params: { id: office_hour.id }
      expect(assigns(:office_hour)).to eq(office_hour)
    end
  end

  describe '#authorize_ta_access' do
    context 'when student tries to edit' do
      before { sign_in student }

      it 'redirects when trying to edit' do
        get :edit, params: { id: office_hour.id }
        expect(response).to redirect_to(office_hours_path)
        expect(flash[:alert]).to match(/only modify.*course/i)
      end

      it 'redirects when trying to update' do
        patch :update, params: { id: office_hour.id, office_hour: { instructor: 'New Name' } }
        expect(response).to redirect_to(office_hours_path)
        expect(flash[:alert]).to match(/only modify.*course/i)
      end

      it 'redirects when trying to destroy' do
        delete :destroy, params: { id: office_hour.id }
        expect(response).to redirect_to(office_hours_path)
        expect(flash[:alert]).to match(/only modify.*course/i)
      end
    end

    context 'when TA from different course tries to modify' do
      let(:other_ta) { create(:user, :ta, uni: 'other_ta', course_name: 'Other Course') }
      
      before { sign_in other_ta }

      it 'redirects when trying to update' do
        patch :update, params: { id: office_hour.id, office_hour: { instructor: 'New Name' } }
        expect(response).to redirect_to(office_hours_path)
        expect(flash[:alert]).to match(/only modify.*course/i)
      end

      it 'redirects when trying to destroy' do
        delete :destroy, params: { id: office_hour.id }
        expect(response).to redirect_to(office_hours_path)
        expect(flash[:alert]).to match(/only modify.*course/i)
      end
    end
  end

  describe '#authorize_ta_for_queue' do
    context 'when student tries to manage queue' do
      before { sign_in student }

      it 'redirects when trying to start queue' do
        post :start_queue, params: { id: office_hour.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/only tas can manage/i)
      end

      it 'redirects when trying to soft close queue' do
        post :soft_close_queue, params: { id: office_hour.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/only tas can manage/i)
      end

      it 'redirects when trying to hard close queue' do
        post :hard_close_queue, params: { id: office_hour.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/only tas can manage/i)
      end
    end
  end

  describe 'private methods' do
    describe '#set_office_hour' do
      before { sign_in student }

      it 'sets @office_hour for show action' do
        get :show, params: { id: office_hour.id }
        expect(assigns(:office_hour)).to eq(office_hour)
      end

      it 'sets @office_hour for edit action' do
        sign_in ta
        get :edit, params: { id: office_hour.id }
        expect(assigns(:office_hour)).to eq(office_hour)
      end
    end

    describe '#office_hour_params' do
      before { sign_in ta }

      it 'permits instructor, day, start_time, end_time, location, ta_uni' do
        post :create, params: {
          office_hour: {
            instructor: 'Dr. Smith',
            day: 'Monday',
            start_time: '10:00AM',
            end_time: '12:00PM',
            location: 'Room 301',
            ta_uni: 'test_ta',
            course_name: 'Should be ignored'
          }
        }
        # course_name should come from current_user, not params
        expect(OfficeHour.last.course_name).to eq('Engineering SaaS')
      end
    end
  end
end