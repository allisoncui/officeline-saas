require 'rails_helper'

RSpec.describe QueueEntry, type: :model do
  describe 'associations' do
    it { should belong_to(:office_hour) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_inclusion_of(:status).in_array(%w[waiting served removed]) }
    
    it 'validates uniqueness of user_id scoped to office_hour_id' do
      user = create(:user)
      office_hour = create(:office_hour)
      create(:queue_entry, user: user, office_hour: office_hour)
      
      duplicate = build(:queue_entry, user: user, office_hour: office_hour)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("already in queue")
    end
  end

  describe 'scopes' do
    let(:office_hour) { create(:office_hour) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    describe '.active' do
      it 'returns only waiting entries' do
        waiting = create(:queue_entry, office_hour: office_hour, user: user1, status: 'waiting')
        served = create(:queue_entry, office_hour: office_hour, user: user2, status: 'served')
        
        expect(QueueEntry.active).to include(waiting)
        expect(QueueEntry.active).not_to include(served)
      end

      it 'orders by joined_at' do
        entry1 = create(:queue_entry, office_hour: office_hour, user: user1, status: 'waiting', joined_at: 2.minutes.ago)
        entry2 = create(:queue_entry, office_hour: office_hour, user: user2, status: 'waiting', joined_at: 1.minute.ago)
        
        expect(QueueEntry.active.to_a).to eq([entry1, entry2])
      end
    end

    describe '.for_office_hour' do
      it 'returns entries for specific office hour' do
        office_hour2 = create(:office_hour)
        entry1 = create(:queue_entry, office_hour: office_hour, user: user1)
        entry2 = create(:queue_entry, office_hour: office_hour2, user: user2)
        
        expect(QueueEntry.for_office_hour(office_hour.id)).to include(entry1)
        expect(QueueEntry.for_office_hour(office_hour.id)).not_to include(entry2)
      end
    end
  end

  describe 'callbacks' do
    let(:office_hour) { create(:office_hour) }
    let(:user) { create(:user) }

    describe 'before_create :set_joined_at' do
      it 'sets joined_at to current time if not set' do
        entry = build(:queue_entry, office_hour: office_hour, user: user, joined_at: nil)
        entry.save
        expect(entry.joined_at).to be_present
      end

      it 'does not override existing joined_at' do
        time = 1.hour.ago
        entry = build(:queue_entry, office_hour: office_hour, user: user, joined_at: time)
        entry.save
        expect(entry.joined_at).to be_within(1.second).of(time)
      end
    end

    describe 'after_create :update_positions' do
      it 'sets position based on join order' do
        user1 = create(:user)
        user2 = create(:user)
        user3 = create(:user)
        
        entry1 = create(:queue_entry, office_hour: office_hour, user: user1, status: 'waiting')
        entry2 = create(:queue_entry, office_hour: office_hour, user: user2, status: 'waiting')
        entry3 = create(:queue_entry, office_hour: office_hour, user: user3, status: 'waiting')
        
        expect(entry1.reload.position).to eq(1)
        expect(entry2.reload.position).to eq(2)
        expect(entry3.reload.position).to eq(3)
      end
    end

    describe 'after_destroy :update_positions' do
      it 'recalculates positions after deletion' do
        user1 = create(:user)
        user2 = create(:user)
        user3 = create(:user)
        
        entry1 = create(:queue_entry, office_hour: office_hour, user: user1, status: 'waiting', position: 1)
        entry2 = create(:queue_entry, office_hour: office_hour, user: user2, status: 'waiting', position: 2)
        entry3 = create(:queue_entry, office_hour: office_hour, user: user3, status: 'waiting', position: 3)
        
        entry1.destroy
        
        expect(entry2.reload.position).to eq(1)
        expect(entry3.reload.position).to eq(2)
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:queue_entry)).to be_valid
    end
  end
end
