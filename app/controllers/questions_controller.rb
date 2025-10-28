class QuestionsController < ApplicationController
  before_action :set_office_hour

  def create
    @question = @office_hour.questions.build(question_params)
    
    if @question.save
      redirect_to @office_hour, notice: 'Question submitted successfully!'
    else
      redirect_to @office_hour, alert: 'Failed to submit question. Please try again.'
    end
  end

  def index
    @questions = @office_hour.questions.order(created_at: :desc)
    redirect_to @office_hour
  end

  private

  def set_office_hour
    @office_hour = OfficeHour.find(params[:office_hour_id])
  end

  def question_params
    params.require(:question).permit(:question_text)
  end
end