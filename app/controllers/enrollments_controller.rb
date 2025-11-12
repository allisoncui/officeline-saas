class EnrollmentsController < ApplicationController
  before_action :set_office_hour

  def create
    unless current_user.student?
      redirect_back fallback_location: office_hours_path, alert: 'Only students can save office hours.'
      return
    end

    enrollment = current_user.enrollments.find_or_initialize_by(office_hour: @office_hour)

    if enrollment.persisted? || enrollment.save
      redirect_back fallback_location: office_hours_path, notice: 'Office hour saved to your profile.'
    else
      redirect_back fallback_location: office_hours_path, alert: 'Could not save office hour.'
    end
  end

  def destroy
    enrollment = current_user.enrollments.find_by(office_hour: @office_hour)
    enrollment&.destroy
    redirect_back fallback_location: office_hours_path, notice: 'Office hour removed from your saved list.'
  end

  private

  def set_office_hour
    @office_hour = OfficeHour.find(params[:office_hour_id])
  end
end

