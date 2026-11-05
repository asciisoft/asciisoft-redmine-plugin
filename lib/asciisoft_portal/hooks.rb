# frozen_string_literal: true

module AsciisoftPortal
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context = {})
      AsciisoftPortal::Context.tag(context)
    rescue StandardError => e
      Rails.logger.error("[asciisoft_portal] context: #{e.class}: #{e.message}")
      ''
    end
  end
end
