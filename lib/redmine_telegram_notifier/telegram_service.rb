require 'net/http'
require 'json'
require 'uri'

module RedmineTelegramNotifier
  class TelegramService
    # Нормализация username (убираем @ если есть)
    def self.normalize_telegram_username(username)
      return nil if username.blank?
      username.to_s.strip.sub(/^@/, '')
    end

    # Отправка сообщения пользователю по username
    def self.send_message_to_username(text, username)
      # Telegram API не поддерживает отправку по username напрямую
      # Нужно сначала получить chat_id пользователя через username
      # Для этого пользователь должен хотя бы раз написать боту
      bot_token = Setting.plugin_redmine_telegram_notifier['bot_token']
      return false if bot_token.blank? || username.blank?

      begin
        # Пробуем отправить через @username
        chat_id = "@#{normalize_telegram_username(username)}"
        send_message_to_chat(text, chat_id)
      rescue => e
        Rails.logger.error "Error sending Telegram notification to username #{username}: #{e.message}"
        false
      end
    end

    # Отправка сообщения в конкретный чат (или пользователю)
    def self.send_message_to_chat(text, chat_id)
      bot_token = Setting.plugin_redmine_telegram_notifier['bot_token']

      return false if bot_token.blank? || chat_id.blank?

      begin
        uri = URI("https://api.telegram.org/bot#{bot_token}/sendMessage")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 5
        http.read_timeout = 5

        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = 'application/json'

        request.body = {
          chat_id: chat_id,
          text: text,
          parse_mode: 'HTML',
          disable_web_page_preview: true
        }.to_json

        response = http.request(request)

        if response.code.to_i == 200
          Rails.logger.info "Telegram notification sent successfully to #{chat_id}"
          true
        else
          Rails.logger.error "Failed to send Telegram notification to #{chat_id}: #{response.body}"
          false
        end
      rescue => e
        Rails.logger.error "Error sending Telegram notification to #{chat_id}: #{e.message}"
        false
      end
    end

    # Отправка в глобальный чат (для обратной совместимости)
    def self.send_message(text)
      chat_id = Setting.plugin_redmine_telegram_notifier['chat_id']
      send_message_to_chat(text, chat_id)
    end

    # Отправка уведомления для issue
    def self.send_issue_notification(issue, text)
      results = []

      # Отправляем в чат проекта, если он настроен
      project_chat_id = ProjectTelegramChat.chat_id_for_project(issue.project_id)
      if project_chat_id.present?
        results << send_message_to_chat(text, project_chat_id)
      else
        # Иначе отправляем в глобальный чат (если настроен)
        global_chat_id = Setting.plugin_redmine_telegram_notifier['chat_id']
        results << send_message_to_chat(text, global_chat_id) if global_chat_id.present?
      end

      # Отправляем личное уведомление назначенному пользователю
      if issue.assigned_to.present?
        personal_message = "🔔 <b>Вам назначена задача</b>\n\n" + text

        # Пробуем отправить по telegram_user_id
        if User.column_names.include?('telegram_user_id') && issue.assigned_to.telegram_user_id.present?
          results << send_message_to_chat(personal_message, issue.assigned_to.telegram_user_id)
        # Если нет user_id, пробуем отправить по telegram_username
        elsif User.column_names.include?('telegram_username') && issue.assigned_to.telegram_username.present?
          username = normalize_telegram_username(issue.assigned_to.telegram_username)
          results << send_message_to_username(personal_message, username)
        end
      end

      results.any?
    end

    def self.format_issue_message(issue, action)
      settings = Setting.plugin_redmine_telegram_notifier
      
      message = []
      
      case action
      when :create
        message << "🆕 <b>Создана новая задача</b>"
      when :update
        message << "✏️ <b>Обновлена задача</b>"
      end
      
      message << ""
      message << "📋 <b>#{issue.tracker.name}</b> ##{issue.id}: #{issue.subject}"
      message << ""
      message << "👤 <b>Автор:</b> #{issue.author.name}"
      message << "📊 <b>Статус:</b> #{issue.status.name}"
      message << "🎯 <b>Приоритет:</b> #{issue.priority.name}"
      
      if issue.assigned_to.present?
        assigned_name = issue.assigned_to.name
        # Добавляем упоминание пользователя, если указан telegram_username
        if User.column_names.include?('telegram_username') && issue.assigned_to.telegram_username.present?
          username = normalize_telegram_username(issue.assigned_to.telegram_username)
          assigned_name = "#{issue.assigned_to.name} (@#{username})"
        end
        message << "👷 <b>Назначена:</b> #{assigned_name}"
      end
      
      if issue.project.present?
        message << "📁 <b>Проект:</b> #{issue.project.name}"
      end
      
      if issue.description.present? && action == :create
        description = issue.description.truncate(200, omission: '...')
        message << ""
        message << "📝 <b>Описание:</b>"
        message << description
      end
      
      # Добавляем ссылку на задачу
      issue_url = Rails.application.routes.url_helpers.issue_url(
        issue,
        host: Setting.host_name,
        protocol: Setting.protocol
      )
      message << ""
      message << "🔗 <a href=\"#{issue_url}\">Открыть задачу</a>"
      
      message.join("\n")
    end

    def self.format_issue_update_message(issue, journal)
      settings = Setting.plugin_redmine_telegram_notifier
      
      message = []
      message << "✏️ <b>Обновлена задача</b>"
      message << ""
      message << "📋 <b>#{issue.tracker.name}</b> ##{issue.id}: #{issue.subject}"
      message << ""
      message << "👤 <b>Изменил:</b> #{journal.user.name}"
      
      changes = []
      
      journal.details.each do |detail|
        case detail.property
        when 'attr'
          case detail.prop_key
          when 'status_id'
            if settings['notify_status_change'] == '1'
              old_status = IssueStatus.find_by(id: detail.old_value)
              new_status = IssueStatus.find_by(id: detail.value)
              changes << "📊 <b>Статус:</b> #{old_status&.name} → #{new_status&.name}"
            end
          when 'priority_id'
            if settings['notify_priority_change'] == '1'
              old_priority = IssuePriority.find_by(id: detail.old_value)
              new_priority = IssuePriority.find_by(id: detail.value)
              changes << "🎯 <b>Приоритет:</b> #{old_priority&.name} → #{new_priority&.name}"
            end
          when 'assigned_to_id'
            if settings['notify_assignee_change'] == '1'
              old_user = User.find_by(id: detail.old_value)
              new_user = User.find_by(id: detail.value)
              changes << "👷 <b>Назначена:</b> #{old_user&.name || 'Не назначена'} → #{new_user&.name || 'Не назначена'}"
            end
          else
            field_name = I18n.t("field_#{detail.prop_key}", default: detail.prop_key)
            changes << "• <b>#{field_name}:</b> #{detail.old_value} → #{detail.value}"
          end
        when 'attachment'
          changes << "📎 <b>Добавлено вложение:</b> #{detail.value}"
        end
      end
      
      if journal.notes.present?
        message << ""
        message << "💬 <b>Комментарий:</b>"
        message << journal.notes.truncate(300, omission: '...')
      end
      
      if changes.any?
        message << ""
        message << "<b>Изменения:</b>"
        message += changes
      end
      
      # Добавляем ссылку на задачу
      issue_url = Rails.application.routes.url_helpers.issue_url(
        issue,
        host: Setting.host_name,
        protocol: Setting.protocol
      )
      message << ""
      message << "🔗 <a href=\"#{issue_url}\">Открыть задачу</a>"
      
      message.join("\n")
    end
  end
end
