class QueueEntriesController < ApplicationController
  before_action :set_office_hour
  before_action :ensure_queue_active, only: [:create]
  
  # Student joins queue
  def create
    if @office_hour.user_in_queue?(current_user)
      redirect_to @office_hour, alert: 'You are already in the queue.'
      return
    end
    
    # Find the current active session
    current_session = @office_hour.queue_sessions.find_by(ended_at: nil)
    
    @queue_entry = @office_hour.queue_entries.build(
      user: current_user,
      queue_session: current_session
    )
    
    if @queue_entry.save
      redirect_to @office_hour, notice: "You've joined the queue at position #{@queue_entry.position}."
    else
      if @queue_entry.errors[:user_id].include?("already in queue")
        redirect_to @office_hour, alert: 'Someone joined at the same time. Please refresh and try again.'
      else
        redirect_to @office_hour, alert: 'Unable to join queue. Please try again.'
      end
    end
  end
  
  # Student leaves queue
  def destroy
    @queue_entry = @office_hour.queue_entries.find_by(user: current_user, status: 'waiting')
    
    if @queue_entry
      @queue_entry.update(status: 'removed')
      # DON'T destroy - keep for analytics
      redirect_to @office_hour, notice: 'You have left the queue.'
    else
      redirect_to @office_hour, alert: 'You are not in the queue.'
    end
  end
  
  # TA starts queue
  def start_queue
    unless current_user&.ta?
      redirect_to @office_hour, alert: 'Only TAs can start the queue.'
      return
    end
    
    @office_hour.start_queue!
    redirect_to @office_hour, notice: 'Queue has been started!'
  end
  
  # TA closes queue
  def close_queue
    unless current_user&.ta?
      redirect_to @office_hour, alert: 'Only TAs can close the queue.'
      return
    end
    
    @office_hour.close_queue!
    redirect_to @office_hour, notice: 'Queue has been closed.'
  end
  
  # TA removes a student from queue (marks as served)
  def remove_student
    unless current_user&.ta?
      redirect_to @office_hour, alert: 'Only TAs can remove students from the queue.'
      return
    end
    
    @queue_entry = @office_hour.queue_entries.find(params[:id])
    @queue_entry.update(status: 'served')
    # DON'T destroy - keep for analytics!
    
    redirect_to @office_hour, notice: 'Student removed from queue.'
  end
  
  private
  
  def set_office_hour
    @office_hour = OfficeHour.find(params[:office_hour_id])
  end
  
  def ensure_queue_active
    unless @office_hour.queue_active?
      redirect_to @office_hour, alert: 'The queue is not currently active.'
    end
  end
end