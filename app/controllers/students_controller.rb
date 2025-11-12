class StudentsController < ApplicationController
  before_action :ensure_student

  def show
    @all_days = OfficeHour.all_days
    
    # Handle day filtering
    raw_days = params[:days]
    raw_days = raw_days.keys if raw_days.is_a?(ActionController::Parameters) ||
                                raw_days.is_a?(Hash)
    
    if raw_days.present?
      @days_to_show = Array(raw_days).reject(&:blank?)
      session[:my_classes_days] = @days_to_show
    else
      @days_to_show = session[:my_classes_days] || @all_days
    end
    
    # Handle sorting
    sort_param = params[:sort_by].presence_in(%w[course_name instructor day])
    
    if sort_param
      @sort_by = sort_param
      session[:my_classes_sort_by] = @sort_by
    else
      @sort_by = session[:my_classes_sort_by] || "course_name"
    end
    
    # Get saved office hours and apply filters
    base_office_hours = current_user.saved_office_hours.includes(:questions)
    @saved_office_hours = OfficeHour.with_filters(@days_to_show, @sort_by)
                                      .where(id: base_office_hours.pluck(:id))
  end

  def questions
    # Get all questions submitted by this student, grouped by office hour
    @my_questions = current_user.questions.includes(:office_hour)
                                 .order(created_at: :desc)
                                 .group_by(&:office_hour)
  end

  private

  def ensure_student
    unless current_user&.student?
      redirect_to office_hours_path, alert: 'Students only.'
    end
  end
end

