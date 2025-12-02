require 'rails_helper'

RSpec.describe Users::RegistrationsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe 'GET #new' do
    it 'sets role from params' do
      get :new, params: { role: 'ta' }
      expect(assigns(:role)).to eq('ta')
    end

    it 'defaults to student role' do
      get :new
      expect(assigns(:role)).to eq('student')
    end
  end

  describe 'POST #create' do
    context 'with valid student params' do
      it 'creates a new student user' do
        expect {
          post :create, params: {
            user: {
              uni: 'newstudent',
              role: 'student',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }
        }.to change(User, :count).by(1)
      end
    end

    context 'with valid TA params' do
      it 'creates a new TA user' do
        expect {
          post :create, params: {
            user: {
              uni: 'newta',
              role: 'ta',
              course_name: 'CS 101',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }
        }.to change(User, :count).by(1)
      end
    end

    context 'with invalid params' do
      it 'does not create user without password' do
        expect {
          post :create, params: {
            user: {
              uni: 'newuser',
              role: 'student',
              password: ''
            }
          }
        }.not_to change(User, :count)
      end
    end

    it 'sets @role before calling super' do
      post :create, params: {
        user: {
          uni: 'newuser',
          role: 'ta',
          course_name: 'CS 101',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
      expect(assigns(:role)).to eq('ta')
    end
  end
end