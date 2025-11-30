class StudentsController < ApplicationController
  before_action :ensure_student

  def show
    # Show saved classes with all office hours for each class
    @saved_class_names = current_user.saved_classes
    @classes_with_office_hours = {}
    
    @saved_class_names.each do |course_name|
      @classes_with_office_hours[course_name] = OfficeHour.where(course_name: course_name).order(:day, :start_time)
    end
  end

  def my_hours
    @all_days = OfficeHour.all_days
    
    # Handle day filtering
    raw_days = params[:days]
    raw_days = raw_days.keys if raw_days.is_a?(ActionController::Parameters) ||
                                raw_days.is_a?(Hash)
    
    if raw_days.present?
      @days_to_show = Array(raw_days).reject(&:blank?)
      session[:my_hours_days] = @days_to_show
    else
      @days_to_show = session[:my_hours_days] || @all_days
    end
    
    # Handle sorting
    sort_param = params[:sort_by].presence_in(%w[course_name instructor day])
    
    if sort_param
      @sort_by = sort_param
      session[:my_hours_sort_by] = @sort_by
    else
      @sort_by = session[:my_hours_sort_by] || "course_name"
    end
    
    # Get selected office hours and apply filters
    base_office_hours = current_user.saved_office_hours.includes(:questions)
    @my_office_hours = OfficeHour.with_filters(@days_to_show, @sort_by)
                                 .where(id: base_office_hours.pluck(:id))
  end

  def save_class
    course_name = params[:course_name]
    
    if course_name.present?
      current_user.add_saved_class(course_name)
      redirect_back fallback_location: office_hours_path, notice: "Class '#{course_name}' saved to My Classes."
    else
      redirect_back fallback_location: office_hours_path, alert: 'Could not save class.'
    end
  end

  def remove_class
    course_name = params[:course_name]
    
    if course_name.present?
      current_user.remove_saved_class(course_name)
      redirect_back fallback_location: student_profile_path, notice: "Class '#{course_name}' removed from My Classes."
    else
      redirect_back fallback_location: student_profile_path, alert: 'Could not remove class.'
    end
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

