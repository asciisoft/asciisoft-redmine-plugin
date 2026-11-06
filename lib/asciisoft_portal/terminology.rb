# frozen_string_literal: true

module AsciisoftPortal
  # 번역 파일을 수정하지 않고, 메모리에 올라온 번역값만 바꿉니다.
  # 플러그인을 제거하거나 설정을 끄고 재시작하면 원래 문구로 돌아옵니다.
  # 다른 플러그인(Agile 등)의 번역도 함께 바뀝니다.
  module Terminology
    KO_RULES = [
      [/일감/, '요청'],
      [/요청를/, '요청을'] # 원본 번역의 조사 오류 보정
    ].freeze

    EN_RULES = [
      [/\bAn issue\b/, 'A request'],
      [/\ban issue\b/, 'a request'],
      [/\bIssues\b/, 'Requests'],
      [/\bIssue\b/, 'Request'],
      [/\bissues\b/, 'requests'],
      [/\bissue\b/, 'request'],
      [/\bISSUES\b/, 'REQUESTS'],
      [/\bISSUE\b/, 'REQUEST']
    ].freeze

    # 상태 이름 '진행중'과 겹치는 기본 필터 문구 정리
    KO_FILTER_LABELS = {
      label_equals: '같음',
      label_not_equals: '같지 않음',
      label_contains: '포함',
      label_not_contains: '포함 안 함',
      label_home: '메인화면',
      label_open_issues: '미완료',
      label_open_issues_plural: '미완료',
      label_closed_issues: '종료',
      label_closed_issues_plural: '종료'
    }.freeze

    SKIP_KEYS = %i[date time datetime number support].freeze

    module BackendExt
      protected

      def init_translations
        super
        AsciisoftPortal::Terminology.transform!(self)
      end
    end

    module_function

    def install!
      backend_class = ::I18n::Backend::Simple
      backend_class.prepend(BackendExt) unless backend_class.ancestors.include?(BackendExt)
      backend = ::I18n.backend
      transform!(backend) if backend.respond_to?(:initialized?) && backend.initialized?
    end

    def transform!(backend)
      data = backend.send(:translations)
      return unless data

      if AsciisoftPortal.enabled?('terminology')
        data[:ko] = walk(data[:ko], KO_RULES) if data[:ko]
        data[:en] = walk(data[:en], EN_RULES) if data[:en]
      end
      if AsciisoftPortal.enabled?('filter_labels') && data[:ko].is_a?(Hash)
        data[:ko] = data[:ko].merge(KO_FILTER_LABELS)
      end
    rescue StandardError => e
      Rails.logger&.error("[asciisoft_portal] terminology: #{e.class}: #{e.message}")
    end

    def walk(value, rules, key = nil)
      case value
      when Hash
        value.each_with_object(value.class.new) do |(k, v), h|
          h[k] = SKIP_KEYS.include?(k) ? v : walk(v, rules, k)
        end
      when Array
        value.map {|v| walk(v, rules) }
      when String
        rules.reduce(value) {|s, (re, rep)| s.gsub(re, rep) }
      else
        value
      end
    end
  end
end
