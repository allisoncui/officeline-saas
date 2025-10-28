require 'rails_helper'

describe OfficeHoursController, type: :controller do
  # Index: filtering and sorting
  describe 'GET #index' do
    before :each do
      @fake_results = [double('office_hour1'), double('office_hour2')]
    end

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

    it 'uses all days and default sort when no params are provided' do
      allow(OfficeHour).to receive(:all_days).and_return(%w[Monday Tuesday Wednesday])
      allow(OfficeHour).to receive(:with_filters).and_return(@fake_results)
      get :index
      expect(assigns(:days_to_show)).to eq(%w[Monday Tuesday Wednesday])
      expect(assigns(:sort_by)).to eq('course_name')
      expect(response).to render_template('index')
    end

    describe 'after valid filter' do
      before :each do
        allow(OfficeHour).to receive(:with_filters).and_return(@fake_results)
        get :index, params: { days: { 'Monday' => '1', 'Wednesday' => '1' }, sort_by: 'instructor' }
      end

      it 'selects the index template for rendering' do
        expect(response).to render_template('index')
      end

      it 'makes the filtered office hours available to that template' do
        expect(assigns(:office_hours)).to eq(@fake_results)
      end
    end
  end

  # Show
  describe 'GET #show' do
    it 'assigns the requested office hour to @office_hour' do
      office_hour = OfficeHour.create!(course_name: 'Math', instructor: 'Lee', day: 'Monday',
                                       start_time: '9:00', end_time: '10:00', location: 'BH210')
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
        location: 'BH310'
      }
    end

    let(:invalid_attributes) { { course_name: '', instructor: '', day: '' } }

    it 'creates a new OfficeHour with valid params and redirects to show' do
      expect {
        post :create, params: { office_hour: valid_attributes }
      }.to change(OfficeHour, :count).by(1)

      expect(response).to redirect_to(OfficeHour.last)
      expect(flash[:notice]).to match(/successfully created/i)
    end

    it 're-renders new when invalid params are provided' do
      expect {
        post :create, params: { office_hour: invalid_attributes }
      }.not_to change(OfficeHour, :count)

      expect(response).to render_template('new')
    end
  end

  # Update
  describe 'PATCH #update' do
    let!(:office_hour) do
      OfficeHour.create!(
        course_name: 'Chemistry',
        instructor: 'Dr. Smith',
        day: 'Wednesday',
        start_time: '10:00',
        end_time: '11:00',
        location: 'BH100'
      )
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
        office_hour: { course_name: '' }
      }

      expect(response).to render_template('edit')
    end
  end

  # Destroy
  describe 'DELETE #destroy' do
    it 'deletes the requested office hour and redirects to index' do
      office_hour = OfficeHour.create!(
        course_name: 'Bio',
        instructor: 'Dr. Lin',
        day: 'Friday',
        start_time: '8:00',
        end_time: '9:00',
        location: 'BH500'
      )

      expect {
        delete :destroy, params: { id: office_hour.id }
      }.to change(OfficeHour, :count).by(-1)

      expect(response).to redirect_to(office_hours_path)
      expect(flash[:notice]).to match(/successfully destroyed/i)
    end
  end
end
