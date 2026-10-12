#!/bin/sh
# nap.py 실행기 — SKILL.md 는 nap.py 를 직접 부르지 않고 `/bin/sh …/nap.sh <명령>` 으로 부른다.
# [의도] python3 가 PATH 에 없는 Windows Git Bash 에서도 스킬 로드 시 스냅샷(`!`)과 준비·검사 명령이 돌게 한다
# [이유] 이 PC 의 Bash 툴·스킬 셸은 PATH 가 Windows 식(';')으로 섞여 들어와 python3·git·ls 를 모두 못 찾고,
#        /usr/bin·/mingw64/bin 을 앞에 붙이면 풀린다(실측). /c/Python314 는 이 PC 의 설치 경로다.
PATH="/usr/bin:/bin:/mingw64/bin:$PATH"
export PATH
for py in python3 python /c/Python314/python.exe; do
    # Windows 스토어 별칭(실행하면 실패하는 껍데기)을 거르려고 실제로 돌려 본다
    if "$py" -c "" >/dev/null 2>&1; then
        exec "$py" "$(dirname "$0")/nap.py" "$@"
    fi
done
echo "nap.sh: python 을 찾지 못했다 (python3 · python · /c/Python314/python.exe)" >&2
exit 127
