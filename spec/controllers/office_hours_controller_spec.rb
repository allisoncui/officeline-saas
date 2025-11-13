require 'rails_helper'

describe OfficeHoursController, type: :controller do
  let(:user) { create(:user, uni: 'test123', role: 'student') }
  let(:ta_user) { create(:user, uni: 'ta123', role: 'ta') }
  
  before :each do
    sign_in user
  end
  
  # Index: filtering and sorting
  describe 'GET #index' do
    before :each do
      @fake_results = [double('office_hour1'), double('office_hour2')]
    end

    context 'as a student' do
      it 'calls the model method that filters and sorts office hours' do
        expect(OfficeHour).to receive(:with_filters)
          .with(['Monday', 'Wednesday'], 'instructor')
          .and_return(@fake_results)
        get :index, params: { days: { 'Monday' => '1', 'Wednesday' => '1' }, sort_by: 'instructor' }
      end

      it 'stores the selected sort parameter in the session and assigns @sort_by' do
        get :index, params: { sort_by: 'instructor' }
        expect(session[:sort_by]).to eq('instructor')
        expect(assigns(:sort_by)).to eq('instructor')
      end

      it 'stores selected days in the session and assigns @days_to_show' do
        get :index, params: { days: { 'Monday' => '1', 'Tuesday' => '1' } }
        expect(session[:days]).to include('Monday', 'Tuesday')
        expect(assigns(:days_to_show)).to include('Monday', 'Tuesday')
      end

      it 'handles days as ActionController::Parameters' do
        # Use a hash that Rails will convert to ActionController::Parameters
        get :index, params: { days: { 'Monday' => '1', 'Tuesday' => '1' } }
        expect(assigns(:days_to_show)).to include('Monday', 'Tuesday')
      end

      it 'handles days as a plain Hash' do
        controller.params = ActionController::Parameters.new(days: { 'Monday' => '1' })
        allow(controller.params[:days]).to receive(:is_a?).with(ActionController::Parameters).and_return(false)
        allow(controller.params[:days]).to receive(:is_a?).with(Hash).and_return(true)
        allow(controller.params[:days]).to receive(:keys).and_return(['Monday'])
        get :index
        expect(assigns(:days_to_show)).to include('Monday')
      end

      it 'executes raw_days.keys when days is ActionController::Parameters' do
        # This tests line 11: raw_days = raw_days.keys if raw_days.is_a?(ActionController::Parameters)
        allow(OfficeHour).to receive(:with_filters).and_return(@fake_results)
        # Use a hash that Rails will convert to ActionController::Parameters
        get :index, params: { days: { 'Monday' => '1', 'Tuesday' => '1' } }
        expect(assigns(:days_to_show)).to include('Monday', 'Tuesday')
      end

      it 'executes raw_days.keys when days is a Hash' do
        # This tests line 12: raw_days.is_a?(Hash)
        allow(OfficeHour).to receive(:with_filters).and_return(@fake_results)
        hash_days = { 'Monday' => '1', 'Tuesday' => '1' }
        get :index, params: { days: hash_days }
        expect(assigns(:days_to_show)).to include('Monday', 'Tuesday')
      end

      it 'uses all days and default sort when no params are provided' do
        allow(OfficeHour).to receive(:all_days).and_return(%w[Monday Tuesday Wednesday])
        allow(OfficeHour).to receive(:with_filters).and_return(@fake_results)
        get :index
        expect(assigns(:days_to_show)).to eq(%w[Monday Tuesday Wednesday])
        expect(assigns(:sort_by)).to eq('course_name')
        expect(response).to render_template('student_index')
      end

      it 'assigns saved office hour IDs' do
        office_hour = create(:office_hour)
        create(:enrollment, user: user, office_hour: office_hour)
        allow(OfficeHour).to receive(:with_filters).and_return(@fake_results)
        get :index
        expect(assigns(:saved_office_hour_ids)).to include(office_hour.id)
      end

      describe 'after valid filter' do
        before :each do
          allow(OfficeHour).to receive(:with_filters).and_return(@fake_results)
          get :index, params: { days: { 'Monday' => '1', 'Wednesday' => '1' }, sort_by: 'instructor' }
        end

        it 'selects the index template for rendering' do
          expect(response).to render_template('student_index')
        end

        it 'makes the filtered office hours available to that template' do
          expect(assigns(:office_hours)).to eq(@fake_results)
        end
      end
    end

    context 'as a TA' do
      before do
        sign_out user
        sign_in ta_user
        ta_user.update(course_name: 'Engineering SaaS')
      end

      it 'renders ta_index template' do
        get :index
        expect(response).to render_template('ta_index')
      end

      it 'assigns office hours for TA course' do
        oh1 = create(:office_hour, course_name: 'Engineering SaaS', ta_uni: 'ta123')
        oh2 = create(:office_hour, course_name: 'Engineering SaaS', ta_uni: 'other123')
        oh3 = create(:office_hour, course_name: 'Other Course')
        
        get :index
        expect(assigns(:all_office_hours)).to include(oh1, oh2)
        expect(assigns(:all_office_hours)).not_to include(oh3)
      end

      it 'assigns only TA own hours when view is "my"' do
        oh1 = create(:office_hour, course_name: 'Engineering SaaS', ta_uni: 'ta123')
        oh2 = create(:office_hour, course_name: 'Engineering SaaS', ta_uni: 'other123')
        
        get :index, params: { view: 'my' }
        expect(assigns(:office_hours)).to include(oh1)
        expect(assigns(:office_hours)).not_to include(oh2)
        expect(assigns(:view)).to eq('my')
      end

      it 'assigns all course hours when view is "all"' do
        oh1 = create(:office_hour, course_name: 'Engineering SaaS', ta_uni: 'ta123')
        oh2 = create(:office_hour, course_name: 'Engineering SaaS', ta_uni: 'other123')
        
        get :index, params: { view: 'all' }
        expect(assigns(:office_hours)).to include(oh1, oh2)
        expect(assigns(:view)).to eq('all')
      end

      it 'executes @view == "all" ternary check' do
        # This tests line 40: @view == 'all' ? @all_office_hours : @my_office_hours
        oh1 = create(:office_hour, course_name: 'Engineering SaaS', ta_uni: 'ta123')
        oh2 = create(:office_hour, course_name: 'Engineering SaaS', ta_uni: 'other123')
        
        get :index, params: { view: 'all' }
        # When view is 'all', should use @all_office_hours
        expect(assigns(:office_hours)).to eq(assigns(:all_office_hours))
        expect(assigns(:office_hours)).to include(oh1, oh2)
      end
    end
  end

  # Show
  describe 'GET #show' do
    it 'assigns the requested office hour to @office_hour' do
      office_hour = OfficeHour.create!(course_name: 'Math', instructor: 'Lee', day: 'Monday',
                                       start_time: '9:00', end_time: '10:00', location: 'BH210', ta_uni: 'lee123')
      get :show, params: { id: office_hour.id }
      expect(assigns(:office_hour)).to eq(office_hour)
      expect(response).to render_template('show')
    end
  end

  # New
  describe 'GET #new' do
    it 'assigns a new OfficeHour to @office_hour' do
      get :new
      expect(assigns(:office_hour)).to be_a_new(OfficeHour)
      expect(response).to render_template('new')
    end
  end

  # Create
  describe 'POST #create' do
    let(:valid_attributes) do
      {
        course_name: 'Physics 101',
        instructor: 'Dr. Carter',
        day: 'Tuesday',
        start_time: '11:00',
        end_time: '12:00',
        location: 'BH310',
        ta_uni: 'carter001'
      }
    end

    let(:invalid_attributes) { { course_name: '', instructor: '', day: '' } }

    it 'creates a new OfficeHour with valid params and redirects to show' do
      sign_out user
      sign_in ta_user
      ta_user.update(course_name: 'Physics 101')

      expect {
        post :create, params: { office_hour: valid_attributes.except(:ta_uni, :course_name) }
      }.to change(OfficeHour, :count).by(1)

      expect(response).to redirect_to(OfficeHour.last)
      expect(flash[:notice]).to match(/successfully created/i)
    end

    it 're-renders new when invalid params are provided' do
      sign_out user
      sign_in ta_user

      expect {
        post :create, params: { office_hour: invalid_attributes }
      }.not_to change(OfficeHour, :count)

      expect(response).to render_template('new')
    end

    it 'handles JSON format requests' do
      sign_out user
      sign_in ta_user
      ta_user.update(course_name: 'Physics 101')

      post :create, params: { office_hour: valid_attributes.except(:ta_uni, :course_name), format: :json }
      expect(response).to have_http_status(:created)
      expect(response.content_type).to include('application/json')
    end

    it 'handles JSON format errors' do
      sign_out user
      sign_in ta_user

      post :create, params: { office_hour: invalid_attributes, format: :json }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.content_type).to include('application/json')
    end
  end

  # Update
  describe 'PATCH #update' do
    let!(:office_hour) do
      sign_out user
      sign_in ta_user
      ta_user.update(course_name: 'Chemistry', uni: 'smith001')
      OfficeHour.create!(
        course_name: 'Chemistry',
        instructor: 'Dr. Smith',
        day: 'Wednesday',
        start_time: '10:00',
        end_time: '11:00',
        location: 'BH100',
        ta_uni: 'smith001'
      )
    end

    before do
      sign_out user
      sign_in ta_user
      ta_user.update(course_name: 'Chemistry', uni: 'smith001')
    end

    it 'updates an existing office hour with valid attributes' do
      patch :update, params: {
        id: office_hour.id,
        office_hour: { instructor: 'Dr. Kim' }
      }

      office_hour.reload
      expect(office_hour.instructor).to eq('Dr. Kim')
      expect(response).to redirect_to(office_hour)
      expect(flash[:notice]).to match(/successfully updated/i)
    end

    it 're-renders edit when invalid attributes are given' do
      patch :update, params: {
        id: office_hour.id,
        office_hour: { instructor: '' }
      }

      expect(response).to render_template('edit')
    end

    it 'handles JSON format requests' do
      patch :update, params: {
        id: office_hour.id,
        office_hour: { instructor: 'Dr. Kim' },
        format: :json
      }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')
    end

    it 'handles JSON format errors' do
      patch :update, params: {
        id: office_hour.id,
        office_hour: { instructor: '' },
        format: :json
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.content_type).to include('application/json')
    end
  end

  # Destroy
  describe 'DELETE #destroy' do
    before do
      sign_out user
      sign_in ta_user
      ta_user.update(course_name: 'Bio', uni: 'lin001')
    end

    it 'deletes the requested office hour and redirects to index' do
      office_hour = OfficeHour.create!(
        course_name: 'Bio',
        instructor: 'Dr. Lin',
        day: 'Friday',
        start_time: '8:00',
        end_time: '9:00',
        location: 'BH500',
        ta_uni: 'lin001'
      )

      expect {
        delete :destroy, params: { id: office_hour.id }
      }.to change(OfficeHour, :count).by(-1)

      expect(response).to redirect_to(office_hours_path)
      expect(flash[:notice]).to match(/successfully destroyed/i)
    end

    it 'handles JSON format requests' do
      office_hour = OfficeHour.create!(
        course_name: 'Bio',
        instructor: 'Dr. Lin',
        day: 'Friday',
        start_time: '8:00',
        end_time: '9:00',
        location: 'BH500',
        ta_uni: 'lin001'
      )

      delete :destroy, params: { id: office_hour.id, format: :json }
      expect(response).to have_http_status(:no_content)
    end
  end

  # Edit
  describe 'GET #edit' do
    let!(:office_hour) do
      OfficeHour.create!(
        course_name: 'Chemistry',
        instructor: 'Dr. Smith',
        day: 'Wednesday',
        start_time: '10:00',
        end_time: '11:00',
        location: 'BH100',
        ta_uni: 'smith001'
      )
    end

    context 'when TA owns the office hour' do
      before do
        sign_out user
        sign_in ta_user
        ta_user.update(uni: 'smith001', course_name: 'Chemistry')
      end

      it 'renders the edit template' do
        get :edit, params: { id: office_hour.id }
        expect(response).to render_template('edit')
      end
    end

    context 'when TA does not own the office hour' do
      before do
        sign_out user
        sign_in ta_user
        ta_user.update(uni: 'other001', course_name: 'Chemistry')
      end

      it 'redirects with alert' do
        get :edit, params: { id: office_hour.id }
        expect(response).to redirect_to(office_hours_path)
        expect(flash[:alert]).to match(/only modify your own/i)
      end
    end
  end

  # Authorization
  describe '#authorize_ta_access' do
    let!(:office_hour) do
      OfficeHour.create!(
        course_name: 'Chemistry',
        instructor: 'Dr. Smith',
        day: 'Wednesday',
        start_time: '10:00',
        end_time: '11:00',
        location: 'BH100',
        ta_uni: 'smith001'
      )
    end

    context 'when updating without authorization' do
      before do
        sign_out user
        sign_in ta_user
        ta_user.update(uni: 'other001', course_name: 'Chemistry')
      end

      it 'redirects when trying to update' do
        patch :update, params: {
          id: office_hour.id,
          office_hour: { instructor: 'Dr. Hacker' }
        }
        expect(response).to redirect_to(office_hours_path)
        expect(flash[:alert]).to match(/only modify your own/i)
      end

      it 'redirects when trying to destroy' do
        delete :destroy, params: { id: office_hour.id }
        expect(response).to redirect_to(office_hours_path)
        expect(flash[:alert]).to match(/only modify your own/i)
      end
    end
  end

  # Index edge cases
  describe 'GET #index' do
    context 'when current_user is nil' do
      before { sign_out user }

      it 'redirects to sign in' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as a student with nil current_user check' do
      it 'handles saved_office_hour_ids when user is student' do
        office_hour = create(:office_hour)
        create(:enrollment, user: user, office_hour: office_hour)
        allow(OfficeHour).to receive(:with_filters).and_return([office_hour])
        get :index
        expect(assigns(:saved_office_hour_ids)).to include(office_hour.id)
      end

      it 'handles when current_user is nil' do
        sign_out user
        allow(controller).to receive(:current_user).and_return(nil)
        allow(OfficeHour).to receive(:with_filters).and_return([])
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when days param is a Hash' do
      it 'extracts keys from Hash' do
        allow(OfficeHour).to receive(:with_filters).and_return(@fake_results)
        # Simulate Hash instead of ActionController::Parameters
        hash_days = { 'Monday' => '1', 'Tuesday' => '1' }
        get :index, params: { days: hash_days }
        expect(assigns(:days_to_show)).to include('Monday', 'Tuesday')
      end
    end
  end

  # Create edge cases
  describe 'POST #create' do
    context 'when current_user is not a TA' do
      it 'does not set ta_uni' do
        sign_out user
        sign_in user # student user
        user.update(course_name: 'Engineering SaaS')
        
        post :create, params: {
          office_hour: {
            instructor: 'Dr. Smith',
            day: 'Monday',
            start_time: '10:00AM',
            end_time: '12:00PM',
            location: 'Room 301'
          }
        }
        
        # Student cannot create office hours - validation fails because ta_uni is required
        # when instructor is present, but students don't have ta_uni set
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template('new')
        office_hour = assigns(:office_hour)
        expect(office_hour.ta_uni).to be_nil
        expect(office_hour.errors).to be_present
      end
    end
  end

  # Queue Status
  describe 'GET #queue_status' do
    let(:office_hour) { create(:office_hour) }

    it 'assigns the office hour' do
      get :queue_status, params: { id: office_hour.id }
      expect(assigns(:office_hour)).to eq(office_hour)
    end

    it 'renders the queue_section partial' do
      get :queue_status, params: { id: office_hour.id }
      expect(response).to render_template(partial: '_queue_section')
    end
  end
end
