# frozen_string_literal: true

module AsciisoftPortal
  # 요청 등록·변경 시 알림을 만듭니다. 오류가 나도 요청 저장에는 영향을 주지 않습니다.
  #   assigned : 나에게 배정
  #   mention  : @멘션
  #   status   : 내가 등록한 요청의 상태 변경
  #   comment  : 내가 등록한 요청에 댓글
  #   due      : 나에게 배정된 요청의 기한 임박(오늘·내일)
  module Notifier
    PRIORITY = {'mention' => 5, 'assigned' => 4, 'status' => 3, 'comment' => 2, 'due' => 1}.freeze
    DUE_CHECK_INTERVAL = 600 # 초
    KEEP_DAYS = 90

    module_function

    def enabled?
      AsciisoftPortal.enabled?('notifications') && table_ready?
    end

    def table_ready?
      @table_ready ||= AsciisoftNotification.table_exists?
    rescue StandardError
      false
    end

    def issue_created(issue)
      return unless enabled?

      recipients = {}
      users_of(issue.assigned_to).each {|u| add(recipients, u, 'assigned') }
      Array(issue.try(:mentioned_users)).each {|u| add(recipients, u, 'mention') }
      deliver(issue, nil, issue.author, recipients)
    rescue StandardError => e
      log(e)
    end

    def journal_created(journal)
      return unless enabled?

      issue = journal.journalized
      return unless issue.is_a?(::Issue)

      recipients = {}
      details = journal.details.to_a
      assign = details.detect {|d| d.property == 'attr' && d.prop_key == 'assigned_to_id' }
      if assign && assign.value.present?
        users_of(::Principal.find_by(id: assign.value)).each {|u| add(recipients, u, 'assigned') }
      end
      Array(journal.try(:mentioned_users)).each {|u| add(recipients, u, 'mention') }
      author = issue.author
      status = details.detect {|d| d.property == 'attr' && d.prop_key == 'status_id' }
      if status && author
        add(recipients, author, 'status', ::IssueStatus.find_by(id: status.value)&.name)
      end
      add(recipients, author, 'comment') if journal.notes.present? && author

      deliver(issue, journal, journal.user, recipients)
    rescue StandardError => e
      log(e)
    end

    # 알림 조회 시 호출. 사용자별로 10분에 한 번만 확인합니다.
    def generate_due(user, session)
      return unless enabled?

      now = Time.now.to_i
      last = session[:asciisoft_due_checked_at].to_i
      return if now - last < DUE_CHECK_INTERVAL

      session[:asciisoft_due_checked_at] = now
      today = user.today
      ids = [user.id] + user.group_ids
      issues = ::Issue.visible(user).open.
        where(assigned_to_id: ids, due_date: today..(today + 1)).limit(50).to_a
      issues.each do |issue|
        exists = AsciisoftNotification.where(user_id: user.id, issue_id: issue.id,
                                             kind: 'due', due_date: issue.due_date).exists?
        next if exists

        AsciisoftNotification.create(user_id: user.id, issue_id: issue.id, kind: 'due',
                                     due_date: issue.due_date,
                                     info: issue.due_date.to_s)
      end
    rescue StandardError => e
      log(e)
    end

    def cleanup
      AsciisoftNotification.where('created_at < ?', KEEP_DAYS.days.ago).delete_all
      AsciisoftNotification.where.not(issue_id: ::Issue.select(:id)).delete_all
    rescue StandardError => e
      log(e)
    end

    def users_of(principal)
      case principal
      when ::Group then principal.users.to_a
      when ::User then [principal]
      else []
      end
    end

    def add(recipients, user, kind, info = nil)
      return unless user.is_a?(::User)

      current = recipients[user.id]
      return if current && PRIORITY[current[:kind]] >= PRIORITY[kind]

      recipients[user.id] = {user: user, kind: kind, info: info}
    end

    def deliver(issue, journal, actor, recipients)
      recipients.each_value do |r|
        user = r[:user]
        next if actor && user.id == actor.id
        next unless user.active?
        next unless issue.visible?(user)
        if journal&.private_notes? && %w[comment mention].include?(r[:kind]) &&
           !user.allowed_to?(:view_private_notes, issue.project)
          next
        end

        AsciisoftNotification.create(user_id: user.id, issue_id: issue.id,
                                     journal_id: journal&.id, actor_id: actor&.id,
                                     kind: r[:kind], info: r[:info].to_s.first(255).presence)
      end
    end

    def log(error)
      Rails.logger&.error("[asciisoft_portal] notifier: #{error.class}: #{error.message}")
    end
  end
end
