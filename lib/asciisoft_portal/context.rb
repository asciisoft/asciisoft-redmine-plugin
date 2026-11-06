# frozen_string_literal: true

module AsciisoftPortal
  # 테마 JS가 사용하는 데이터를 <head>에 JSON으로 넣습니다.
  # 테마를 쓰지 않으면 이 데이터는 사용되지 않습니다.
  module Context
    STATS_PAGES = {
      'projects' => %w[show],
      'issues' => %w[index],
      'agile_boards' => %w[index]
    }.freeze

    module_function

    def build(controller, project)
      user = User.current
      base = AsciisoftPortal.base_path
      data = {
        v: 1,
        base: base,
        lang: ::I18n.locale.to_s,
        page: {controller: controller&.controller_name, action: controller&.action_name},
        user: {logged: user.logged?, id: user.logged? ? user.id : nil, name: user.logged? ? user.name : nil},
        mode: user_mode(user),
        notifications: notifications_config(user, base),
        endpoints: {mode: "#{base}/asciisoft/mode"},
        statuses: ::IssueStatus.sorted.map {|s| {id: s.id, name: s.name, closed: s.is_closed?} },
        trackers: ::Tracker.sorted.map {|t| {id: t.id, name: t.name} },
        priorities: ::IssuePriority.active.sorted.map {|p| {id: p.id, name: p.name} }
      }
      if project.is_a?(::Project) && project.persisted? && project.visible?(user)
        data[:project] = project_data(controller, project, user, base)
      end
      data
    end

    def tag(context)
      controller = context[:controller]
      return '' unless controller

      data = build(controller, context[:project])
      json = ERB::Util.json_escape(data.to_json)
      %(<script type="application/json" id="asciisoft-context">#{json}</script>).html_safe
    end

    def user_mode(user)
      return nil unless user.logged?

      AsciisoftUserSetting.find_by(user_id: user.id)&.color_mode
    rescue StandardError
      nil
    end

    def notifications_config(user, base)
      return {enabled: false} unless user.logged? && AsciisoftPortal::Notifier.enabled?

      poll = AsciisoftPortal.setting('poll_seconds').to_i
      poll = 30 if poll < 10
      {enabled: true, poll: poll,
       url: "#{base}/asciisoft/notifications",
       read_all: "#{base}/asciisoft/notifications/read_all"}
    end

    def project_data(controller, project, user, base)
      header = AsciisoftProjectHeader.find_by(project_id: project.id) rescue nil
      status_key = header&.status_key.presence || 'auto'
      status_key = project.active? ? 'active' : 'closed' if status_key == 'auto'
      out = {
        id: project.id,
        identifier: project.identifier,
        name: project.name,
        status: status_key,
        status_label: status_key == 'hidden' ? nil : ::I18n.t("label_asciisoft_status_#{status_key}", default: status_key),
        subtitle: header&.subtitle.presence,
        sub_title: (header.try(:sub_title).presence if header),
        logo: (header&.logo? ? "#{base}/projects/#{project.identifier}/asciisoft_header/image?kind=logo&v=#{header.updated_at.to_i}" : nil),
        bg: header&.bg_mode.presence || 'pattern',
        image: (header&.image? ? "#{base}/projects/#{project.identifier}/asciisoft_header/image?v=#{header.updated_at.to_i}" : nil),
        can_edit: user.allowed_to?(:edit_project, project),
        settings_url: "#{base}/projects/#{project.identifier}/settings/asciisoft_header",
        new_issue: user.allowed_to?(:add_issues, project) && ::Issue.allowed_target_trackers(project, user).any?,
        customers: customer_ids(project)
      }
      pages = STATS_PAGES[controller.controller_name.to_s]
      out[:stats] = stats(project, user) if pages&.include?(controller.action_name.to_s)
      out
    end

    def customer_ids(project)
      role_name = AsciisoftPortal.setting('customer_role').to_s.strip
      return [] if role_name.empty?

      role = ::Role.find_by(name: role_name)
      return [] unless role

      ::Member.joins(:member_roles).
        where(project_id: project.id, member_roles: {role_id: role.id}).
        distinct.limit(1000).pluck(:user_id)
    rescue StandardError
      []
    end

    def stats(project, user)
      project_ids =
        if ::Setting.display_subprojects_issues?
          project.self_and_descendants.pluck(:id)
        else
          [project.id]
        end
      scope = ::Issue.visible(user).where(project_id: project_ids)
      counts = scope.group(:status_id).count
      statuses = ::IssueStatus.sorted.to_a
      new_names = AsciisoftPortal.name_list('new_status_names')
      excluded_names = AsciisoftPortal.name_list('excluded_status_names')

      new_ids = statuses.select {|s| new_names.include?(s.name) }.map(&:id)
      if new_ids.empty?
        new_ids = ::Tracker.where.not(default_status_id: nil).distinct.pluck(:default_status_id)
      end
      excluded_ids = statuses.select {|s| excluded_names.include?(s.name) }.map(&:id)
      closed_ids = statuses.select(&:is_closed?).map(&:id)

      sum = ->(ids) { ids.sum {|id| counts[id].to_i } }
      open_ids = statuses.map(&:id) - closed_ids
      considered = statuses.map(&:id) - excluded_ids
      total = sum.call(considered)
      done = sum.call(closed_ids - excluded_ids)

      {
        new: sum.call(new_ids & open_ids),
        progress: sum.call(open_ids - new_ids),
        overdue: scope.open.where("#{::Issue.table_name}.due_date < ?", user.today).count,
        percent: total.positive? ? ((done * 100.0) / total).round : 0,
        total: counts.values.sum,
        by_status: statuses.map {|s| {id: s.id, name: s.name, closed: s.is_closed?, count: counts[s.id].to_i} }
      }
    rescue StandardError => e
      Rails.logger.error("[asciisoft_portal] stats: #{e.message}")
      nil
    end
  end
end
