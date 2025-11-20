class CreateProjectTelegramChats < ActiveRecord::Migration[7.2]
  def change
    create_table :project_telegram_chats do |t|
      t.integer :project_id, null: false
      t.string :chat_id, null: false
      t.boolean :enabled, default: true
      t.timestamps
    end

    add_index :project_telegram_chats, [:project_id, :chat_id], unique: true
    add_index :project_telegram_chats, :project_id
  end
end
