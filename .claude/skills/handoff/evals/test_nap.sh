#!/usr/bin/env bash
# nap.py 결정적 회귀 테스트. 모델 없이 스크립트 동작만 검증한다.
# 사용: bash evals/test_nap.sh   (스킬 폴더 어디서 실행해도 됨)
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; NAP="$HERE/../scripts/nap.py"; FX="$HERE/fixtures"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0
ok()   { echo "  PASS  $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL  $1"; fail=$((fail+1)); }
has()  { grep -qF -- "$2" <<<"$1" && ok "$3" || { bad "$3"; echo "$1" | sed 's/^/        | /' | head -20; }; }
hasre(){ grep -qE -- "$2" <<<"$1" && ok "$3" || { bad "$3"; echo "$1" | sed 's/^/        | /' | head -20; }; }
hasnt(){ grep -qF -- "$2" <<<"$1" && { bad "$3"; echo "$1" | sed 's/^/        | /' | head -20; } || ok "$3"; }
# 파일 안 문자열 치환 / 마지막 줄 삭제 — GNU sed -i 는 macOS(BSD sed)에서 실패하므로 python3 로
sub()      { python3 -c "import sys;p,a,b=sys.argv[1:];t=open(p,encoding='utf-8').read();open(p,'w',encoding='utf-8',newline='').write(t.replace(a,b))" "$1" "$2" "$3"; }
droplast() { python3 -c "import sys;p=sys.argv[1];L=open(p,encoding='utf-8').read().splitlines(True);open(p,'w',encoding='utf-8',newline='').write(''.join(L[:-1]))" "$1"; }
# 골든 NAP 본문에 prepare가 출력한 기계 필드를 입힌다 (모델이 하는 일을 결정적으로 재현). status 는 draft 로 들어와 check 가 올린다
apply_fields() { python3 - "$1" "$2" <<'PY'
import re, sys
out, nap = open(sys.argv[1], encoding="utf-8").read(), sys.argv[2]
fields = dict(re.findall(r"^(status|created|branch|head|dirty|worktree|session|previous): ?(.*)$", out, re.M))
text = open(nap, encoding="utf-8").read()
for k, v in fields.items():
    text = re.sub(rf"^{k}:.*$", f"{k}: {v}".rstrip(), text, count=1, flags=re.M)
open(nap, "w", encoding="utf-8").write(text)
PY
}

echo "[A] 작성: payhook (미커밋 + .env 함정)"
bash "$FX/setup_payhook.sh" "$T/payhook" >/dev/null
python3 "$NAP" prepare --root "$T/payhook" --session sess-A > "$T/prep.txt"
has "$(cat "$T/payhook/next/CURRENT.md")" "status: draft" "prepare 가 draft 초안을 디스크에 남김"
out=$(python3 "$NAP" check --root "$T/payhook"); has "$out" "[미작성]" "초안 그대로는 검사 실패(자리표시자)"; hasnt "$out" "승격" "실패하면 승격하지 않음"
cp "$HERE/golden/nap_payhook.md" "$T/payhook/next/CURRENT.md"; apply_fields "$T/prep.txt" "$T/payhook/next/CURRENT.md"
out=$(python3 "$NAP" check --root "$T/payhook"); has "$out" "결과: 통과" "골든 NAP가 검사 통과"
has "$out" "승격: status draft → active" "검사 통과 시 draft → active"; has "$(cat "$T/payhook/next/CURRENT.md")" "status: active" "승격이 파일에 반영"
has "$(cd "$T/payhook" && git status --porcelain --ignored)" "!! next/" "next/는 무시되고 추적 파일 변경 없음"
[ -f "$T/payhook/next/.CURRENT.files" ] && ok "매니페스트 생성" || bad "매니페스트 생성"
cp "$T/payhook/next/CURRENT.md" "$T/leak.md"
sub "$T/leak.md" '값은 기록하지 않음' 'whsec_live_9Fh2kQ7xLm3Pz8RtVb'
out=$(python3 "$NAP" check "$T/leak.md" --root "$T/payhook"); has "$out" "[시크릿]" ".env 값 유출을 오류로 잡음"
hasnt "$out" "9Fh2kQ7x" "검사 출력에도 비밀값을 노출하지 않음"

echo "[A'] 작성 후 코드가 바뀐 경우 → --refresh"
echo "# edit" >> "$T/payhook/src/payhook/backoff.py"
out=$(python3 "$NAP" check --root "$T/payhook"); has "$out" "worktree 불일치" "작성 후 변경을 오류로 잡음"
python3 "$NAP" prepare --refresh --root "$T/payhook" >/dev/null
out=$(python3 "$NAP" check --root "$T/payhook"); has "$out" "결과: 통과" "--refresh 후 통과 (보관 없이 제자리 갱신)"
[ -z "$(ls "$T/payhook/next/archive")" ] && ok "--refresh는 보관하지 않음" || bad "--refresh는 보관하지 않음"
git -C "$T/payhook" checkout -q -- . 2>/dev/null; droplast "$T/payhook/src/payhook/backoff.py"
python3 "$NAP" prepare --refresh --root "$T/payhook" >/dev/null

echo "[C] 재개: 드리프트"
cp -r "$T/payhook" "$T/benign"; git -C "$T/benign" add src tests; git -C "$T/benign" commit -qm "wip"
out=$(python3 "$NAP" drift --root "$T/benign"); has "$out" "작업 내용은 기록 시점과 동일" "WIP를 그대로 커밋만 한 경우를 구분"
bash "$FX/drift_payhook.sh" "$T/payhook" >/dev/null
out=$(python3 "$NAP" snapshot --root "$T/payhook"); has "$out" "드리프트: DRIFT" "스냅샷이 드리프트를 표시"
out=$(python3 "$NAP" drift --root "$T/payhook"); rc=$?
has "$out" "새 커밋 1개" "새 커밋 감지"; has "$out" "새로 변경   src/payhook/handler.py" "인수인계 이후 바뀐 파일만 정확히 지목"
hasnt "$out" "backoff.py" "인수인계 전부터 있던 변경은 섞지 않음"; [ $rc -eq 1 ] && ok "drift exit 1" || bad "drift exit 1"

echo "[B] 작성: csvtool (막다른 길)"
bash "$FX/setup_csvtool.sh" "$T/csvtool" >/dev/null
python3 "$NAP" prepare --root "$T/csvtool" --session sess-B > "$T/prep.txt"
cp "$HERE/golden/nap_csvtool.md" "$T/csvtool/next/CURRENT.md"; apply_fields "$T/prep.txt" "$T/csvtool/next/CURRENT.md"
out=$(python3 "$NAP" check --root "$T/csvtool"); has "$out" "통과" "골든 NAP가 검사 통과"
has "$out" "sample_utf8_bom.csv" "새로 만들 파일은 경고로만 표시"

echo "[D] 브랜치 전환·보관·복원·완료"
R="$T/csvtool"; git -C "$R" stash -qu; git -C "$R" switch -qc feature/other
python3 "$NAP" prepare --root "$R" > "$T/prep2.txt"
has "$(cat "$T/prep2.txt")" "상태를 유지한 채 보관" "다른 브랜치 NAP는 superseded로 덮지 않음"
arch=$(ls "$R/next/archive/"*.md); has "$(cat "$arch")" "status: active" "보관본 status 유지"
[ -f "${arch%.md}.files" ] && ok "보관 시 매니페스트 동반 이동" || bad "보관 시 매니페스트 동반 이동"
rm -f "$R/next/CURRENT.md" "$R/next/.CURRENT.files"; git -C "$R" switch -q fix/korean-csv-encoding; git -C "$R" stash pop -q
out=$(python3 "$NAP" snapshot --root "$R"); has "$out" "현재 브랜치(fix/korean-csv-encoding)의 보관된 활성 NAP" "원래 브랜치로 오면 보관된 활성 NAP를 안내"
python3 "$NAP" restore "${arch#$R/}" --root "$R" >/dev/null
out=$(python3 "$NAP" drift --root "$R"); has "$out" "판정: CLEAN" "복원 후 드리프트 없음"
python3 "$NAP" mark resumed --root "$R" >/dev/null; has "$(cat "$R/next/CURRENT.md")" "status: resumed" "mark resumed"
python3 "$NAP" mark done --root "$R" >/dev/null
[ ! -e "$R/next/CURRENT.md" ] && ls "$R/next/archive/" | grep -q ".files" && ok "mark done → 매니페스트와 함께 보관" || bad "mark done → 매니페스트와 함께 보관"

echo "[E] 비정상 환경"
mkdir -p "$T/plain"; out=$(python3 "$NAP" snapshot --root "$T/plain"); rc=$?
has "$out" "git 저장소가 아님" "git 아닌 폴더"; [ $rc -eq 0 ] && ok "snapshot은 항상 exit 0" || bad "snapshot은 항상 exit 0"
out=$(cd "$T/payhook/src" && python3 "$NAP" snapshot --root '${CLAUDE_PROJECT_DIR}'); hasre "$out" '^- 루트: .*payhook\r?$' "치환 안 된 --root는 cwd의 git 최상위로 폴백"

echo "[F] 같은 브랜치 재인수인계: 이전 NAP 승격 시점 · 무변화 가드"
P="$T/payhook"
python3 "$NAP" prepare --root "$P" --session sess-F > "$T/prep3.txt"
prev=$(sed -n 's/^previous: //p' "$T/prep3.txt" | tr -d '\r')
has "$(cat "$P/$prev")" "status: active" "prepare 는 이전 NAP 의 상태를 바꾸지 않음"
cp "$HERE/golden/nap_payhook.md" "$P/next/CURRENT.md"; apply_fields "$T/prep3.txt" "$P/next/CURRENT.md"
out=$(python3 "$NAP" check --root "$P"); has "$out" "이전 NAP superseded" "검사 통과 시 이전 NAP superseded"
has "$(cat "$P/$prev")" "status: superseded" "이전 NAP 파일에 반영"
out=$(python3 "$NAP" prepare --root "$P"); rc=$?
has "$out" "인수인계할 변화 없음" "변화 없는 활성 NAP 위에 prepare → 가드"; [ $rc -eq 1 ] && ok "가드 exit 1" || bad "가드 exit 1"
has "$(cat "$P/next/CURRENT.md")" "status: active" "가드가 걸리면 CURRENT.md 를 건드리지 않음"
python3 "$NAP" prepare --force --root "$P" >/dev/null && ok "--force 로 진행" || bad "--force 로 진행"

echo; echo "결과: PASS $pass · FAIL $fail"; [ $fail -eq 0 ]
