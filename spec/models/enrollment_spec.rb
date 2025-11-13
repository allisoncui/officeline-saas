require 'rails_helper'

RSpec.describe Enrollment, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:office_hour) }
  end

  describe 'validations' do
    it 'validates uniqueness of office_hour_id scoped to user_id' do
      user = create(:user)
      office_hour = create(:office_hour)
      create(:enrollment, user: user, office_hour: office_hour)
      
      duplicate = build(:enrollment, user: user, office_hour: office_hour)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:office_hour_id]).to be_present
    end

    it 'allows same office hour for different users' do
      office_hour = create(:office_hour)
      user1 = create(:user)
      user2 = create(:user)
      
      enrollment1 = create(:enrollment, user: user1, office_hour: office_hour)
      enrollment2 = build(:enrollment, user: user2, office_hour: office_hour)
      
      expect(enrollment1).to be_valid
      expect(enrollment2).to be_valid
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:enrollment)).to be_valid
    end
  end
end
