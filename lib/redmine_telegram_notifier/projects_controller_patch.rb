module RedmineTelegramNotifier
  module ProjectsControllerPatch
    def self.included(base)
      base.class_eval do
        after_action :save_telegram_chat_id, only: [:update]
      end
    end

    private

    def save_telegram_chat_id
      return unless defined?(ProjectTelegramChat)
      return unless params[:project_telegram_chat]
      return unless @project

      chat_id = params[:project_telegram_chat][:chat_id]

      if chat_id.present?
        # Удаляем все существующие чаты для проекта
        @project.project_telegram_chats.destroy_all

        # Создаём новый чат
        chat = @project.project_telegram_chats.create!(
          chat_id: chat_id,
          enabled: true
        )
        Rails.logger.info "Telegram chat saved for project #{@project.identifier}: #{chat_id}"
      else
        # Если поле очищено, удаляем все чаты
        @project.project_telegram_chats.destroy_all
        Rails.logger.info "Telegram chats destroyed for project #{@project.identifier}"
      end
    rescue => e
      Rails.logger.error "Error saving telegram chat: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end

unless ProjectsController.included_modules.include?(RedmineTelegramNotifier::ProjectsControllerPatch)
  ProjectsController.send(:include, RedmineTelegramNotifier::ProjectsControllerPatch)
end
