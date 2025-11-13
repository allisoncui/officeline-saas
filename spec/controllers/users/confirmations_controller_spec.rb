require 'rails_helper'

RSpec.describe Users::ConfirmationsController, type: :controller do
  it 'can be instantiated' do
    expect(controller).to be_a(Users::ConfirmationsController)
  end
end

