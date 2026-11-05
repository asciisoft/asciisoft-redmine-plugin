# frozen_string_literal: true

module AsciisoftPortal
  module Patches
    module ProjectPatch
      def self.prepended(base)
        base.after_destroy :asciisoft_portal_cleanup
      end

      private

      def asciisoft_portal_cleanup
        AsciisoftProjectHeader.where(project_id: id).delete_all
      rescue StandardError
        nil
      end
    end
  end
end
