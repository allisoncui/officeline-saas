require 'rails_helper'

RSpec.describe Users::ConfirmationsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  it 'can be instantiated' do
    expect(controller).to be_a(Users::ConfirmationsController)
  end

  it 'inherits from Devise::ConfirmationsController' do
    expect(Users::ConfirmationsController.superclass).to eq(Devise::ConfirmationsController)
  end

  it 'loads the controller class' do
    # Ensure the class definition is executed
    expect(Users::ConfirmationsController).to be_a(Class)
  end
end

