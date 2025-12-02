require 'rails_helper'

RSpec.describe QueueEntry, type: :model do
  describe 'associations' do
    it { should belong_to(:office_hour) }
    it { should belong_to(:user) }
    it { should belong_to(:queue_session).optional }
  end

  describe 'validations' do
    it 'validates uniqueness of user_id scoped to office_hour_id' do
      office_hour = create(:office_hour)
      user = create(:user, :student)
      create(:queue_entry, office_hour: office_hour, user: user)
      duplicate = build(:queue_entry, office_hour: office_hour, user: user)
      
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("is already in this queue")
    end

    it 'allows same user for different office hours' do
      office_hour1 = create(:office_hour)
      office_hour2 = create(:office_hour)
      user = create(:user, :student)
      
      entry1 = create(:queue_entry, office_hour: office_hour1, user: user)
      entry2 = build(:queue_entry, office_hour: office_hour2, user: user)
      
      expect(entry1).to be_valid
      expect(entry2).to be_valid
    end

    it 'validates status inclusion' do
      entry = build(:queue_entry, status: 'invalid_status')
      expect(entry).not_to be_valid
      expect(entry.errors[:status]).to be_present
    end
  end

  describe 'scopes' do
    let(:office_hour) { create(:office_hour) }

    describe '.active' do
      it 'returns only waiting entries ordered by joined_at' do
        entry1 = create(:queue_entry, office_hour: office_hour, status: 'waiting', joined_at: 2.minutes.ago)
        entry2 = create(:queue_entry, office_hour: office_hour, status: 'served')
        entry3 = create(:queue_entry, office_hour: office_hour, status: 'waiting', joined_at: 1.minute.ago)
        
        active_entries = QueueEntry.active
        expect(active_entries).to eq([entry1, entry3])
      end
    end

    describe '.for_office_hour' do
      it 'returns entries for specific office hour' do
        office_hour2 = create(:office_hour)
        entry1 = create(:queue_entry, office_hour: office_hour)
        entry2 = create(:queue_entry, office_hour: office_hour2)
        
        entries = QueueEntry.for_office_hour(office_hour.id)
        expect(entries).to include(entry1)
        expect(entries).not_to include(entry2)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_create :set_joined_at' do
      it 'sets joined_at automatically' do
        entry = build(:queue_entry, joined_at: nil)
        entry.save
        expect(entry.joined_at).to be_present
      end

      it 'does not override existing joined_at' do
        time = 1.hour.ago
        entry = create(:queue_entry, joined_at: time)
        expect(entry.joined_at).to be_within(1.second).of(time)
      end
    end

    describe 'after_create :update_positions' do
      it 'assigns positions in order of creation' do
        office_hour = create(:office_hour)
        entry1 = create(:queue_entry, office_hour: office_hour)
        entry2 = create(:queue_entry, office_hour: office_hour)
        entry3 = create(:queue_entry, office_hour: office_hour)
        
        expect(entry1.reload.position).to eq(1)
        expect(entry2.reload.position).to eq(2)
        expect(entry3.reload.position).to eq(3)
      end
    end

    describe 'after_update :update_positions' do
      it 'recalculates positions after status change' do
        office_hour = create(:office_hour)
        entry1 = create(:queue_entry, office_hour: office_hour, position: 1, status: 'waiting')
        entry2 = create(:queue_entry, office_hour: office_hour, position: 2, status: 'waiting')
        
        # Mark entry1 as served (not destroyed, just status change)
        entry1.update(status: 'served')
        
        # entry2 should now be position 1
        expect(entry2.reload.position).to eq(1)
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:queue_entry)).to be_valid
    end
  end
end