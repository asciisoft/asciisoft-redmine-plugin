# frozen_string_literal: true

module AsciisoftPortal
  # 프로젝트 메뉴의 '위키'를 누르면 첫 페이지 대신 문서 목록(제목별 색인)을 먼저 보여줍니다.
  module WikiMenu
    INDEX_URL = {controller: 'wiki', action: 'index'}.freeze

    module_function

    def install!
      item = ::Redmine::MenuManager.map(:project_menu).find(:wiki)
      return unless item

      @original_url ||= item.url
      url = AsciisoftPortal.enabled?('wiki_index_first') ? INDEX_URL : @original_url
      item.instance_variable_set(:@url, url)
    rescue StandardError => e
      Rails.logger&.error("[asciisoft_portal] wiki menu: #{e.message}")
    end
  end
end
