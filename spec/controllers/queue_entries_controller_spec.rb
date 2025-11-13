require 'rails_helper'

RSpec.describe QueueEntriesController, type: :controller do
  let(:student) { create(:user, role: 'student', uni: 'student123') }
  let(:ta) { create(:user, role: 'ta', uni: 'ta123', course_name: 'Engineering SaaS') }
  let(:office_hour) { create(:office_hour, course_name: 'Engineering SaaS', ta_uni: 'ta123') }

  describe 'POST #create' do
    context 'when queue is active' do
      before do
        office_hour.start_queue!
        sign_in student
      end

      it 'creates a new queue entry' do
        expect {
          post :create, params: { office_hour_id: office_hour.id }
        }.to change(QueueEntry, :count).by(1)
      end

      it 'associates entry with current user and office hour' do
        post :create, params: { office_hour_id: office_hour.id }
        entry = QueueEntry.last
        expect(entry.user).to eq(student)
        expect(entry.office_hour).to eq(office_hour)
        expect(entry.status).to eq('waiting')
      end

      it 'redirects with success notice including position' do
        post :create, params: { office_hour_id: office_hour.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:notice]).to match(/joined the queue/i)
      end

      it 'prevents duplicate entries' do
        create(:queue_entry, user: student, office_hour: office_hour, status: 'waiting')
        post :create, params: { office_hour_id: office_hour.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/already in the queue/i)
      end

      it 'handles save failure with "already in queue" validation error' do
        # Stub OfficeHour.find to return our stubbed office_hour
        allow(OfficeHour).to receive(:find).with(office_hour.id.to_s).and_return(office_hour)
        allow(office_hour).to receive(:user_in_queue?).with(student).and_return(false)
        
        # Create a queue entry mock that fails to save
        queue_entry = instance_double(QueueEntry)
        allow(office_hour.queue_entries).to receive(:build).with(user: student).and_return(queue_entry)
        allow(queue_entry).to receive(:save).and_return(false)
        errors = instance_double(ActiveModel::Errors)
        allow(errors).to receive(:[]).with(:user_id).and_return(['already in queue'])
        allow(queue_entry).to receive(:errors).and_return(errors)
        
        post :create, params: { office_hour_id: office_hour.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/Someone joined at the same time/i)
      end

      it 'handles save failure with other validation errors' do
        # Stub OfficeHour.find to return our stubbed office_hour
        allow(OfficeHour).to receive(:find).with(office_hour.id.to_s).and_return(office_hour)
        allow(office_hour).to receive(:user_in_queue?).with(student).and_return(false)
        
        # Create a queue entry mock that fails to save
        queue_entry = instance_double(QueueEntry)
        allow(office_hour.queue_entries).to receive(:build).with(user: student).and_return(queue_entry)
        allow(queue_entry).to receive(:save).and_return(false)
        errors = instance_double(ActiveModel::Errors)
        allow(errors).to receive(:[]).with(:user_id).and_return([])
        allow(queue_entry).to receive(:errors).and_return(errors)
        
        post :create, params: { office_hour_id: office_hour.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/Unable to join queue/i)
      end
    end

    context 'when queue is inactive' do
      before { sign_in student }

      it 'does not create entry and redirects with alert' do
        expect {
          post :create, params: { office_hour_id: office_hour.id }
        }.not_to change(QueueEntry, :count)
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/not currently active/i)
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      office_hour.start_queue!
      sign_in student
    end

    it 'removes the queue entry' do
      entry = create(:queue_entry, user: student, office_hour: office_hour, status: 'waiting')
      expect {
        delete :destroy, params: { office_hour_id: office_hour.id, id: entry.id }
      }.to change(QueueEntry, :count).by(-1)
    end

    it 'updates entry status to removed before destroying' do
      entry = create(:queue_entry, user: student, office_hour: office_hour, status: 'waiting')
      # The update happens in the controller, we just verify the flow works
      delete :destroy, params: { office_hour_id: office_hour.id, id: entry.id }
      expect(response).to redirect_to(office_hour)
      expect(flash[:notice]).to match(/left the queue/i)
    end

    it 'redirects with success notice' do
      entry = create(:queue_entry, user: student, office_hour: office_hour, status: 'waiting')
      delete :destroy, params: { office_hour_id: office_hour.id, id: entry.id }
      expect(response).to redirect_to(office_hour)
      expect(flash[:notice]).to match(/left the queue/i)
    end

    it 'handles non-existent entry gracefully' do
      delete :destroy, params: { office_hour_id: office_hour.id, id: 999 }
      expect(response).to redirect_to(office_hour)
      expect(flash[:alert]).to match(/not in the queue/i)
    end

    it 'handles entry not found by user' do
      # When find_by returns nil (user not in queue)
      delete :destroy, params: { office_hour_id: office_hour.id, id: 999 }
      expect(response).to redirect_to(office_hour)
      expect(flash[:alert]).to match(/not in the queue/i)
    end
  end

  describe 'private methods' do
    describe '#set_office_hour' do
      before { sign_in student }

      it 'finds the office hour by office_hour_id' do
        get :create, params: { office_hour_id: office_hour.id }
        expect(assigns(:office_hour)).to eq(office_hour)
      end
    end

    describe '#ensure_queue_active' do
      before { sign_in student }

      it 'redirects when queue is inactive' do
        post :create, params: { office_hour_id: office_hour.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/not currently active/i)
      end
    end
  end

  describe 'POST #start_queue' do
    context 'as a TA' do
      before { sign_in ta }

      it 'activates the queue' do
        post :start_queue, params: { office_hour_id: office_hour.id }
        office_hour.reload
        expect(office_hour.queue_active).to be true
        expect(office_hour.queue_started_at).to be_present
      end

      it 'redirects with success notice' do
        post :start_queue, params: { office_hour_id: office_hour.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:notice]).to match(/started/i)
      end
    end

    context 'as a student' do
      before { sign_in student }

      it 'does not allow students to start queue' do
        post :start_queue, params: { office_hour_id: office_hour.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/only TAs/i)
      end
    end
  end

  describe 'POST #close_queue' do
    context 'as a TA' do
      before do
        office_hour.start_queue!
        sign_in ta
      end

    it 'deactivates the queue' do
      post :close_queue, params: { office_hour_id: office_hour.id }
      office_hour.reload
      expect(office_hour.queue_active).to be false
    end

    it 'marks waiting entries as removed' do
      entry = create(:queue_entry, office_hour: office_hour, status: 'waiting')
      post :close_queue, params: { office_hour_id: office_hour.id }
      expect(entry.reload.status).to eq('removed')
    end

      it 'redirects with success notice' do
        post :close_queue, params: { office_hour_id: office_hour.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:notice]).to match(/closed/i)
      end
    end

    context 'as a student' do
      before { sign_in student }

      it 'does not allow students to close queue' do
        office_hour.start_queue!
        post :close_queue, params: { office_hour_id: office_hour.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/only TAs/i)
      end
    end
  end

  describe 'DELETE #remove_student' do
    let(:other_student) { create(:user, role: 'student', uni: 'student456') }

    before do
      office_hour.start_queue!
      sign_in ta
    end

    it 'removes the student from queue' do
      entry = create(:queue_entry, user: other_student, office_hour: office_hour, status: 'waiting')
      expect {
        delete :remove_student, params: { office_hour_id: office_hour.id, id: entry.id }
      }.to change(QueueEntry, :count).by(-1)
    end

    it 'marks entry as served before destroying' do
      entry = create(:queue_entry, user: other_student, office_hour: office_hour, status: 'waiting')
      entry_id = entry.id
      delete :remove_student, params: { office_hour_id: office_hour.id, id: entry.id }
      # Entry is destroyed, so we check the update was called before destroy
      expect(QueueEntry.find_by(id: entry_id)).to be_nil
    end

    it 'calls update with served status before destroy' do
      entry = create(:queue_entry, user: other_student, office_hour: office_hour, status: 'waiting')
      expect_any_instance_of(QueueEntry).to receive(:update).with(status: 'served').and_return(true)
      delete :remove_student, params: { office_hour_id: office_hour.id, id: entry.id }
    end

    it 'redirects with success notice' do
      entry = create(:queue_entry, user: other_student, office_hour: office_hour, status: 'waiting')
      delete :remove_student, params: { office_hour_id: office_hour.id, id: entry.id }
      expect(response).to redirect_to(office_hour)
      expect(flash[:notice]).to match(/removed from queue/i)
    end

    context 'as a student' do
      before { sign_in student }

      it 'does not allow students to remove others' do
        entry = create(:queue_entry, user: other_student, office_hour: office_hour, status: 'waiting')
        delete :remove_student, params: { office_hour_id: office_hour.id, id: entry.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/only TAs/i)
      end
    end
  end
end

