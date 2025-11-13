require 'rails_helper'

RSpec.describe Users::UnlocksController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  it 'can be instantiated' do
    expect(controller).to be_a(Users::UnlocksController)
  end

  it 'inherits from Devise::UnlocksController' do
    expect(Users::UnlocksController.superclass).to eq(Devise::UnlocksController)
  end

  it 'loads the controller class' do
    # Ensure the class definition is executed
    expect(Users::UnlocksController).to be_a(Class)
  end
end

