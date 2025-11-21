Redmine::Plugin.register :redmine_telegram_notifier do
  name 'Redmine Telegram Notifier'
  author 'Sviatoslav Ivanov'
  description 'Отправляет уведомления в Telegram при создании и изменении задач. Поддерживает отдельные чаты для проектов и личные уведомления пользователям.'
  version '2.0.0'
  url 'https://github.com/isi1988/Redmine-Telegram-Notifier.git'
  author_url 'https://github.com/isi1988'

  settings default: {
    'bot_token' => '',
    'chat_id' => '',
    'notify_on_create' => '1',
    'notify_on_update' => '1',
    'notify_status_change' => '1',
    'notify_priority_change' => '1',
    'notify_assignee_change' => '1'
  }, partial: 'settings/telegram_notifier_settings'

  requires_redmine version_or_higher: '6.0.0'
end

# Для Rails 7+ (Zeitwerk) используем require вместо require_dependency
Rails.application.config.after_initialize do
  require_relative 'lib/redmine_telegram_notifier/telegram_service'
  require_relative 'lib/redmine_telegram_notifier/hooks'
  require_relative 'lib/redmine_telegram_notifier/user_patch'
  require_relative 'lib/redmine_telegram_notifier/project_patch'
  require_relative 'lib/redmine_telegram_notifier/project_settings_hook'
  require_relative 'lib/redmine_telegram_notifier/user_profile_hook'
  require_relative 'lib/redmine_telegram_notifier/projects_controller_patch'
end
