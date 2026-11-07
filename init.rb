# frozen_string_literal: true

# ASCII SOFT Portal — Redmine 7 plugin
# 테마(themes/asciisoft)와 함께 동작합니다. 플러그인을 제거하면 모든 변경이 원래대로 돌아갑니다.

Redmine::Plugin.register :asciisoft_portal do
  name 'ASCII SOFT Portal'
  author 'ASCII SOFT'
  description '요청 용어 변경, 모듈별 등록 버튼, 실시간 알림, 프로젝트 헤더, 화면 모드'
  version '1.6.0'
  url 'https://asciisoft.com'
  author_url 'https://asciisoft.com'
  requires_redmine version_or_higher: '6.0.0'

  settings default: {
    'terminology'           => '1',   # 일감 → 요청 / Issue → Request
    'filter_labels'         => '1',   # 상태 필터 문구: 진행중 → 미완료, 완료됨 → 종료
    'module_new_button'     => '1',   # + 메뉴를 현재 모듈에 맞는 등록 버튼 하나로
    'default_all_status'    => '1',   # 요청 목록 첫 화면을 '전체' 상태로
    'notifications'         => '1',   # 실시간 알림
    'poll_seconds'          => '30',
    'customer_role'         => '일반 사용자',
    'new_status_names'      => '신규등록',
    'excluded_status_names' => '반려',
    'wiki_index_first'      => '1',   # 위키 메뉴를 누르면 문서 목록부터 표시
    'auto_due_date'         => '1',   # 완료 상태로 바꾸면 완료일 자동 입력
    'internal_group'        => '아스키 소프트', # 프로젝트 목록 검색영역을 볼 수 있는 그룹
    # 프로젝트 카드에 표시할 프로젝트 사용자 정의 필드 이름
    'pf_start' => '시작일', 'pf_end' => '종료일', 'pf_manager' => '담당자(직책)', 'pf_phone' => '담당자 연락처'
  }, partial: 'settings/asciisoft_portal'
end

AsciisoftPortal.setup!
