# frozen_string_literal: true

module AsciisoftPortal
  # 관리 > 설정 > 표시 > 사용자 표시 형식에 "이름/회사" 계열 형식을 추가합니다.
  # 이름 = 사용자 이름(firstname), 회사 = 성(lastname) 칸에 입력한 값입니다.
  # 플러그인을 제거하면 레드마인 기본 형식(이름 성)으로 돌아갑니다.
  module UserFormats
    # rubocop:disable Lint/InterpolationCheck
    FORMATS = {
      asciisoft_name_slash_company: '#{firstname}/#{lastname}',
      asciisoft_name_spaced_slash_company: '#{firstname} / #{lastname}',
      asciisoft_name_paren_company: '#{firstname}(#{lastname})',
      asciisoft_name_spaced_paren_company: '#{firstname} (#{lastname})'
    }.freeze
    INITIALS = '#{firstname.to_s.first}'
    # rubocop:enable Lint/InterpolationCheck

    module_function

    def install!
      FORMATS.each_with_index do |(key, string), i|
        next if ::User::USER_FORMATS.key?(key)

        ::User::USER_FORMATS[key] = {
          string: string, initials: INITIALS,
          order: %w[firstname lastname id], setting_order: 20 + i
        }
      end
    rescue StandardError => e
      Rails.logger&.error("[asciisoft_portal] user formats: #{e.message}")
    end
  end
end
