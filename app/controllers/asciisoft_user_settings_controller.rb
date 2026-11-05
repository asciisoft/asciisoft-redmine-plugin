# frozen_string_literal: true

class AsciisoftUserSettingsController < ApplicationController
  before_action :require_login

  # POST /asciisoft/mode  mode=light|gray|dark|blue|sunset|green|purple|orange|pink
  def update_mode
    mode = params[:mode].to_s
    unless AsciisoftUserSetting::MODES.include?(mode)
      return render(json: {error: 'invalid mode'}, status: :unprocessable_content)
    end

    setting = AsciisoftUserSetting.find_or_initialize_by(user_id: User.current.id)
    setting.color_mode = mode
    setting.save!
    render json: {mode: mode}
  end
end
