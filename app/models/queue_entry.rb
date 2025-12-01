class QueueEntry < ApplicationRecord
  belongs_to :office_hour
  belongs_to :user
  belongs_to :queue_session, optional: true
  
  validates :user_id, uniqueness: { 
    scope: :office_hour_id, 
    conditions: -> { where(status: 'waiting') },
    message: "is already in this queue" 
  }
  validates :status, inclusion: { in: %w[waiting served removed] }
  
  scope :active, -> { where(status: 'waiting').order(:joined_at) }
  scope :for_office_hour, ->(office_hour_id) { where(office_hour_id: office_hour_id) }
  
  before_create :set_joined_at
  after_create :update_positions
  after_update :update_positions, if: :saved_change_to_status?
  
  private
  
  def set_joined_at
    self.joined_at ||= Time.current
  end
  
  def update_positions
    # Only reposition entries that are still waiting
    # Order by joined_at to maintain FIFO queue
    office_hour.queue_entries.where(status: 'waiting')
                              .order(:joined_at)
                              .each_with_index do |entry, index|
      entry.update_column(:position, index + 1) unless entry.position == (index + 1)
    end
  end
end