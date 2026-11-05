# frozen_string_literal: true

module AsciisoftPortal
  module Patches
    # 프로젝트 설정에 '포털 헤더' 탭을 추가합니다 (프로젝트 관리 권한 필요).
    module ProjectsHelperPatch
      def project_settings_tabs
        tabs = super
        if @project && User.current.allowed_to?(:edit_project, @project)
          tabs << {name: 'asciisoft_header', action: :edit_project,
                   partial: 'asciisoft_project_headers/settings',
                   label: :label_asciisoft_header}
        end
        tabs
      end
    end
  end
end
