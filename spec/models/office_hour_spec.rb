require 'rails_helper'

RSpec.describe OfficeHour, type: :model do
  describe 'associations' do
    it { should have_many(:questions).dependent(:destroy) }
    it { should have_many(:enrollments).dependent(:destroy) }
    it { should have_many(:students).through(:enrollments) }
    it { should have_many(:queue_entries).dependent(:destroy) }
    it { should have_many(:queued_users).through(:queue_entries) }
    it { should have_many(:queue_sessions).dependent(:destroy) }
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

    it 'allows ta_uni to be nil when instructor is nil' do
      office_hour = build(:office_hour, instructor: nil, ta_uni: nil)
      office_hour.valid?
      expect(office_hour.errors[:ta_uni]).to be_empty
    end
  end

  describe 'class methods' do
    describe '.all_days' do
      it 'returns array of weekdays' do
        expect(OfficeHour.all_days).to eq(%w[Monday Tuesday Wednesday Thursday Friday])
      end
    end
  end

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

      it 'associates existing questions without session to the new session' do
        user = create(:user, :student)
        question1 = create(:question, office_hour: office_hour, user: user, queue_session_id: nil)
        question2 = create(:question, office_hour: office_hour, user: user, queue_session_id: nil)
        
        office_hour.start_queue!
        session = office_hour.current_session
        
        question1.reload
        question2.reload
        expect(question1.queue_session_id).to eq(session.id)
        expect(question2.queue_session_id).to eq(session.id)
      end
    end

    describe '#soft_close_queue!' do
      before do
        office_hour.start_queue!
      end

      it 'sets queue_active to false' do
        office_hour.soft_close_queue!
        expect(office_hour.queue_active?).to be false
      end

      it 'clears queue_started_at' do
        office_hour.soft_close_queue!
        expect(office_hour.queue_started_at).to be_nil
      end

      it 'does not end the current session' do
        session = office_hour.current_session
        office_hour.soft_close_queue!
        expect(session.reload.ended_at).to be_nil
      end
    end

    describe '#hard_close_queue!' do
      before do
        office_hour.start_queue!
        create(:queue_entry, office_hour: office_hour, status: 'waiting')
      end

      it 'sets queue_active to false' do
        office_hour.hard_close_queue!
        expect(office_hour.queue_active?).to be false
      end

      it 'ends the current session' do
        session = office_hour.current_session
        office_hour.hard_close_queue!
        expect(session.reload.ended_at).to be_present
      end

      it 'marks waiting entries as removed' do
        entry = office_hour.queue_entries.first
        office_hour.hard_close_queue!
        expect(entry.reload.status).to eq('removed')
      end

      it 'clears queue_started_at' do
        office_hour.hard_close_queue!
        expect(office_hour.queue_started_at).to be_nil
      end

      it 'handles case when no current session exists' do
        session = office_hour.current_session
        session.update!(ended_at: Time.current)
        
        expect { office_hour.hard_close_queue! }.not_to raise_error
        expect(office_hour.queue_active?).to be false
      end

      it 'handles case when current_session returns nil' do
        office_hour.update(queue_active: true)
        allow(office_hour).to receive(:current_session).and_return(nil)
        
        expect { office_hour.hard_close_queue! }.not_to raise_error
        expect(office_hour.queue_active?).to be false
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

      it 'accepts custom limit parameter' do
        5.times { |i| create(:queue_session, office_hour: office_hour, started_at: i.days.ago) }
        expect(office_hour.recent_sessions(limit: 3).count).to eq(3)
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