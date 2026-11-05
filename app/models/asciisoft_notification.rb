# frozen_string_literal: true

class AsciisoftNotification < ApplicationRecord
  self.table_name = 'asciisoft_notifications'

  KINDS = %w[assigned mention status comment due].freeze

  belongs_to :user
  belongs_to :issue
  belongs_to :journal, optional: true
  belongs_to :actor, class_name: 'User', optional: true

  validates :kind, inclusion: {in: KINDS}

  scope :unread, -> { where(read_at: nil) }
  scope :for_user, ->(user) { where(user_id: user.id).joins(:issue) }
end
