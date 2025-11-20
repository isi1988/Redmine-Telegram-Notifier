module RedmineTelegramNotifier
  module UserPatch
    def self.included(base)
      base.class_eval do
        safe_attributes 'telegram_user_id'
      end
    end
  end
end

unless User.included_modules.include?(RedmineTelegramNotifier::UserPatch)
  User.send(:include, RedmineTelegramNotifier::UserPatch)
end
