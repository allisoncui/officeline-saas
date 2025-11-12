class QuestionsController < ApplicationController
  before_action :set_office_hour
  before_action :set_question, only: [:edit, :update, :destroy]
  before_action :ensure_question_owner, only: [:edit, :update, :destroy]

  def create
    @question = @office_hour.questions.build(question_params)
    @question.user = current_user
    
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

  def edit
  end

  def update
    if @question.update(question_params)
      redirect_to @office_hour, notice: 'Question updated successfully!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @question.destroy
    redirect_to @office_hour, notice: 'Question deleted successfully!'
  end

  private

  def set_office_hour
    @office_hour = OfficeHour.find(params[:office_hour_id])
  end

  def set_question
    @question = @office_hour.questions.find(params[:id])
  end

  def ensure_question_owner
    unless @question.user == current_user
      redirect_to @office_hour, alert: 'You can only edit or delete your own questions.'
    end
  end

  def question_params
    params.require(:question).permit(:question_text)
  end
end