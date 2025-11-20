class ProjectTelegramChat < ActiveRecord::Base
  belongs_to :project

  validates :chat_id, presence: true
  validates :project_id, presence: true, uniqueness: { scope: :chat_id }

  scope :enabled, -> { where(enabled: true) }

  def self.chat_id_for_project(project_id)
    enabled.find_by(project_id: project_id)&.chat_id
  end
end
