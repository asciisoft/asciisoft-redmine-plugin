# frozen_string_literal: true

class AsciisoftUserSetting < ApplicationRecord
  self.table_name = 'asciisoft_user_settings'

  MODES = %w[light white gray dark blue sunset green purple orange pink].freeze

  belongs_to :user
  validates :color_mode, inclusion: {in: MODES}, allow_nil: true
end
