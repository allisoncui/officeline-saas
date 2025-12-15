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
    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:role).in_array(%w[student ta]) }
    
    it 'validates uniqueness of uni scoped to role' do
      create(:user, uni: 'abc123', role: 'student')
      duplicate = build(:user, uni: 'abc123', role: 'student')
      
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:uni]).to be_present
    end

    it 'includes uni value in uniqueness error message' do
      create(:user, uni: 'abc123', role: 'student')
      duplicate = build(:user, uni: 'abc123', role: 'student')
      duplicate.valid?
      expect(duplicate.errors[:uni].first).to include('abc123')
    end
    
    it 'allows same UNI with different roles' do
      create(:user, uni: 'abc123', role: 'student')
      ta_account = build(:user, uni: 'abc123', role: 'ta', course_name: 'CS 101')
      
      expect(ta_account).to be_valid
    end
    
    it 'validates presence of course_name for TAs' do
      ta = build(:user, role: 'ta', course_name: nil)
      expect(ta).not_to be_valid
      expect(ta.errors[:course_name]).to be_present
    end
    
    it 'does not require course_name for students' do
      student = build(:user, role: 'student', course_name: nil)
      expect(student).to be_valid
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end
  end

  describe 'role helpers' do
    describe '#ta?' do
      it 'returns true for ta role' do
        user = build(:user, role: 'ta', course_name: 'CS 101')
        expect(user.ta?).to be true
      end

      it 'returns false for student role' do
        user = build(:user, role: 'student')
        expect(user.ta?).to be false
      end

      it 'handles uppercase role' do
        user = build(:user, role: 'TA', course_name: 'CS 101')
        expect(user.ta?).to be true
      end

      it 'handles mixed case role' do
        user = build(:user, role: 'Ta', course_name: 'CS 101')
        expect(user.ta?).to be true
      end
    end

    describe '#student?' do
      it 'returns true for student role' do
        user = build(:user, role: 'student')
        expect(user.student?).to be true
      end

      it 'returns false for ta role' do
        user = build(:user, role: 'ta', course_name: 'CS 101')
        expect(user.student?).to be false
      end

      it 'handles uppercase role' do
        user = build(:user, role: 'STUDENT')
        expect(user.student?).to be true
      end

      it 'handles mixed case role' do
        user = build(:user, role: 'Student')
        expect(user.student?).to be true
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

  describe 'dual accounts' do
    describe '.accounts_for_uni' do
      it 'returns all accounts for a given UNI' do
        create(:user, uni: 'abc123', role: 'student')
        create(:user, uni: 'abc123', role: 'ta', course_name: 'CS 101')
        create(:user, uni: 'xyz789', role: 'student')
        
        accounts = User.accounts_for_uni('abc123')
        expect(accounts.count).to eq(2)
        expect(accounts.pluck(:role)).to match_array(%w[student ta])
      end
    end
    
    describe '.available_roles_for_uni' do
      it 'returns available roles when UNI has no accounts' do
        expect(User.available_roles_for_uni('new123')).to match_array(%w[student ta])
      end
      
      it 'returns only student when UNI has TA account' do
        create(:user, uni: 'abc123', role: 'ta', course_name: 'CS 101')
        expect(User.available_roles_for_uni('abc123')).to eq(['student'])
      end
      
      it 'returns only ta when UNI has student account' do
        create(:user, uni: 'abc123', role: 'student')
        expect(User.available_roles_for_uni('abc123')).to eq(['ta'])
      end
      
      it 'returns empty array when UNI has both accounts' do
        create(:user, uni: 'abc123', role: 'student')
        create(:user, uni: 'abc123', role: 'ta', course_name: 'CS 101')
        expect(User.available_roles_for_uni('abc123')).to be_empty
      end
    end
    
    describe '.has_both_accounts?' do
      it 'returns true when UNI has both student and TA accounts' do
        create(:user, uni: 'abc123', role: 'student')
        create(:user, uni: 'abc123', role: 'ta', course_name: 'CS 101')
        
        expect(User.has_both_accounts?('abc123')).to be true
      end
      
      it 'returns false when UNI has only one account' do
        create(:user, uni: 'abc123', role: 'student')
        
        expect(User.has_both_accounts?('abc123')).to be false
      end
    end
    
    describe '#other_account' do
      it 'returns the TA account when called on student' do
        student = create(:user, uni: 'abc123', role: 'student')
        ta = create(:user, uni: 'abc123', role: 'ta', course_name: 'CS 101')
        
        expect(student.other_account).to eq(ta)
      end
      
      it 'returns the student account when called on TA' do
        student = create(:user, uni: 'abc123', role: 'student')
        ta = create(:user, uni: 'abc123', role: 'ta', course_name: 'CS 101')
        
        expect(ta.other_account).to eq(student)
      end
      
      it 'returns nil when no other account exists' do
        student = create(:user, uni: 'abc123', role: 'student')
        
        expect(student.other_account).to be_nil
      end
    end
  end
end