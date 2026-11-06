# frozen_string_literal: true

module AsciisoftPortal
  module Patches
    # 기본 정렬을 '등록일 최신순'으로 바꿉니다. 사용자가 머리글을 눌러 정렬을 바꾸면 그 값이 우선합니다.
    #   게시판 글 목록(boards#show), 파일 목록(files#index)
    module SortDefaultPatch
      DEFAULTS = {
        'boards#show' => %w[created_on desc],
        'files#index' => %w[created_on desc]
      }.freeze

      def sort_init(*args)
        default = DEFAULTS["#{controller_name}##{action_name}"]
        default ? super(*default) : super
      end
    end
  end
end
