# frozen_string_literal: true

# 내 계정 > "내 프로젝트 바로 진입" 설정
class AddLandingProjectToAsciisoftUserSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :asciisoft_user_settings, :landing_project_id, :integer
  end
end
