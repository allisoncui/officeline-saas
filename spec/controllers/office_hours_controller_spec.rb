require 'rails_helper'

describe OfficeHoursController, type: :controller do
  describe 'filtering and sorting office hours' do
    before :each do
      @fake_results = [double('office_hour1'), double('office_hour2')]
    end

    it 'calls the model method that filters and sorts office hours' do
      expect(OfficeHour).to receive(:with_filters)
        .with(['Monday', 'Wednesday'], 'instructor')
        .and_return(@fake_results)
      get :index, params: { days: { 'Monday' => '1', 'Wednesday' => '1' }, sort_by: 'instructor' }
    end

    # Sorting behavior
    it 'stores the selected sort parameter in the session and assigns @sort_by' do
      get :index, params: { sort_by: 'instructor' }
      expect(session[:sort_by]).to eq('instructor')
      expect(assigns(:sort_by)).to eq('instructor')
    end

    # Days filter persistence
    it 'stores selected days in the session and assigns @days_to_show' do
      get :index, params: { days: { 'Monday' => '1', 'Tuesday' => '1' } }
      expect(session[:days]).to include('Monday', 'Tuesday')
      expect(assigns(:days_to_show)).to include('Monday', 'Tuesday')
    end

    # Default behavior when no params provided
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
end
