module RedmineTelegramNotifier
  class UserProfileHook < Redmine::Hook::ViewListener
    # Добавление поля в форму "Мой аккаунт"
    def view_my_account(context = {})
      # Проверяем, что колонки существуют в БД
      has_user_id = User.column_names.include?('telegram_user_id')
      has_username = User.column_names.include?('telegram_username')
      return ''.html_safe unless has_user_id || has_username

      user = context[:user]

      content = ''.html_safe
      content << '<h3>Telegram</h3>'.html_safe

      if has_user_id
        content << '<p>'.html_safe
        content << '<label for="user_telegram_user_id">Telegram User ID</label>'.html_safe
        content << '<input type="text" name="user[telegram_user_id]" id="user_telegram_user_id" value="'.html_safe
        content << (user.telegram_user_id || '').html_safe
        content << '" size="30" placeholder="123456789" />'.html_safe
        content << '<br/><em class="info">'.html_safe
        content << 'Ваш числовой ID в Telegram. Используйте '.html_safe
        content << '<a href="https://t.me/getidsbot" target="_blank">@getidsbot</a>'.html_safe
        content << ' для получения ID'.html_safe
        content << '</em>'.html_safe
        content << '</p>'.html_safe
      end

      if has_username
        content << '<p>'.html_safe
        content << '<label for="user_telegram_username">Telegram Username</label>'.html_safe
        content << '<input type="text" name="user[telegram_username]" id="user_telegram_username" value="'.html_safe
        content << (user.telegram_username || '').html_safe
        content << '" size="30" placeholder="@username или username" />'.html_safe
        content << '<br/><em class="info">'.html_safe
        content << 'Ваш username в Telegram (с @ или без)'.html_safe
        content << '</em>'.html_safe
        content << '</p>'.html_safe
      end

      content
    end

    # Добавление поля в форму редактирования пользователя (администратор)
    def view_users_form(context = {})
      # Проверяем, что колонки существуют в БД
      has_user_id = User.column_names.include?('telegram_user_id')
      has_username = User.column_names.include?('telegram_username')
      return ''.html_safe unless has_user_id || has_username

      f = context[:form]
      user = context[:user]

      content = ''.html_safe

      if has_user_id
        content << '<p>'.html_safe
        content << f.label(:telegram_user_id, 'Telegram User ID')
        content << '<br/>'.html_safe
        content << f.text_field(:telegram_user_id, size: 30, placeholder: '123456789')
        content << '<br/><em class="info">'.html_safe
        content << 'Ваш числовой ID в Telegram. Используйте '.html_safe
        content << '<a href="https://t.me/getidsbot" target="_blank">@getidsbot</a>'.html_safe
        content << ' для получения ID'.html_safe
        content << '</em>'.html_safe
        content << '</p>'.html_safe
      end

      if has_username
        content << '<p>'.html_safe
        content << f.label(:telegram_username, 'Telegram Username')
        content << '<br/>'.html_safe
        content << f.text_field(:telegram_username, size: 30, placeholder: '@username или username')
        content << '<br/><em class="info">'.html_safe
        content << 'Ваш username в Telegram (с @ или без)'.html_safe
        content << '</em>'.html_safe
        content << '</p>'.html_safe
      end

      content
    end

    # Отображение в профиле пользователя
    def view_account_left_bottom(context = {})
      user = context[:user]
      has_user_id = User.column_names.include?('telegram_user_id')
      has_username = User.column_names.include?('telegram_username')

      return ''.html_safe unless has_user_id || has_username
      return ''.html_safe if user.telegram_user_id.blank? && user.telegram_username.blank?

      content = ''.html_safe

      if has_user_id && user.telegram_user_id.present?
        content << '<p>'.html_safe
        content << '<strong>Telegram User ID:</strong> '.html_safe
        content << user.telegram_user_id.to_s.html_safe
        content << '</p>'.html_safe
      end

      if has_username && user.telegram_username.present?
        content << '<p>'.html_safe
        content << '<strong>Telegram Username:</strong> '.html_safe
        content << user.telegram_username.to_s.html_safe
        content << '</p>'.html_safe
      end

      content
    end
  end
end
