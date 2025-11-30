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

  describe 'email attribute' do
    it 'has email as an accessor' do
      user = build(:user)
      user.email = 'test@example.com'
      expect(user.email).to eq('test@example.com')
    end

    it 'allows email to be set and retrieved' do
      user = build(:user)
      user.email = 'user@columbia.edu'
      expect(user.email).to eq('user@columbia.edu')
    end
  end

  describe 'saved_classes' do
    let(:user) { create(:user) }

    describe '#saved_class?' do
      it 'returns true when course is saved' do
        user.update(saved_classes: ['Engineering SaaS', 'Math 101'])
        expect(user.saved_class?('Engineering SaaS')).to be true
      end

      it 'returns false when course is not saved' do
        user.update(saved_classes: ['Engineering SaaS'])
        expect(user.saved_class?('Math 101')).to be false
      end

      it 'returns false when saved_classes is empty' do
        user.update(saved_classes: [])
        expect(user.saved_class?('Engineering SaaS')).to be false
      end
    end

    describe '#add_saved_class' do
      it 'adds a new class to saved_classes' do
        user.update(saved_classes: [])
        user.add_saved_class('Engineering SaaS')
        expect(user.saved_classes).to include('Engineering SaaS')
      end

      it 'does not add duplicate classes' do
        user.update(saved_classes: ['Engineering SaaS'])
        user.add_saved_class('Engineering SaaS')
        expect(user.saved_classes.count('Engineering SaaS')).to eq(1)
      end

      it 'preserves existing classes when adding new one' do
        user.update(saved_classes: ['Math 101'])
        user.add_saved_class('Engineering SaaS')
        expect(user.saved_classes).to include('Math 101', 'Engineering SaaS')
      end
    end

    describe '#remove_saved_class' do
      it 'removes a class from saved_classes' do
        user.update(saved_classes: ['Engineering SaaS', 'Math 101'])
        user.remove_saved_class('Engineering SaaS')
        expect(user.saved_classes).not_to include('Engineering SaaS')
        expect(user.saved_classes).to include('Math 101')
      end

      it 'does nothing if class is not in saved_classes' do
        user.update(saved_classes: ['Math 101'])
        user.remove_saved_class('Engineering SaaS')
        expect(user.saved_classes).to eq(['Math 101'])
      end
    end

    describe '#saved_class_office_hours' do
      it 'returns office hours for saved classes' do
        oh1 = create(:office_hour, course_name: 'Engineering SaaS')
        oh2 = create(:office_hour, course_name: 'Math 101')
        oh3 = create(:office_hour, course_name: 'Physics')
        
        user.update(saved_classes: ['Engineering SaaS', 'Math 101'])
        office_hours = user.saved_class_office_hours
        
        expect(office_hours).to include(oh1, oh2)
        expect(office_hours).not_to include(oh3)
      end

      it 'returns empty when no classes are saved' do
        user.update(saved_classes: [])
        expect(user.saved_class_office_hours).to be_empty
      end
    end
  end
end
