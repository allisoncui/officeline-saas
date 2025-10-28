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
