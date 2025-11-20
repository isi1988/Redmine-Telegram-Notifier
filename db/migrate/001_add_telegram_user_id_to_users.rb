class AddTelegramUserIdToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :telegram_user_id, :string
    add_index :users, :telegram_user_id
  end
end
