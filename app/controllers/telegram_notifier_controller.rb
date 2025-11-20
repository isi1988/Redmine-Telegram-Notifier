class TelegramNotifierController < ApplicationController
  before_action :require_admin

  def test
    message = "🔔 <b>Тестовое сообщение</b>\n\n" \
              "✅ Плагин Redmine Telegram Notifier настроен корректно!\n\n" \
              "Сервер: #{Setting.host_name}\n" \
              "Время: #{Time.now.strftime('%d.%m.%Y %H:%M:%S')}"
    
    if RedmineTelegramNotifier::TelegramService.send_message(message)
      flash[:notice] = 'Тестовое сообщение отправлено в Telegram'
    else
      flash[:error] = 'Ошибка отправки сообщения. Проверьте настройки и логи.'
    end
    
    redirect_to plugin_settings_path(:redmine_telegram_notifier)
  end
end
