# frozen_string_literal: true

module AsciisoftPortal
  DEFAULTS = {
    'terminology' => '1', 'filter_labels' => '1', 'module_new_button' => '1',
    'default_all_status' => '1', 'notifications' => '1', 'poll_seconds' => '30',
    'customer_role' => '일반 사용자', 'new_status_names' => '신규등록',
    'excluded_status_names' => '반려', 'wiki_index_first' => '1',
    'auto_due_date' => '1', 'internal_group' => '아스키 소프트',
    'pf_start' => '시작일', 'pf_end' => '종료일', 'pf_manager' => '담당자(직책)', 'pf_phone' => '담당자 연락처'
  }.freeze

  module_function

  # 패치는 여러 번 호출되어도 한 번만 적용됩니다 (개발 모드 리로드 대응).
  def setup!
    apply_patch(::Redmine::MenuManager::MenuHelper, Patches::MenuHelperPatch)
    apply_patch(::IssuesController, Patches::IssuesControllerPatch)
    apply_patch(::ProjectsHelper, Patches::ProjectsHelperPatch)
    apply_patch(::Issue, Patches::IssuePatch)
    apply_patch(::Journal, Patches::JournalPatch)
    apply_patch(::Project, Patches::ProjectPatch)
    apply_patch(::BoardsController, Patches::SortDefaultPatch)
    apply_patch(::FilesController, Patches::SortDefaultPatch)
    apply_patch(::AccountController, Patches::AccountControllerPatch)
    apply_patch(::MyController, Patches::MyControllerPatch)
    UserFormats.install!
    WikiMenu.install!
    AsciisoftPortal::Hooks # 훅 리스너 등록 (autoload)
    Terminology.install!
  end

  def apply_patch(target, patch)
    target.prepend(patch) unless target.ancestors.include?(patch)
  end

  def settings
    s = Setting.respond_to?(:plugin_asciisoft_portal) ? Setting.plugin_asciisoft_portal : nil
    s.is_a?(Hash) ? DEFAULTS.merge(s.to_h.transform_keys(&:to_s)) : DEFAULTS.dup
  rescue StandardError
    DEFAULTS.dup
  end

  def setting(key)
    settings[key.to_s]
  end

  def enabled?(key)
    v = setting(key)
    v == true || v.to_s == '1' || v.to_s == 'true'
  end

  def name_list(key)
    setting(key).to_s.split(/[,\n]/).map(&:strip).reject(&:empty?)
  end

  def base_path
    Redmine::Utils.relative_url_root.to_s
  end
end
