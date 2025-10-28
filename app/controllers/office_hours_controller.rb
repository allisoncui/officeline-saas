class OfficeHoursController < ApplicationController
  before_action :set_office_hour, only: %i[ show edit update destroy ]

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
  
    @office_hours = OfficeHour.with_filters(@days_to_show, @sort_by)
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_office_hour
      @office_hour = OfficeHour.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def office_hour_params
      params.require(:office_hour).permit(:course_name, :instructor, :day, :start_time, :end_time, :location)
    end
end