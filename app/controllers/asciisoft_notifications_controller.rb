# frozen_string_literal: true

class AsciisoftNotificationsController < ApplicationController
  before_action :require_login
  before_action :check_enabled

  # GET /asciisoft/notifications.json
  #   ?since_id=N : N 이후 새 알림(토스트용, 최대 5건)
  #   ?list=1     : 최근 알림 목록(레이어용, 최대 30건)
  def index
    user = User.current
    AsciisoftPortal::Notifier.generate_due(user, session)
    AsciisoftPortal::Notifier.cleanup if rand(50).zero?

    scope = AsciisoftNotification.for_user(user)
    items =
      if params[:list].present?
        scope.order(id: :desc).limit(30)
      elsif params[:since_id].to_i.positive?
        scope.where("#{AsciisoftNotification.table_name}.id > ?", params[:since_id].to_i).order(id: :desc).limit(5)
      else
        AsciisoftNotification.none
      end
    items = items.includes(:actor, issue: [:project, :tracker, :status]).to_a.select {|n| n.issue.visible?(user) }

    render json: {
      unread: scope.unread.count,
      latest_id: scope.maximum(:id).to_i,
      items: items.map {|n| serialize(n) }
    }
  end

  # POST /asciisoft/notifications/read_all
  def read_all
    AsciisoftNotification.where(user_id: User.current.id, read_at: nil).update_all(read_at: Time.now)
    render json: {unread: 0}
  end

  private

  def check_enabled
    render(json: {enabled: false}, status: :not_found) unless AsciisoftPortal::Notifier.enabled?
  end

  def serialize(n)
    issue = n.issue
    {
      id: n.id,
      kind: n.kind,
      info: n.info,
      unread: n.read_at.nil?,
      created_at: n.created_at&.iso8601,
      actor: n.actor&.name,
      url: issue_path(issue, anchor: (n.journal_id ? "change-#{n.journal_id}" : nil)),
      issue: {
        id: issue.id,
        subject: issue.subject,
        tracker: issue.tracker&.name,
        status: issue.status&.name,
        project: issue.project&.name
      }
    }
  end
end
