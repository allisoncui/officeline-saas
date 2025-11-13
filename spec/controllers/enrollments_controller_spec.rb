require 'rails_helper'

RSpec.describe EnrollmentsController, type: :controller do
  let(:student) { create(:user, role: 'student', uni: 'student123') }
  let(:ta) { create(:user, role: 'ta', uni: 'ta123') }
  let(:office_hour) { create(:office_hour) }

  describe 'POST #create' do
    context 'as a student' do
      before { sign_in student }

      it 'creates a new enrollment' do
        expect {
          post :create, params: { office_hour_id: office_hour.id }
        }.to change(Enrollment, :count).by(1)
      end

      it 'associates enrollment with current user and office hour' do
        post :create, params: { office_hour_id: office_hour.id }
        enrollment = Enrollment.last
        expect(enrollment.user).to eq(student)
        expect(enrollment.office_hour).to eq(office_hour)
      end

      it 'redirects back with success notice' do
        post :create, params: { office_hour_id: office_hour.id }
        expect(response).to redirect_to(office_hours_path)
        expect(flash[:notice]).to match(/saved to your profile/i)
      end

      it 'does not create duplicate enrollment' do
        create(:enrollment, user: student, office_hour: office_hour)
        expect {
          post :create, params: { office_hour_id: office_hour.id }
        }.not_to change(Enrollment, :count)
      end

      it 'handles save failure when enrollment cannot be saved' do
        # Stub OfficeHour.find to return our office_hour
        allow(OfficeHour).to receive(:find).with(office_hour.id.to_s).and_return(office_hour)
        
        # Stub current_user to return our student with stubbed enrollments
        allow(controller).to receive(:current_user).and_return(student)
        
        # Create an enrollment mock that fails to save
        enrollment = instance_double(Enrollment)
        allow(student.enrollments).to receive(:find_or_initialize_by).with(office_hour: office_hour).and_return(enrollment)
        allow(enrollment).to receive(:persisted?).and_return(false)
        allow(enrollment).to receive(:save).and_return(false)
        
        post :create, params: { office_hour_id: office_hour.id }
        expect(response).to redirect_to(office_hours_path)
        expect(flash[:alert]).to match(/Could not save office hour/i)
      end
    end

    context 'as a TA' do
      before { sign_in ta }

      it 'does not allow TAs to save office hours' do
        post :create, params: { office_hour_id: office_hour.id }
        expect(response).to redirect_to(office_hours_path)
        expect(flash[:alert]).to match(/only students/i)
      end
    end
  end

  describe 'DELETE #destroy' do
    before { sign_in student }

    it 'destroys the enrollment' do
      enrollment = create(:enrollment, user: student, office_hour: office_hour)
      expect {
        delete :destroy, params: { office_hour_id: office_hour.id }
      }.to change(Enrollment, :count).by(-1)
    end

    it 'redirects back with success notice' do
      create(:enrollment, user: student, office_hour: office_hour)
      delete :destroy, params: { office_hour_id: office_hour.id }
      expect(response).to redirect_to(office_hours_path)
      expect(flash[:notice]).to match(/removed from your saved list/i)
    end

    it 'handles non-existent enrollment gracefully' do
      delete :destroy, params: { office_hour_id: office_hour.id }
      expect(response).to redirect_to(office_hours_path)
    end
  end
end

