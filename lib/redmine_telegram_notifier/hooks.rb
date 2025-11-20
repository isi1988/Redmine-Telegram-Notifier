module RedmineTelegramNotifier
  class Hooks < Redmine::Hook::Listener
    def controller_issues_new_after_save(context = {})
      issue = context[:issue]
      settings = Setting.plugin_redmine_telegram_notifier
      
      return unless settings['notify_on_create'] == '1'
      return unless issue.persisted?
      
      message = TelegramService.format_issue_message(issue, :create)
      TelegramService.send_message(message)
    end

    def controller_issues_edit_after_save(context = {})
      issue = context[:issue]
      journal = context[:journal]
      settings = Setting.plugin_redmine_telegram_notifier
      
      return unless settings['notify_on_update'] == '1'
      return unless journal.present?
      
      # Проверяем, есть ли изменения или комментарии
      return if journal.details.empty? && journal.notes.blank?
      
      message = TelegramService.format_issue_update_message(issue, journal)
      TelegramService.send_message(message)
    end
  end
end
