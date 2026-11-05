# frozen_string_literal: true

# 제거:  bundle exec rake redmine:plugins:migrate NAME=asciisoft_portal VERSION=0 RAILS_ENV=production
class CreateAsciisoftPortalTables < ActiveRecord::Migration[7.2]
  def change
    create_table :asciisoft_notifications do |t|
      t.integer  :user_id, null: false
      t.integer  :issue_id, null: false
      t.integer  :journal_id
      t.integer  :actor_id
      t.string   :kind, limit: 20, null: false
      t.string   :info, limit: 255
      t.date     :due_date
      t.datetime :read_at
      t.datetime :created_at, null: false
    end
    add_index :asciisoft_notifications, [:user_id, :read_at]
    add_index :asciisoft_notifications, [:user_id, :id]
    add_index :asciisoft_notifications, :issue_id

    create_table :asciisoft_project_headers do |t|
      t.integer :project_id, null: false
      t.string  :status_key, limit: 20, null: false, default: 'auto'
      t.string  :subtitle, limit: 255
      t.string  :bg_mode, limit: 20, null: false, default: 'pattern'
      t.binary  :image_data, limit: 4.megabytes
      t.string  :image_content_type, limit: 100
      t.string  :image_filename, limit: 255
      t.timestamps null: false
    end
    add_index :asciisoft_project_headers, :project_id, unique: true

    create_table :asciisoft_user_settings do |t|
      t.integer :user_id, null: false
      t.string  :color_mode, limit: 20
      t.timestamps null: false
    end
    add_index :asciisoft_user_settings, :user_id, unique: true
  end
end
