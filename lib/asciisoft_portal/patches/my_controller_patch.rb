# frozen_string_literal: true

module AsciisoftPortal
  module Patches
    # 내 계정 화면에서 설정값 저장
    module MyControllerPatch
      def account
        asciisoft_save_landing if request.post? || request.patch? || request.put?
        super
      end

      private

      def asciisoft_save_landing
        return unless params.key?(:asciisoft_landing_project_id)

        user = User.current
        id = params[:asciisoft_landing_project_id].to_i
        project = id.positive? ? ::Project.find_by(id: id) : nil
        project = nil unless project&.visible?(user)
        setting = AsciisoftUserSetting.find_or_initialize_by(user_id: user.id)
        setting.landing_project_id = project&.id
        setting.save
      rescue StandardError => e
        Rails.logger.error("[asciisoft_portal] landing: #{e.message}")
      end
    end
  end
end
