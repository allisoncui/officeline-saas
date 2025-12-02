require 'rails_helper'

RSpec.describe OfficeHour, type: :model do
  # ... existing tests ...

  describe 'queue methods' do
    let(:office_hour) { create(:office_hour) }

    describe '#start_queue!' do
      it 'sets queue_active to true' do
        office_hour.start_queue!
        expect(office_hour.queue_active?).to be true
      end

      it 'creates a queue session' do
        expect {
          office_hour.start_queue!
        }.to change(QueueSession, :count).by(1)
      end

      it 'sets queue_started_at' do
        office_hour.start_queue!
        expect(office_hour.queue_started_at).to be_present
      end
    end

    describe '#close_queue!' do
      before do
        office_hour.start_queue!
        create(:queue_entry, office_hour: office_hour, status: 'waiting')
      end

      it 'sets queue_active to false' do
        office_hour.close_queue!
        expect(office_hour.queue_active?).to be false
      end

      it 'ends the current session' do
        session = office_hour.queue_sessions.last
        office_hour.close_queue!
        expect(session.reload.ended_at).to be_present
      end

      it 'marks waiting entries as removed' do
        entry = office_hour.queue_entries.first
        office_hour.close_queue!
        expect(entry.reload.status).to eq('removed')
      end
    end

    describe '#current_session' do
      it 'returns the active session' do
        office_hour.start_queue!
        session = office_hour.queue_sessions.last
        expect(office_hour.current_session).to eq(session)
      end

      it 'returns nil when no active session' do
        expect(office_hour.current_session).to be_nil
      end
    end

    describe '#recent_sessions' do
      it 'returns recent sessions ordered by started_at' do
        session1 = create(:queue_session, office_hour: office_hour, started_at: 2.days.ago)
        session2 = create(:queue_session, office_hour: office_hour, started_at: 1.day.ago)
        
        expect(office_hour.recent_sessions).to eq([session2, session1])
      end

      it 'limits results' do
        12.times { |i| create(:queue_session, office_hour: office_hour, started_at: i.days.ago) }
        expect(office_hour.recent_sessions.count).to eq(10)
      end
    end

    describe '#active_queue' do
      it 'returns waiting entries ordered by joined_at' do
        entry1 = create(:queue_entry, office_hour: office_hour, status: 'waiting', joined_at: 2.minutes.ago)
        entry2 = create(:queue_entry, office_hour: office_hour, status: 'served')
        entry3 = create(:queue_entry, office_hour: office_hour, status: 'waiting', joined_at: 1.minute.ago)
        
        expect(office_hour.active_queue).to eq([entry1, entry3])
      end
    end

    describe '#queue_size' do
      it 'returns count of active queue entries' do
        create(:queue_entry, office_hour: office_hour, status: 'waiting')
        create(:queue_entry, office_hour: office_hour, status: 'waiting')
        create(:queue_entry, office_hour: office_hour, status: 'served')
        
        expect(office_hour.queue_size).to eq(2)
      end
    end

    describe '#user_in_queue?' do
      let(:user) { create(:user, :student) }

      it 'returns true if user is in queue' do
        create(:queue_entry, office_hour: office_hour, user: user, status: 'waiting')
        expect(office_hour.user_in_queue?(user)).to be true
      end

      it 'returns false if user is not in queue' do
        expect(office_hour.user_in_queue?(user)).to be false
      end

      it 'returns false if user was served' do
        create(:queue_entry, office_hour: office_hour, user: user, status: 'served')
        expect(office_hour.user_in_queue?(user)).to be false
      end
    end

    describe '#user_queue_position' do
      let(:user) { create(:user, :student) }

      it 'returns position if user is in queue' do
        # Create other entries first to make this user position 3
        create(:queue_entry, office_hour: office_hour, status: 'waiting', position: 1, joined_at: 3.minutes.ago)
        create(:queue_entry, office_hour: office_hour, status: 'waiting', position: 2, joined_at: 2.minutes.ago)
        entry = create(:queue_entry, office_hour: office_hour, user: user, status: 'waiting', position: 3, joined_at: 1.minute.ago)
        
        expect(office_hour.user_queue_position(user)).to eq(3)
      end

      it 'returns nil if user is not in queue' do
        expect(office_hour.user_queue_position(user)).to be_nil
      end
    end
  end
end