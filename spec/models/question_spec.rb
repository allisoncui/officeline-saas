require 'rails_helper'

RSpec.describe Question, type: :model do
  describe 'associations' do
    it { should belong_to(:office_hour) }
  end

  describe 'validations' do
    it { should validate_presence_of(:question_text) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      office_hour = create(:office_hour)
      question = build(:question, office_hour: office_hour)
      expect(question).to be_valid
    end
  end

  describe 'basic functionality' do
    let(:office_hour) { create(:office_hour) }
    let(:question) { build(:question, office_hour: office_hour) }

    it 'is valid with valid attributes' do
      expect(question).to be_valid
    end

    it 'is invalid without question_text' do
      question.question_text = nil
      expect(question).to_not be_valid
    end

    it 'is invalid without office_hour' do
      question.office_hour = nil
      expect(question).to_not be_valid
    end
  end
end