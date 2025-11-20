module RedmineTelegramNotifier
  module ProjectPatch
    def self.included(base)
      base.class_eval do
        has_many :project_telegram_chats, dependent: :destroy
      end
    end
  end
end

unless Project.included_modules.include?(RedmineTelegramNotifier::ProjectPatch)
  Project.send(:include, RedmineTelegramNotifier::ProjectPatch)
end
