# frozen_string_literal: true

# 프로젝트 헤더에 부제목과 프로젝트 로고 이미지를 추가합니다.
class AddLogoAndSubTitleToAsciisoftProjectHeaders < ActiveRecord::Migration[7.2]
  def change
    add_column :asciisoft_project_headers, :sub_title, :string, limit: 120
    add_column :asciisoft_project_headers, :logo_data, :binary, limit: 1.megabyte
    add_column :asciisoft_project_headers, :logo_content_type, :string, limit: 100
    add_column :asciisoft_project_headers, :logo_filename, :string, limit: 255
  end
end
