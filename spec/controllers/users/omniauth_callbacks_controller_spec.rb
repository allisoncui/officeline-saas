require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  it 'can be instantiated' do
    expect(controller).to be_a(Users::OmniauthCallbacksController)
  end

  it 'inherits from Devise::OmniauthCallbacksController' do
    expect(Users::OmniauthCallbacksController.superclass).to eq(Devise::OmniauthCallbacksController)
  end

  it 'loads the controller class' do
    # Ensure the class definition is executed
    expect(Users::OmniauthCallbacksController).to be_a(Class)
  end
end

