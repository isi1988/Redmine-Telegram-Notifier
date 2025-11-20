post 'telegram_notifier/test', to: 'telegram_notifier#test', as: 'test_telegram_notification'

scope '/projects/:project_id' do
  post 'telegram_chats', to: 'project_telegram_chats#create', as: 'project_telegram_chats'
  patch 'telegram_chats/:id', to: 'project_telegram_chats#update', as: 'project_telegram_chat'
  delete 'telegram_chats/:id', to: 'project_telegram_chats#destroy'
end
