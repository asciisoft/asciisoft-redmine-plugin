# frozen_string_literal: true

class AsciisoftProjectHeader < ApplicationRecord
  self.table_name = 'asciisoft_project_headers'

  STATUS_KEYS = %w[auto preparing active maintenance paused closed hidden].freeze
  BG_MODES = %w[pattern image none].freeze
  MAX_IMAGE_SIZE = 3 * 1024 * 1024
  MAX_LOGO_SIZE = 1 * 1024 * 1024

  belongs_to :project

  validates :status_key, inclusion: {in: STATUS_KEYS}
  validates :bg_mode, inclusion: {in: BG_MODES}
  validates :subtitle, length: {maximum: 120}
  validates :sub_title, length: {maximum: 120}
  validate :validate_image

  def image?
    image_data.present?
  end

  def logo?
    respond_to?(:logo_data) && logo_data.present?
  end

  # 확장자·Content-Type 대신 파일 내용(시그니처)으로 형식을 판별합니다. SVG는 허용하지 않습니다.
  def self.detect_image_type(bytes)
    head = bytes.to_s.byteslice(0, 12).to_s.b
    return 'image/png' if head.start_with?("\x89PNG".b)
    return 'image/jpeg' if head.start_with?("\xFF\xD8\xFF".b)
    return 'image/gif' if head.start_with?('GIF8'.b)
    return 'image/webp' if head.start_with?('RIFF'.b) && head.byteslice(8, 4) == 'WEBP'.b

    nil
  end

  private

  def validate_logo_only
    return unless logo?

    if logo_data.bytesize > MAX_LOGO_SIZE
      errors.add(:base, ::I18n.t(:error_asciisoft_image_too_large, size: '1MB'))
    elsif logo_content_type.blank?
      errors.add(:base, ::I18n.t(:error_asciisoft_image_type))
    end
  end


  def validate_image
    return validate_logo_only if image_data.blank?

    if image_data.bytesize > MAX_IMAGE_SIZE
      errors.add(:base, ::I18n.t(:error_asciisoft_image_too_large, size: '3MB'))
    elsif image_content_type.blank?
      errors.add(:base, ::I18n.t(:error_asciisoft_image_type))
    end
    return unless logo?

    if logo_data.bytesize > MAX_LOGO_SIZE
      errors.add(:base, ::I18n.t(:error_asciisoft_image_too_large, size: '1MB'))
    elsif logo_content_type.blank?
      errors.add(:base, ::I18n.t(:error_asciisoft_image_type))
    end
  end
end
