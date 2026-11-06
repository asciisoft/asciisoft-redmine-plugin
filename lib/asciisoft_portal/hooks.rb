# frozen_string_literal: true

module AsciisoftPortal
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context = {})
      AsciisoftPortal::Context.tag(context)
    rescue StandardError => e
      Rails.logger.error("[asciisoft_portal] context: #{e.class}: #{e.message}")
      ''
    end

    # 내 계정 > 환경설정: 내 프로젝트 바로 진입
    def view_my_account_preferences(context = {})
      user = context[:user] || User.current
      return '' unless user&.logged?

      projects = ::Project.visible(user).where(id: user.memberships.select(:project_id)).sorted.to_a
      current = (AsciisoftUserSetting.find_by(user_id: user.id).try(:landing_project_id) rescue nil)
      options = [[::I18n.t(:label_asciisoft_landing_none), '']] + projects.map {|p| [p.name, p.id] }
      select = select_tag('asciisoft_landing_project_id', options_for_select(options, current), id: 'asciisoft_landing_project_id')
      label = content_tag('label', ::I18n.t(:label_asciisoft_landing_project), for: 'asciisoft_landing_project_id')
      hint = content_tag('em', ::I18n.t(:text_asciisoft_landing_hint), class: 'info')
      content_tag('p', label + select + hint)
    rescue StandardError => e
      Rails.logger.error("[asciisoft_portal] landing hook: #{e.message}")
      ''
    end
  end
end
