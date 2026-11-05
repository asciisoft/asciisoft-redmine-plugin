# frozen_string_literal: true

module AsciisoftPortal
  module Patches
    # 프로젝트 메뉴의 "+" 드롭다운을 현재 모듈에 맞는 등록 버튼 하나로 바꿉니다.
    # 권한이 없으면 레드마인 기본 권한 검사로 항목이 빠지고, 버튼 자체가 표시되지 않습니다.
    module MenuHelperPatch
      NEW_OBJECT_BY_CONTROLLER = {
        'issues' => :new_issue_sub,
        'gantts' => :new_issue_sub,
        'calendars' => :new_issue_sub,
        'activities' => :new_issue_sub,
        'reports' => :new_issue_sub,
        'agile_boards' => :new_issue_sub,
        'agile_charts' => :new_issue_sub,
        'agile_versions' => :new_issue_sub,
        'versions' => :new_version,
        'timelog' => :new_timelog,
        'news' => :new_news,
        'documents' => :new_document,
        'wiki' => :new_wiki_page,
        'files' => :new_file,
        'issue_categories' => :new_issue_category
      }.freeze

      def render_menu_node_with_children(node, project = nil)
        return super unless node.name == :new_object && AsciisoftPortal.enabled?('module_new_button')

        wanted = asciisoft_new_object_item
        return ''.html_safe unless wanted

        child = node.children.detect {|c| c.name == wanted }
        return ''.html_safe unless child && allowed_node?(child, User.current, project)

        caption, url, _selected = extract_node_details(child, project)
        link = link_to(h(caption), use_absolute_controller(url),
                       id: 'new-object', class: "new-object as-new-object as-new-#{wanted}",
                       title: caption)
        content_tag('li', link, class: 'as-new-object-item')
      end

      private

      def asciisoft_new_object_item
        name = respond_to?(:controller_name) ? controller_name.to_s : ''
        action = respond_to?(:action_name) ? action_name.to_s : ''
        return :new_issue_sub if name == 'projects' && action == 'show'

        NEW_OBJECT_BY_CONTROLLER[name]
      end
    end
  end
end
