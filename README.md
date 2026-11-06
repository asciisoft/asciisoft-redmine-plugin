# ASCII SOFT Portal (Redmine plugin)

Redmine 7.0.x용 플러그인입니다. 테마(https://github.com/asciisoft/asciisoft-redmine-theme)와 함께 사용합니다.

## 기능

- 용어 변경: 일감 → 요청, Issue → Request (번역 파일은 수정하지 않고 메모리에서만 바꿉니다)
- 상태 필터 문구 변경: 진행중 → 미완료, 완료됨 → 종료
- "+" 메뉴를 현재 모듈에 맞는 등록 버튼 하나로 표시 (권한이 없으면 숨김)
- 요청 목록 첫 화면을 '전체' 상태로 표시
- 실시간 알림: 배정, @멘션, 내 요청의 상태 변경·댓글, 기한 임박
- 프로젝트 설정 "포털 헤더" 탭: 진행 상태 표시, 부가 문구, 헤더 배경 이미지
- 프로젝트 헤더 통계(신규·진행·지연·진척도)
- 사용자별 화면 모드 저장
- 사용자 표시 형식 추가: 이름/회사, 이름 / 회사, 이름(회사), 이름 (회사) — 관리 > 설정 > 표시 > 사용자 표시 형식 (회사는 사용자 '성' 칸에 입력)
- 기본 정렬 변경: 게시판 글 목록과 파일 목록은 등록일 최신순
- 파일 목록: 번호 · 설명 열 추가, Checksum · 다운로드 수 열 제거
- 위키 메뉴를 누르면 문서 목록(제목별 색인)부터 표시

## 설치

폴더 이름은 반드시 `asciisoft_portal`로 받습니다. 플러그인 ID와 다르면 레드마인이 시작되지 않습니다.

```bash
sudo -u redmine -i
cd $REDMINE        # 레드마인 설치 폴더

git clone https://github.com/asciisoft/asciisoft-redmine-plugin.git plugins/asciisoft_portal

# DB 테이블 3개 생성
bundle exec rake redmine:plugins:migrate NAME=asciisoft_portal RAILS_ENV=production

sudo systemctl restart redmine   # Docker는 위 안내처럼 docker restart
```

`$REDMINE`은 `Gemfile`과 `bin/rails`가 있는 레드마인 루트 폴더입니다. `bin/rails: No such file or directory`가 나오면 `find /srv/redmine -maxdepth 3 -name Gemfile`로 위치를 확인하세요.

관리 > 플러그인 > ASCII SOFT Portal > 설정에서 고객 역할, 통계 기준 상태 등을 확인하세요.
용어 관련 설정을 바꾼 뒤에는 레드마인을 재시작해야 적용됩니다.

비공개 저장소는 GitHub 계정과 Personal Access Token(읽기 권한)이 필요합니다.
SSH를 쓰려면 `git@github.com:asciisoft/asciisoft-redmine-plugin.git` 주소와 Deploy key(읽기 전용)를 사용합니다.

## Docker로 운영하는 경우

공식 `redmine` 이미지는 레드마인 루트가 컨테이너 안(`/usr/src/redmine`)에 있어서 호스트에는 `bin/rails`가 없습니다.
아래 명령은 모두 `compose.yaml`이 있는 폴더(예: `/srv/redmine`)에서 실행합니다.

```bash
cd /srv/redmine
git clone https://github.com/asciisoft/asciisoft-redmine-plugin.git plugins/asciisoft_portal
docker compose up -d --force-recreate redmine
docker compose exec redmine ls plugins
```

`./plugins:/usr/src/redmine/plugins`가 compose.yaml에 연결되어 있어야 합니다.
`REDMINE_PLUGINS_MIGRATE: "true"`가 설정되어 있으면 컨테이너 시작 시 DB 마이그레이션이 자동 실행됩니다.
없다면 `docker compose exec redmine bundle exec rake redmine:plugins:migrate NAME=asciisoft_portal RAILS_ENV=production`을 실행하세요.

## 업데이트

```bash
cd $REDMINE
git -C plugins/asciisoft_portal pull --ff-only
bundle exec rake redmine:plugins:migrate NAME=asciisoft_portal RAILS_ENV=production
sudo systemctl restart redmine   # Docker는 위 안내처럼 docker restart
```

## 제거 (원복)

```bash
cd $REDMINE
# 테이블 삭제 (알림, 헤더 설정, 화면 모드 데이터가 삭제됩니다)
bundle exec rake redmine:plugins:migrate NAME=asciisoft_portal VERSION=0 RAILS_ENV=production
rm -rf plugins/asciisoft_portal
sudo systemctl restart redmine   # Docker는 위 안내처럼 docker restart
```

번역 파일과 레드마인 원본 파일은 수정하지 않으므로 제거하면 용어, 메뉴, 첫 화면 동작이 모두 원래대로 돌아옵니다.
남는 것은 `settings` 테이블의 `plugin_asciisoft_portal` 한 줄뿐이며 동작에는 영향이 없습니다.

## 기본 설정값

| 항목 | 기본값 |
|---|---|
| 고객 역할 | 일반 사용자 |
| '신규' 통계에 포함할 상태 | 신규등록 |
| 진척도 계산에서 제외할 상태 | 반려 |
| 알림 확인 주기 | 30초 |

## 문제 확인

오류는 요청 저장에 영향을 주지 않고 로그에만 남습니다.

```bash
grep asciisoft_portal $REDMINE/log/production.log
```
