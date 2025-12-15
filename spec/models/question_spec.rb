require 'rails_helper'

RSpec.describe Question, type: :model do
  describe 'associations' do
    it { should belong_to(:office_hour) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    let(:office_hour) { create(:office_hour) }
    let(:user) { create(:user) }
    
    it { should validate_presence_of(:question_text) }
    
    it 'sets default question_type to general if blank' do
      question = build(:question, office_hour: office_hour, user: user, question_type: nil)
      question.valid?
      expect(question.question_type).to eq('general')
    end
    
    it 'validates inclusion of question_type' do
      question = build(:question, office_hour: office_hour, user: user, question_type: 'invalid_type')
      expect(question).not_to be_valid
      expect(question.errors[:question_type]).to be_present
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      office_hour = create(:office_hour)
      user = create(:user)
      question = build(:question, office_hour: office_hour, user: user)
      expect(question).to be_valid
    end
  end

  describe 'basic functionality' do
    let(:office_hour) { create(:office_hour) }
    let(:user) { create(:user) }
    let(:question) { build(:question, office_hour: office_hour, user: user) }

    it 'is valid with valid attributes' do
      expect(question).to be_valid
    end

    it 'is invalid without question_text' do
      question.question_text = nil
      expect(question).to_not be_valid
    end

    it 'sets default question_type to general if nil' do
      question.question_type = nil
      question.valid?
      expect(question.question_type).to eq('general')
      expect(question).to be_valid
    end

    it 'is invalid with invalid question_type' do
      question.question_type = 'invalid_type'
      expect(question).to_not be_valid
    end

    it 'is valid with valid question_type' do
      question.question_type = 'general'
      expect(question).to be_valid
    end

    it 'is invalid without office_hour' do
      question.office_hour = nil
      expect(question).to_not be_valid
    end

    it 'is invalid without user' do
      question.user = nil
      expect(question).to_not be_valid
    end
  end
end