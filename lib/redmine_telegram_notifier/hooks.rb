module RedmineTelegramNotifier
  class Hooks < Redmine::Hook::Listener
    def controller_issues_new_after_save(context = {})
      issue = context[:issue]
      settings = Setting.plugin_redmine_telegram_notifier

      return unless settings['notify_on_create'] == '1'
      return unless issue.persisted?

      message = TelegramService.format_issue_message(issue, :create)
      TelegramService.send_issue_notification(issue, message)
    end

    def controller_issues_edit_after_save(context = {})
      issue = context[:issue]
      journal = context[:journal]
      settings = Setting.plugin_redmine_telegram_notifier

      return unless settings['notify_on_update'] == '1'
      return unless journal.present?

      # Проверяем, есть ли изменения или комментарии
      return if journal.details.empty? && journal.notes.blank?

      # Отправляем в чаты проекта
      message = TelegramService.format_issue_update_message(issue, journal)

      # Проверяем изменение назначенного пользователя
      assigned_to_changed = false
      new_assigned_to = nil

      journal.details.each do |detail|
        if detail.property == 'attr' && detail.prop_key == 'assigned_to_id'
          assigned_to_changed = true
          new_assigned_to = User.find_by(id: detail.value)
          break
        end
      end

      # Отправляем уведомление в чаты проекта
      TelegramService.send_issue_notification(issue, message)

      # Если изменился назначенный пользователь, отправляем отдельное уведомление новому исполнителю
      if assigned_to_changed &&
         new_assigned_to.present? &&
         User.column_names.include?('telegram_user_id') &&
         new_assigned_to.telegram_user_id.present?
        personal_message = "🔔 <b>Вам назначена задача</b>\n\n" + message
        TelegramService.send_message_to_chat(personal_message, new_assigned_to.telegram_user_id)
      end
    end
  end
end
