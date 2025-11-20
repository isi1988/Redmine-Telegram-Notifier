module RedmineTelegramNotifier
  class ProjectSettingsHook < Redmine::Hook::ViewListener
    def view_projects_form(context = {})
      project = context[:project]

      return ''.html_safe unless defined?(ProjectTelegramChat)

      context[:controller].send(:render_to_string, {
        partial: 'projects/telegram_settings',
        locals: { project: project }
      })
    end

    # Обработка сохранения проекта
    def controller_projects_update_before_save(context = {})
      project = context[:project]
      params = context[:params]

      return unless defined?(ProjectTelegramChat)
      return unless params[:project_telegram_chat]

      chat_id = params[:project_telegram_chat][:chat_id]

      if chat_id.present?
        # Ищем существующий чат или создаём новый
        chat = project.project_telegram_chats.first_or_initialize
        chat.chat_id = chat_id
        chat.enabled = true
        chat.save
      elsif project.project_telegram_chats.any?
        # Если поле очищено, удаляем чат
        project.project_telegram_chats.destroy_all
      end
    end
  end
end
