# frozen_string_literal: true

module AsciisoftPortal
  module Patches
    # 요청 목록을 처음 열었을 때 기본 조건(미완료) 대신 '전체' 상태로 보여줍니다.
    # 저장된 기본 검색양식(관리 > 설정)이 있으면 그것을 우선합니다.
    module IssuesControllerPatch
      def index
        asciisoft_default_all_status
        super
      end

      private

      def asciisoft_default_all_status
        return unless AsciisoftPortal.enabled?('default_all_status')
        return unless request.format.html?
        return if api_request?
        return if %i[query_id set_filter without_default f status_id].any? {|k| params[k].present? }

        stored = session[:issue_query]
        if stored.is_a?(Hash)
          stored_project = stored[:project_id] || stored['project_id']
          return if stored_project == @project&.id
        end
        return if IssueQuery.default(project: @project)

        params[:set_filter] = '1'
        params[:f] = ['status_id', '']
        params[:op] = {'status_id' => '*'}
        params[:v] = {'status_id' => ['']}
      rescue StandardError => e
        Rails.logger.error("[asciisoft_portal] default_all_status: #{e.message}")
      end
    end
  end
end
