require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:questions).dependent(:destroy) }
    it { should have_many(:enrollments).dependent(:destroy) }
    it { should have_many(:saved_office_hours).through(:enrollments) }
    it { should have_many(:queue_entries).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:uni) }
    it { should validate_uniqueness_of(:uni).case_insensitive }
    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:role).in_array(%w[student ta]) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end
  end

  describe 'role helpers' do
    describe '#ta?' do
      it 'returns true for ta role' do
        user = build(:user, role: 'ta')
        expect(user.ta?).to be true
      end

      it 'returns false for student role' do
        user = build(:user, role: 'student')
        expect(user.ta?).to be false
      end
    end

    describe '#student?' do
      it 'returns true for student role' do
        user = build(:user, role: 'student')
        expect(user.student?).to be true
      end

      it 'returns false for ta role' do
        user = build(:user, role: 'ta')
        expect(user.student?).to be false
      end
    end
  end

  describe 'Devise configuration' do
    it 'does not require email' do
      user = build(:user)
      expect(user.email_required?).to be false
    end

    it 'returns false for email_changed?' do
      user = build(:user)
      expect(user.email_changed?).to be false
    end

    it 'returns false for will_save_change_to_email?' do
      user = build(:user)
      expect(user.will_save_change_to_email?).to be false
    end

    it 'uses uni for authentication' do
      user = create(:user, uni: 'test123')
      expect(user.uni).to eq('test123')
    end
  end
end
