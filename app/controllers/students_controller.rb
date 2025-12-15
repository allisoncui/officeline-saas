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
    
    # Base relation: all saved office hours for this student, filtered by day
    saved_scope = current_user.saved_office_hours
                          .where(day: @days_to_show)
                          .includes(:questions)
    base_scope =
      if saved_scope.exists?
        saved_scope
      else
        OfficeHour.where(day: @days_to_show).includes(:questions)
      end
  
    # Apply sorting
    case @sort_by
    when "instructor"
      @my_office_hours = base_scope.order(instructor: :asc)
    when "day"
      # Day-of-week + time ordering
      day_order = OfficeHour.all_days
      @my_office_hours = base_scope.to_a.sort_by do |oh|
        [
          day_order.index(oh.day) || 99,
          Time.strptime(oh.start_time, "%I:%M%p")
        ]
      end    
    else # "course_name"
      @my_office_hours = base_scope.order(course_name: :asc)
    end
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
    @all_question_types = Question::QUESTION_TYPES.map { |_, value| value }
    
    # Handle question type filtering (single selection from dropdown)
    selected_type = params[:question_type].presence
    
    if selected_type.present?
      if selected_type == 'all'
        @selected_question_type = 'all'
        session[:my_questions_type] = nil 
      else
        @selected_question_type = selected_type
        session[:my_questions_type] = @selected_question_type
      end
    else
      # Use session value if available, otherwise default to 'all'
      @selected_question_type = session[:my_questions_type] || 'all'
    end
    
    questions = current_user.questions.includes(:office_hour)
    
    if @selected_question_type != 'all'
      questions = questions.where(question_type: @selected_question_type)
    end
    
    questions = questions.order(created_at: :desc)
    
    # Group by office hour
    @my_questions = questions.group_by(&:office_hour)
  end

  private

  def ensure_student
    unless current_user&.student?
      redirect_to office_hours_path, alert: 'Students only.'
    end
  end
end

