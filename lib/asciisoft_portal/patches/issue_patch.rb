# frozen_string_literal: true

module AsciisoftPortal
  module Patches
    module IssuePatch
      def self.prepended(base)
        base.after_create_commit :asciisoft_portal_notify_created
      end

      private

      def asciisoft_portal_notify_created
        AsciisoftPortal::Notifier.issue_created(self)
      end
    end
  end
end
