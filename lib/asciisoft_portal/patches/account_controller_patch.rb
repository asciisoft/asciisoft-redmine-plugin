# frozen_string_literal: true

module AsciisoftPortal
  module Patches
    # 로그인 후 '내 프로젝트 바로 진입'에 설정한 프로젝트로 이동합니다.
    # 다른 페이지를 보려다 로그인 화면으로 온 경우(back_url이 그 페이지)는 원래 페이지로 보냅니다.
    module AccountControllerPatch
      HOME_PATHS = ['', '/', '/my/page', '/login', '/my'].freeze

      private

      def successful_authentication(user)
        @asciisoft_landing_user = user
        super
      end

      def redirect_back_or_default(default, options = {})
        project = asciisoft_landing_project
        return redirect_to(project_path(project)) if project

        super
      end

      def asciisoft_landing_project
        user = @asciisoft_landing_user
        return nil unless user
        return nil unless asciisoft_home_back_url?

        setting = AsciisoftUserSetting.find_by(user_id: user.id)
        project = setting && setting.try(:landing_project_id) && ::Project.find_by(id: setting.landing_project_id)
        project if project&.active? && project.visible?(user)
      rescue StandardError
        nil
      end

      def asciisoft_home_back_url?
        url = params[:back_url].to_s
        return true if url.blank?

        path = URI.parse(url).path.to_s
        base = AsciisoftPortal.base_path
        path = path.delete_prefix(base) if base.present?
        HOME_PATHS.include?(path.chomp('/')) || HOME_PATHS.include?(path)
      rescue URI::InvalidURIError
        false
      end
    end
  end
end
