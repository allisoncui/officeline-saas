require 'rails_helper'

RSpec.describe OfficeHour, type: :model do
  describe 'associations' do
    it { should have_many(:questions).dependent(:destroy) }
    it { should have_many(:enrollments).dependent(:destroy) }
    it { should have_many(:students).through(:enrollments) }
    it { should have_many(:queue_entries).dependent(:destroy) }
    it { should have_many(:queued_users).through(:queue_entries) }
  end

  describe 'validations' do
    it { should validate_presence_of(:course_name) }
    it { should validate_presence_of(:instructor) }
    it { should validate_presence_of(:day) }
    it { should validate_presence_of(:start_time) }
    it { should validate_presence_of(:end_time) }
    it { should validate_presence_of(:location) }
    
    it 'validates ta_uni presence when instructor is present' do
      office_hour = build(:office_hour, instructor: 'Dr. Smith', ta_uni: nil)
      expect(office_hour).not_to be_valid
      expect(office_hour.errors[:ta_uni]).to be_present
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:office_hour)).to be_valid
    end
  end

  describe 'class methods' do
    describe '.all_days' do
      it 'returns the correct days' do
        expect(OfficeHour.all_days).to eq(%w[Monday Tuesday Wednesday Thursday Friday])
      end
    end

    describe '.with_filters' do
      let!(:monday_oh) { create(:office_hour, day: 'Monday', start_time: '2:00PM', course_name: 'Math') }
      let!(:tuesday_oh) { create(:office_hour, day: 'Tuesday', start_time: '1:00PM', course_name: 'Physics') }
      let!(:wednesday_oh) { create(:office_hour, day: 'Wednesday', start_time: '3:00PM', course_name: 'Chemistry') }

      it 'filters by days' do
        results = OfficeHour.with_filters(['Monday', 'Tuesday'], 'course_name')
        expect(results).to include(monday_oh, tuesday_oh)
        expect(results).not_to include(wednesday_oh)
      end

      it 'sorts by course_name' do
        results = OfficeHour.with_filters(nil, 'course_name')
        expect(results.map(&:course_name)).to eq(['Chemistry', 'Math', 'Physics'])
      end

      it 'sorts by instructor' do
        monday_oh.update(instructor: 'Dr. A')
        tuesday_oh.update(instructor: 'Dr. B')
        wednesday_oh.update(instructor: 'Dr. C')
        
        results = OfficeHour.with_filters(nil, 'instructor')
        expect(results.map(&:instructor)).to eq(['Dr. A', 'Dr. B', 'Dr. C'])
      end

      it 'sorts by day and time chronologically' do
        results = OfficeHour.with_filters(nil, 'day')
        # When sorting by day, it sorts by DAY_ORDER first (Monday=1, Tuesday=2, Wednesday=3)
        # Then by time within the same day
        # So Monday (2:00PM) comes before Tuesday (1:00PM) comes before Wednesday (3:00PM)
        expect(results.map(&:day)).to eq(['Monday', 'Tuesday', 'Wednesday'])
      end

      it 'handles days not in DAY_ORDER' do
        saturday_oh = create(:office_hour, day: 'Saturday', start_time: '10:00AM')
        results = OfficeHour.with_filters(nil, 'day')
        # Saturday should come last (999 in DAY_ORDER)
        expect(results.last.day).to eq('Saturday')
      end
    end

    describe '.parse_time' do
      it 'parses AM times correctly' do
        expect(OfficeHour.send(:parse_time, '9:30AM')).to eq(9 * 60 + 30)
        expect(OfficeHour.send(:parse_time, '12:00AM')).to eq(0) # midnight
        expect(OfficeHour.send(:parse_time, '1:15AM')).to eq(1 * 60 + 15)
      end

      it 'parses PM times correctly' do
        expect(OfficeHour.send(:parse_time, '1:30PM')).to eq(13 * 60 + 30)
        expect(OfficeHour.send(:parse_time, '12:00PM')).to eq(12 * 60) # noon
        expect(OfficeHour.send(:parse_time, '11:45PM')).to eq(23 * 60 + 45)
      end

      it 'handles blank time strings' do
        expect(OfficeHour.send(:parse_time, '')).to eq(0)
        expect(OfficeHour.send(:parse_time, nil)).to eq(0)
      end

      it 'handles invalid time formats' do
        expect(OfficeHour.send(:parse_time, 'invalid')).to eq(0)
        expect(OfficeHour.send(:parse_time, '25:00')).to eq(0)
      end

      it 'strips whitespace' do
        expect(OfficeHour.send(:parse_time, '  2:00PM  ')).to eq(14 * 60)
      end

      it 'handles case insensitivity' do
        expect(OfficeHour.send(:parse_time, '2:00pm')).to eq(14 * 60)
        expect(OfficeHour.send(:parse_time, '2:00am')).to eq(2 * 60)
      end
    end
  end

  describe 'queue methods' do
    let(:office_hour) { create(:office_hour) }
    let(:user) { create(:user) }

    describe '#start_queue!' do
      it 'activates the queue and sets started_at' do
        office_hour.start_queue!
        expect(office_hour.queue_active).to be true
        expect(office_hour.queue_started_at).to be_present
      end
    end

    describe '#close_queue!' do
      it 'deactivates the queue' do
        office_hour.start_queue!
        office_hour.close_queue!
        expect(office_hour.queue_active).to be false
      end

      it 'marks all waiting entries as removed' do
        office_hour.start_queue!
        entry = create(:queue_entry, office_hour: office_hour, user: user, status: 'waiting')
        office_hour.close_queue!
        expect(entry.reload.status).to eq('removed')
      end
    end

    describe '#active_queue' do
      it 'returns only waiting entries' do
        office_hour.start_queue!
        waiting = create(:queue_entry, office_hour: office_hour, status: 'waiting')
        served = create(:queue_entry, office_hour: office_hour, status: 'served')
        
        expect(office_hour.active_queue).to include(waiting)
        expect(office_hour.active_queue).not_to include(served)
      end
    end

    describe '#user_in_queue?' do
      it 'returns true if user is in queue' do
        office_hour.start_queue!
        create(:queue_entry, office_hour: office_hour, user: user, status: 'waiting')
        expect(office_hour.user_in_queue?(user)).to be true
      end

      it 'returns false if user is not in queue' do
        expect(office_hour.user_in_queue?(user)).to be false
      end
    end

    describe '#user_queue_position' do
      it 'returns the position of the user in queue' do
        office_hour.start_queue!
        other_user = create(:user)
        create(:queue_entry, office_hour: office_hour, user: other_user, status: 'waiting')
        entry = create(:queue_entry, office_hour: office_hour, user: user, status: 'waiting')
        # Position is updated by callback, so second entry should be position 2
        expect(office_hour.user_queue_position(user)).to eq(2)
      end

      it 'returns nil if user is not in queue' do
        expect(office_hour.user_queue_position(user)).to be_nil
      end
    end

    describe '#queue_size' do
      it 'returns the count of active queue entries' do
        office_hour.start_queue!
        create(:queue_entry, office_hour: office_hour, user: user, status: 'waiting')
        other_user = create(:user)
        create(:queue_entry, office_hour: office_hour, user: other_user, status: 'waiting')
        create(:queue_entry, office_hour: office_hour, user: create(:user), status: 'served')
        
        expect(office_hour.queue_size).to eq(2)
      end
    end
  end
end

