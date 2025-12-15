require 'rails_helper'

RSpec.describe QueueEntriesController, type: :controller do
  let(:student) { create(:user, :student, uni: 'student123') }
  let(:ta) { create(:user, :ta, uni: 'ta123', course_name: 'Engineering SaaS') }
  let(:office_hour) { create(:office_hour) }

  describe 'POST #create' do
    context 'when queue is active' do
      let!(:queue_session) { create(:queue_session, office_hour: office_hour, ended_at: nil) }
      
      before do
        sign_in student
        office_hour.update(queue_active: true)
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
      end

      it 'associates entry with current queue session' do
        post :create, params: { office_hour_id: office_hour.id }
        entry = QueueEntry.last
        expect(entry.queue_session).to eq(queue_session)
      end

      it 'redirects with success notice' do
        post :create, params: { office_hour_id: office_hour.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:notice]).to match(/joined the queue/i)
      end

      it 'prevents duplicate entries' do
        create(:queue_entry, office_hour: office_hour, user: student)
        post :create, params: { office_hour_id: office_hour.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/already in the queue/i)
      end

      it 'handles save failure with "already in queue" validation error (race condition)' do
        allow_any_instance_of(OfficeHour).to receive(:user_in_queue?).and_return(false)
        allow_any_instance_of(OfficeHour).to receive_message_chain(:queue_entries, :where).and_return(QueueEntry.none)
        
        entry = QueueEntry.new(office_hour: office_hour, user: student, queue_session: queue_session)
        allow_any_instance_of(OfficeHour).to receive_message_chain(:queue_entries, :build).and_return(entry)
        allow_any_instance_of(OfficeHour).to receive_message_chain(:queue_sessions, :find_by).and_return(queue_session)
        
        allow(entry).to receive(:save).and_return(false)
        allow(entry).to receive(:reload)
        
        errors_object = ActiveModel::Errors.new(entry)
        errors_object.add(:user_id, "already in queue")
        allow(entry).to receive(:errors).and_return(errors_object)
        
        post :create, params: { office_hour_id: office_hour.id }
        
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/someone joined at the same time/i)
      end

      it 'handles save failure with other validation errors' do
        # Stub to force a different validation error
        allow_any_instance_of(QueueEntry).to receive(:save).and_return(false)
        allow_any_instance_of(QueueEntry).to receive(:errors).and_return(
          double(:[]).tap { |d| allow(d).to receive(:[]).with(:user_id).and_return([]) }
        )
        
        post :create, params: { office_hour_id: office_hour.id }
        
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/unable to join queue/i)
      end
    end

    context 'when queue is inactive' do
      before { sign_in student }

      it 'redirects with alert' do
        office_hour.update(queue_active: false)
        post :create, params: { office_hour_id: office_hour.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/not currently active/i)
      end
    end
  end

  describe 'DELETE #destroy' do
    before { sign_in student }

    it 'marks the queue entry as removed (not destroyed)' do
      entry = create(:queue_entry, office_hour: office_hour, user: student, status: 'waiting')
      
      expect {
        delete :destroy, params: { office_hour_id: office_hour.id, id: entry.id }
      }.to_not change(QueueEntry, :count)
      
      expect(entry.reload.status).to eq('removed')
    end

    it 'redirects with success notice' do
      entry = create(:queue_entry, office_hour: office_hour, user: student, status: 'waiting')
      delete :destroy, params: { office_hour_id: office_hour.id, id: entry.id }
      expect(response).to redirect_to(office_hour)
      expect(flash[:notice]).to match(/left the queue/i)
    end

    it 'handles non-existent entry' do
      delete :destroy, params: { office_hour_id: office_hour.id, id: 999 }
      expect(response).to redirect_to(office_hour)
      expect(flash[:alert]).to match(/not in the queue/i)
    end
  end

  describe 'DELETE #remove_student' do
    before { sign_in ta }

    let(:student2) { create(:user, :student, uni: 'student456') }

    it 'marks the student as served (not destroyed)' do
      entry = create(:queue_entry, office_hour: office_hour, user: student2, status: 'waiting')
      
      expect {
        delete :remove_student, params: { office_hour_id: office_hour.id, id: entry.id }
      }.to_not change(QueueEntry, :count)
      
      expect(entry.reload.status).to eq('served')
    end

    it 'keeps the entry for analytics' do
      entry = create(:queue_entry, office_hour: office_hour, user: student2, status: 'waiting')
      entry_id = entry.id
      
      delete :remove_student, params: { office_hour_id: office_hour.id, id: entry_id }
      
      expect(QueueEntry.find_by(id: entry_id)).to be_present
      expect(QueueEntry.find_by(id: entry_id).status).to eq('served')
    end

    it 'redirects with success notice' do
      entry = create(:queue_entry, office_hour: office_hour, user: student2)
      delete :remove_student, params: { office_hour_id: office_hour.id, id: entry.id }
      expect(response).to redirect_to(office_hour)
      expect(flash[:notice]).to match(/removed from queue/i)
    end

    context 'as a student' do
      before { sign_in student }

      it 'denies access' do
        entry = create(:queue_entry, office_hour: office_hour, user: student2)
        delete :remove_student, params: { office_hour_id: office_hour.id, id: entry.id }
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/only tas/i)
      end
    end
  end

  describe 'POST #start_queue' do
    context 'as a TA' do
      before { sign_in ta }

      it 'starts the queue successfully' do
        expect(office_hour.queue_active?).to be false
        
        post :start_queue, params: { office_hour_id: office_hour.id }
        
        expect(office_hour.reload.queue_active?).to be true
        expect(response).to redirect_to(office_hour)
        expect(flash[:notice]).to match(/queue has been started/i)
      end

      it 'calls start_queue! on the office hour' do
        allow(controller).to receive(:set_office_hour).and_call_original
        expect_any_instance_of(OfficeHour).to receive(:start_queue!)
        post :start_queue, params: { office_hour_id: office_hour.id }
      end
    end

    context 'as a student' do
      before { sign_in student }

      it 'denies access and redirects with alert' do
        post :start_queue, params: { office_hour_id: office_hour.id }
        
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/only tas can start the queue/i)
        expect(office_hour.reload.queue_active?).to be false
      end
    end

    context 'when not signed in' do
      it 'redirects to sign in page' do
        post :start_queue, params: { office_hour_id: office_hour.id }
        
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST #close_queue' do
    context 'as a TA' do
      before { sign_in ta }

      it 'closes the queue successfully' do
        office_hour.update(queue_active: true)
        expect(office_hour.queue_active?).to be true
        
        post :close_queue, params: { office_hour_id: office_hour.id }
        
        expect(office_hour.reload.queue_active?).to be false
        expect(response).to redirect_to(office_hour)
        expect(flash[:notice]).to match(/queue has been closed/i)
      end

      it 'calls close_queue! on the office hour' do
        office_hour.update(queue_active: true)
        allow(controller).to receive(:set_office_hour).and_call_original
        expect_any_instance_of(OfficeHour).to receive(:close_queue!)
        post :close_queue, params: { office_hour_id: office_hour.id }
      end
    end

    context 'as a student' do
      before { sign_in student }

      it 'denies access and redirects with alert' do
        office_hour.update(queue_active: true)
        
        post :close_queue, params: { office_hour_id: office_hour.id }
        
        expect(response).to redirect_to(office_hour)
        expect(flash[:alert]).to match(/only tas can close the queue/i)
        expect(office_hour.reload.queue_active?).to be true
      end
    end

    context 'when not signed in' do
      it 'redirects to sign in page' do
        post :close_queue, params: { office_hour_id: office_hour.id }
        
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end