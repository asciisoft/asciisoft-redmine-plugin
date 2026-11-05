# frozen_string_literal: true

class AsciisoftProjectHeadersController < ApplicationController
  before_action :find_project_by_project_id
  before_action :check_visible, only: :image
  before_action :check_editable, only: :update

  # GET /projects/:project_id/asciisoft_header/image
  def image
    header = AsciisoftProjectHeader.find_by(project_id: @project.id)
    return render_404 unless header&.image?

    expires_in 30.days, public: false
    send_data header.image_data, type: header.image_content_type,
                                 disposition: 'inline',
                                 filename: header.image_filename.presence || 'header'
  end

  # POST /projects/:project_id/asciisoft_header
  def update
    header = AsciisoftProjectHeader.find_or_initialize_by(project_id: @project.id)
    header.status_key = params[:status_key].to_s if params.key?(:status_key)
    header.subtitle = params[:subtitle].to_s.strip.first(120) if params.key?(:subtitle)
    header.bg_mode = params[:bg_mode].to_s if params.key?(:bg_mode)

    if params[:remove_image] == '1'
      header.image_data = nil
      header.image_content_type = nil
      header.image_filename = nil
    end

    upload = params[:image]
    if upload.respond_to?(:read)
      bytes = upload.read
      header.image_data = bytes
      header.image_content_type = AsciisoftProjectHeader.detect_image_type(bytes)
      header.image_filename = File.basename(upload.original_filename.to_s).first(200)
      header.bg_mode = 'image'
    end
    header.bg_mode = 'pattern' if header.bg_mode == 'image' && !header.image?

    if header.save
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:error] = header.errors.full_messages.join(', ')
    end
    redirect_to settings_project_path(@project, tab: 'asciisoft_header')
  end

  private

  def check_visible
    render_404 unless @project.visible?
  end

  def check_editable
    render_403 unless User.current.allowed_to?(:edit_project, @project)
  end
end
