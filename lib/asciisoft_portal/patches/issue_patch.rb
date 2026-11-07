# frozen_string_literal: true

module AsciisoftPortal
  module Patches
    module IssuePatch
      def self.prepended(base)
        base.after_create_commit :asciisoft_portal_notify_created
        base.before_save :asciisoft_portal_auto_due_date
      end

      private

      # 완료 상태(완료 · 반려 등 '완료' 표시된 상태)로 바꾸면 완료일을 오늘로, 되돌리면 비웁니다.
      def asciisoft_portal_auto_due_date
        return unless AsciisoftPortal.enabled?('auto_due_date')

        if closing?
          self.due_date = Date.today
        elsif reopening?
          self.due_date = nil
        end
      rescue StandardError => e
        Rails.logger.error("[asciisoft_portal] auto due date: #{e.message}")
      end

      def asciisoft_portal_notify_created
        AsciisoftPortal::Notifier.issue_created(self)
      end
    end
  end
end
