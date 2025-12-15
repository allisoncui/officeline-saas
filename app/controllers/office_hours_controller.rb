class OfficeHoursController < ApplicationController
  before_action :set_office_hour, only: %i[ show edit update destroy queue_status start_queue soft_close_queue hard_close_queue ]
  before_action :authorize_ta_access, only: [:edit, :update, :destroy]
  before_action :authorize_ta_for_queue, only: [:start_queue, :soft_close_queue, :hard_close_queue]

  # GET /office_hours or /office_hours.json
  def index
    @all_days = OfficeHour.all_days

    raw_days = params[:days]

    raw_days = raw_days.keys if raw_days.is_a?(ActionController::Parameters) ||
                                raw_days.is_a?(Hash)

    if raw_days.present?
      @days_to_show = Array(raw_days).reject(&:blank?)
      session[:days] = @days_to_show
    else
      @days_to_show = session[:days] || @all_days
    end

    sort_param = params[:sort_by].presence_in(%w[course_name instructor day])

    if sort_param
        @sort_by = sort_param
        session[:sort_by] = @sort_by
    else
        @sort_by = session[:sort_by] || "course_name"
    end

    # role based logic
    if current_user&.ta?
      # fetch only this TA's own hours (course is implied by TA's course_name)
      @my_office_hours = OfficeHour.where(course_name: current_user.course_name, ta_uni: current_user.uni)
    
      # Handle view parameter: 'dashboard' or 'my'
      @view = params[:view].presence_in(%w[dashboard my]) || 'dashboard'
      
      if @view == 'my'
        @office_hours = @my_office_hours
      else
        # Dashboard view - collect analytics from queue sessions
        @office_hours = nil
        @sessions = QueueSession.joins(:office_hour)
                                .where(office_hours: { course_name: current_user.course_name })
                                .order(started_at: :desc)
                                .limit(20)
                                .includes(:office_hour, :queue_entries)

        # Analytics — all questions for this course
        @questions = Question.joins(:office_hour)
        .where(office_hours: { course_name: current_user.course_name })

        # Breakdown by type (for pie chart)
        @question_breakdown = @questions.group(:question_type).count

        # KPI metrics
        @total_questions = @questions.count
        @total_sessions  = @sessions.count
        @avg_questions_per_session = @total_sessions > 0 ? (@total_questions.to_f / @total_sessions).round(1) : 0

        # Most common question type
        @most_common_type = @question_breakdown.max_by { |_k, v| v }&.first&.titleize || "N/A"

        # Busiest hour (by question creation time)
        @busiest_hour = @questions
          .group("strftime('%H', questions.created_at)")
          .count
          .max_by { |_k, v| v }
        &.first

      end
    
      render :ta_index
    else    
      @saved_class_names = current_user.saved_classes if current_user&.student?
      @office_hours = OfficeHour.where(day: @days_to_show)

      # Apply search filter if search parameter is present
      if params[:search].present?
        search_term = "%#{params[:search].strip}%"
        @office_hours = @office_hours.where(
          "course_name LIKE ? OR instructor LIKE ? OR location LIKE ?",
          search_term, search_term, search_term
        )
      end

      case @sort_by
        when "instructor"
          @office_hours = @office_hours.order(:instructor, :course_name, :day, :start_time)

        when "day"
          day_order = OfficeHour.all_days
        
          @office_hours = @office_hours.sort_by do |oh|
            [
              day_order.index(oh.day) || 99,
              DateTime.strptime(oh.start_time, "%I:%M%p").strftime("%H:%M")
            ]
          end            

        else 
          @office_hours = @office_hours.order(:course_name, :day, :start_time)
        end
      if @sort_by == "day"
        @office_hours_by_course = { "All Office Hours" => @office_hours }
      else
        @office_hours_by_course = @office_hours.group_by(&:course_name)
      end

      render :student_index
    end    

  end

  # GET /office_hours/1 or /office_hours/1.json
  def show
  end

  # GET /office_hours/new
  def new
    @office_hour = OfficeHour.new
  end

  # GET /office_hours/1/edit
  def edit
  end

  # POST /office_hours or /office_hours.json
  def create
    @office_hour = OfficeHour.new(office_hour_params)
    @office_hour.course_name = current_user.course_name
    @office_hour.ta_uni = current_user.uni if current_user&.ta? # automatically assign TA UNI if logged in as TA

    respond_to do |format|
      if @office_hour.save
        format.html { redirect_to @office_hour, notice: "Office hour was successfully created." }
        format.json { render :show, status: :created, location: @office_hour }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @office_hour.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /office_hours/1 or /office_hours/1.json
  def update
    respond_to do |format|
      if @office_hour.update(office_hour_params)
        format.html { redirect_to @office_hour, notice: "Office hour was successfully updated." }
        format.json { render :show, status: :ok, location: @office_hour }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @office_hour.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /office_hours/1 or /office_hours/1.json
  def destroy
    @office_hour.destroy!

    respond_to do |format|
      format.html do
        redirect_to office_hours_path(view: 'my'),
                    status: :see_other,
                    notice: "Office hour was successfully destroyed."
      end      
      format.json { head :no_content }
    end
  end

  # Queue management actions
  def start_queue
    @office_hour.start_queue!
    redirect_to @office_hour, notice: "Queue started successfully!"
  end

  def soft_close_queue
    @office_hour.soft_close_queue!
    
    waiting_count = @office_hour.queue_entries.where(status: 'waiting').count
    
    redirect_to @office_hour, 
      notice: "Queue closed to new students. #{waiting_count} student(s) still waiting to be served."
  end

  def hard_close_queue
    removed_count = @office_hour.queue_entries.where(status: 'waiting').count
    @office_hour.hard_close_queue!
    
    redirect_to @office_hour, 
      notice: "Queue closed and #{removed_count} student(s) removed from queue."
  end

  def queue_status
    render partial: 'queue_section', locals: { office_hour: @office_hour }
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_office_hour
      @office_hour = OfficeHour.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def office_hour_params
      params.require(:office_hour).permit(:instructor, :day, :start_time, :end_time, :location, :ta_uni)
    end

    # For editing/deleting office hours - check course match
    def authorize_ta_access
      unless current_user&.ta? && @office_hour.course_name == current_user.course_name
        redirect_to office_hours_path, alert: "You can only modify office hours for your course."
      end
    end
    
    # For queue management - just check if user is a TA (more permissive like old logic)
    def authorize_ta_for_queue
      unless current_user&.ta?
        redirect_to @office_hour, alert: "Only TAs can manage the queue."
      end
    end
end