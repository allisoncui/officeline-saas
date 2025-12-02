require 'rails_helper'

RSpec.describe QueueSession, type: :model do
  describe 'associations' do
    it { should belong_to(:office_hour) }
    it { should have_many(:queue_entries).dependent(:nullify) }
  end

  describe 'validations' do
    it { should validate_presence_of(:started_at) }
  end

  describe '#duration_minutes' do
    let(:office_hour) { create(:office_hour) }
    
    it 'returns 0 if started_at is nil' do
      session = QueueSession.new(started_at: nil)
      expect(session.duration_minutes).to eq(0)
    end
    
    it 'calculates duration using ended_at when present' do
      session = create(:queue_session, 
        office_hour: office_hour,
        started_at: 1.hour.ago, 
        ended_at: 30.minutes.ago
      )
      expect(session.duration_minutes).to eq(30)
    end
    
    it 'calculates duration using current time when ended_at is nil' do
      session = create(:queue_session, 
        office_hour: office_hour,
        started_at: 45.minutes.ago, 
        ended_at: nil
      )
      expect(session.duration_minutes).to be_within(1).of(45)
    end
  end

  describe '#students_served' do
    let(:office_hour) { create(:office_hour) }
    let(:session) { create(:queue_session, office_hour: office_hour) }
    
    it 'counts entries with served status' do
      create(:queue_entry, queue_session: session, status: 'served')
      create(:queue_entry, queue_session: session, status: 'served')
      create(:queue_entry, queue_session: session, status: 'waiting')
      
      expect(session.students_served).to eq(2)
    end
  end

  describe '#total_students' do
    let(:office_hour) { create(:office_hour) }
    let(:session) { create(:queue_session, office_hour: office_hour) }
    
    it 'counts all queue entries' do
      create(:queue_entry, queue_session: session, status: 'served')
      create(:queue_entry, queue_session: session, status: 'waiting')
      create(:queue_entry, queue_session: session, status: 'removed')
      
      expect(session.total_students).to eq(3)
    end
  end

  describe '#students_waiting' do
    let(:office_hour) { create(:office_hour) }
    let(:session) { create(:queue_session, office_hour: office_hour) }
    
    it 'counts entries with waiting status' do
      create(:queue_entry, queue_session: session, status: 'waiting')
      create(:queue_entry, queue_session: session, status: 'waiting')
      create(:queue_entry, queue_session: session, status: 'served')
      
      expect(session.students_waiting).to eq(2)
    end
  end

  describe '#students_removed' do
    let(:office_hour) { create(:office_hour) }
    let(:session) { create(:queue_session, office_hour: office_hour) }
    
    it 'counts entries with removed status' do
      create(:queue_entry, queue_session: session, status: 'removed')
      create(:queue_entry, queue_session: session, status: 'waiting')
      
      expect(session.students_removed).to eq(1)
    end
  end

  describe '#service_rate' do
    let(:office_hour) { create(:office_hour) }
    let(:session) { create(:queue_session, office_hour: office_hour) }
    
    it 'returns 0 when no students' do
      expect(session.service_rate).to eq(0)
    end
    
    it 'calculates percentage of students served' do
      create(:queue_entry, queue_session: session, status: 'served')
      create(:queue_entry, queue_session: session, status: 'served')
      create(:queue_entry, queue_session: session, status: 'served')
      create(:queue_entry, queue_session: session, status: 'waiting')
      
      expect(session.service_rate).to eq(75.0)
    end
  end

  describe '#active?' do
    let(:office_hour) { create(:office_hour) }
    
    it 'returns true when ended_at is nil' do
      session = create(:queue_session, office_hour: office_hour, ended_at: nil)
      expect(session.active?).to be true
    end
    
    it 'returns false when ended_at is present' do
      session = create(:queue_session, office_hour: office_hour, ended_at: Time.current)
      expect(session.active?).to be false
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      queue_session = build(:queue_session)
      queue_session.office_hour = create(:office_hour)
      expect(queue_session).to be_valid
    end
  end
end