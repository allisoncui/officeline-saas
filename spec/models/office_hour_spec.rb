require 'rails_helper'

RSpec.describe OfficeHour, type: :model do
  describe 'associations' do
    it { should have_many(:questions).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:course_name) }
    it { should validate_presence_of(:instructor) }
    it { should validate_presence_of(:day) }
    it { should validate_presence_of(:start_time) }
    it { should validate_presence_of(:end_time) }
    it { should validate_presence_of(:location) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      office_hour = build(:office_hour)
      expect(office_hour).to be_valid
    end
  end

  describe 'basic functionality' do
    let(:valid_attributes) do
      {
        course_name: 'Engineering SaaS',
        instructor: 'Junfeng Yang',
        day: 'Tuesday',
        start_time: '3:00PM',
        end_time: '5:00PM',
        location: 'Zoom'
      }
    end

    it 'is valid with valid attributes' do
      office_hour = OfficeHour.new(valid_attributes)
      expect(office_hour).to be_valid
    end

    it 'is invalid without course_name' do
      office_hour = OfficeHour.new(valid_attributes.merge(course_name: nil))
      expect(office_hour).to_not be_valid
      expect(office_hour.errors[:course_name]).to include("can't be blank")
    end

    it 'is invalid without instructor' do
      office_hour = OfficeHour.new(valid_attributes.merge(instructor: nil))
      expect(office_hour).to_not be_valid
      expect(office_hour.errors[:instructor]).to include("can't be blank")
    end

    it 'is invalid without day' do
      office_hour = OfficeHour.new(valid_attributes.merge(day: nil))
      expect(office_hour).to_not be_valid
      expect(office_hour.errors[:day]).to include("can't be blank")
    end

    it 'is invalid without start_time' do
      office_hour = OfficeHour.new(valid_attributes.merge(start_time: nil))
      expect(office_hour).to_not be_valid
      expect(office_hour.errors[:start_time]).to include("can't be blank")
    end

    it 'is invalid without end_time' do
      office_hour = OfficeHour.new(valid_attributes.merge(end_time: nil))
      expect(office_hour).to_not be_valid
      expect(office_hour.errors[:end_time]).to include("can't be blank")
    end

    it 'is invalid without location' do
      office_hour = OfficeHour.new(valid_attributes.merge(location: nil))
      expect(office_hour).to_not be_valid
      expect(office_hour.errors[:location]).to include("can't be blank")
    end
  end

  describe 'class methods' do
    describe '.all_days' do
      it 'returns array of weekdays' do
        expect(OfficeHour.all_days).to eq(%w[Monday Tuesday Wednesday Thursday Friday])
      end
    end

    describe '.with_filters' do
      before do
        @oh1 = create(:office_hour, course_name: 'Math', day: 'Monday', start_time: '1:00PM')
        @oh2 = create(:office_hour, course_name: 'Science', day: 'Tuesday', start_time: '2:00PM')
        @oh3 = create(:office_hour, course_name: 'English', day: 'Wednesday', start_time: '3:00PM')
      end

      it 'filters by days' do
        results = OfficeHour.with_filters(['Monday', 'Tuesday'], 'course_name')
        expect(results.map(&:course_name)).to match_array(['Math', 'Science'])
      end

      it 'sorts by course_name' do
        results = OfficeHour.with_filters(nil, 'course_name')
        expect(results.map(&:course_name)).to eq(['English', 'Math', 'Science'])
      end

      it 'sorts by day and time' do
        results = OfficeHour.with_filters(nil, 'day')
        expect(results.first.day).to eq('Monday')
      end
    end
  end
end

