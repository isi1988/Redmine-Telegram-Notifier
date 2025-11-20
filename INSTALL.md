# Инструкция по установке в production

## Установка плагина

### 1. Скопируйте плагин в директорию plugins

```bash
cd /opt/redmine/plugins
git clone https://github.com/yourusername/redmine_telegram_notifier.git
```

### 2. Установите права доступа

```bash
chown -R redmine:redmine /opt/redmine/plugins/redmine_telegram_notifier
chmod -R 755 /opt/redmine/plugins/redmine_telegram_notifier
```

### 3. Перезапустите Redmine

#### Для Passenger (Apache/Nginx):
```bash
touch /opt/redmine/tmp/restart.txt
```

#### Для systemd:
```bash
sudo systemctl restart redmine
```

#### Для Unicorn/Puma:
```bash
sudo systemctl restart redmine-unicorn
# или
sudo systemctl restart redmine-puma
```

### 4. Проверьте установку

1. Войдите в Redmine как администратор
2. Перейдите в **Администрирование → Плагины**
3. Убедитесь, что плагин **Redmine Telegram Notifier v1.0.0** появился в списке

## Настройка firewall

Если Redmine работает за firewall, необходимо разрешить исходящие соединения к Telegram API:

### iptables:
```bash
iptables -A OUTPUT -p tcp --dport 443 -d 149.154.160.0/20 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -d 91.108.4.0/22 -j ACCEPT
```

### firewalld:
```bash
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 -p tcp --dport 443 -d 149.154.160.0/20 -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 -p tcp --dport 443 -d 91.108.4.0/22 -j ACCEPT
firewall-cmd --reload
```

### ufw:
```bash
ufw allow out to 149.154.160.0/20 port 443
ufw allow out to 91.108.4.0/22 port 443
```

## Проверка работы через curl

### Проверка доступности Telegram API:
```bash
curl -v https://api.telegram.org/botYOUR_BOT_TOKEN/getMe
```

### Тестовая отправка сообщения:
```bash
curl -X POST "https://api.telegram.org/botYOUR_BOT_TOKEN/sendMessage" \
  -H "Content-Type: application/json" \
  -d '{"chat_id": "YOUR_CHAT_ID", "text": "Test from Redmine server"}'
```

## Мониторинг логов

### Просмотр логов Redmine:
```bash
tail -f /opt/redmine/log/production.log | grep -i telegram
```

### Логи при успешной отправке:
```
Telegram notification sent successfully
```

### Логи при ошибке:
```
Failed to send Telegram notification: {"ok":false,"error_code":401,"description":"Unauthorized"}
Error sending Telegram notification: execution expired
```

## Настройка для высоконагруженных систем

Для систем с большим количеством задач рекомендуется использовать асинхронную очередь:

### Установка Sidekiq (опционально):

1. Добавьте в Gemfile плагина:
```ruby
gem 'sidekiq'
```

2. Создайте worker:
```ruby
# lib/redmine_telegram_notifier/telegram_worker.rb
class TelegramWorker
  include Sidekiq::Worker
  
  def perform(message)
    RedmineTelegramNotifier::TelegramService.send_message(message)
  end
end
```

3. Измените отправку в hooks.rb:
```ruby
TelegramWorker.perform_async(message)
```

## Резервное копирование настроек

Настройки плагина хранятся в таблице `settings` базы данных Redmine.

### Экспорт настроек:
```bash
psql -U redmine -d redmine_production -c \
  "SELECT * FROM settings WHERE name = 'plugin_redmine_telegram_notifier';" \
  > telegram_notifier_settings_backup.sql
```

### Импорт настроек:
```bash
psql -U redmine -d redmine_production < telegram_notifier_settings_backup.sql
```

## Troubleshooting

### Проблема: Уведомления не отправляются

**Решение:**
1. Проверьте логи: `tail -f /opt/redmine/log/production.log`
2. Проверьте доступность API: `curl https://api.telegram.org`
3. Проверьте Bot Token: `curl https://api.telegram.org/bot<TOKEN>/getMe`
4. Проверьте firewall: `telnet api.telegram.org 443`

### Проблема: Ошибка "Unauthorized"

**Решение:**
- Неверный Bot Token
- Проверьте токен через @BotFather

### Проблема: Ошибка "Chat not found"

**Решение:**
- Неверный Chat ID
- Бот не добавлен в группу/канал
- У бота нет прав администратора (для каналов)

### Проблема: Ошибка "execution expired"

**Решение:**
- Проблема с сетевым подключением
- Firewall блокирует исходящие соединения
- Проблемы с DNS

### Проблема: SSL certificate verify failed

**Решение:**
```bash
# Установите корневые сертификаты
apt-get install ca-certificates  # Debian/Ubuntu
yum install ca-certificates      # CentOS/RHEL
```

## Обновление плагина

```bash
cd /opt/redmine/plugins/redmine_telegram_notifier
git pull origin main
chown -R redmine:redmine .
touch /opt/redmine/tmp/restart.txt
```

## Удаление плагина

```bash
cd /opt/redmine/plugins
rm -rf redmine_telegram_notifier
touch /opt/redmine/tmp/restart.txt
```

**Важно:** Настройки в базе данных останутся. Для полного удаления:

```sql
DELETE FROM settings WHERE name = 'plugin_redmine_telegram_notifier';
```
