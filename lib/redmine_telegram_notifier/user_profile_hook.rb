module RedmineTelegramNotifier
  class UserProfileHook < Redmine::Hook::ViewListener
    # Добавление поля в форму редактирования пользователя
    def view_users_form(context = {})
      # Проверяем, что колонка существует в БД
      return ''.html_safe unless User.column_names.include?('telegram_user_id')

      f = context[:form]
      user = context[:user]

      content = ''.html_safe
      content << '<p>'.html_safe
      content << f.label(:telegram_user_id, 'Telegram User ID')
      content << '<br/>'.html_safe
      content << f.text_field(:telegram_user_id, size: 30, placeholder: '123456789')
      content << '<br/><em class="info">'.html_safe
      content << 'Используйте '.html_safe
      content << '<a href="https://t.me/getidsbot" target="_blank">@getidsbot</a>'.html_safe
      content << ' для получения вашего Telegram User ID'.html_safe
      content << '</em>'.html_safe
      content << '</p>'.html_safe

      content
    end

    # Отображение в профиле пользователя
    def view_account_left_bottom(context = {})
      # Проверяем, что колонка существует в БД
      return ''.html_safe unless User.column_names.include?('telegram_user_id')

      user = context[:user]
      return '' if user.telegram_user_id.blank?

      content = ''.html_safe
      content << '<p>'.html_safe
      content << '<strong>Telegram User ID:</strong> '.html_safe
      content << user.telegram_user_id.to_s.html_safe
      content << '</p>'.html_safe

      content
    end
  end
end
