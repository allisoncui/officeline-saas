require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  it 'can be instantiated' do
    expect(controller).to be_a(Users::OmniauthCallbacksController)
  end
end

