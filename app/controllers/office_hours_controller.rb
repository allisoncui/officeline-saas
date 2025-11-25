class OfficeHoursController < ApplicationController
  before_action :set_office_hour, only: %i[ show edit update destroy ]
  before_action :authorize_ta_access, only: [:edit, :update, :destroy]

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
      # fetch all office hours under the TA's course
      @all_office_hours = OfficeHour.where(course_name: current_user.course_name)
      
      # fetch only this TA's own hours
      @my_office_hours = @all_office_hours.where(ta_uni: current_user.uni)
    
      # Handle view parameter: 'dashboard', 'my', or 'all'
      @view = params[:view].presence_in(%w[dashboard my all]) || 'dashboard'
      
      if @view == 'my'
        @office_hours = @my_office_hours
      elsif @view == 'all'
        @office_hours = @all_office_hours
      else
        # Dashboard view - collect analytics from queue sessions
        @office_hours = nil
        @sessions = QueueSession.joins(:office_hour)
                                .where(office_hours: { course_name: current_user.course_name })
                                .order(started_at: :desc)
                                .limit(20)
                                .includes(:office_hour, :queue_entries)
      end
    
      render :ta_index
    else
      @office_hours = OfficeHour.with_filters(@days_to_show, @sort_by)
      @saved_office_hour_ids = current_user.saved_office_hours.pluck(:id) if current_user&.student?
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
      format.html { redirect_to office_hours_path, status: :see_other, notice: "Office hour was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def queue_status
    @office_hour = OfficeHour.find(params[:id])
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

    def authorize_ta_access
      @office_hour = OfficeHour.find(params[:id])
      unless @office_hour.ta_uni == current_user.uni
        redirect_to office_hours_path, alert: "You can only modify your own office hours."
      end
    end
end