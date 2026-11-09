# .brain 래퍼 공통: 파이썬을 찾아 brain.py를 부른다(. 으로 읽는다)
# 2026-11-09
# [의도] Windows Git Bash(python3가 스토어 별칭, PATH가 ';'로 섞임)와 Linux 클라우드 세션에서 같은 명령이 돈다
# [이유] .claude/skills/handoff/scripts/nap.sh 와 같은 방식(실측으로 굳은 순서): /usr/bin·/mingw64/bin 먼저, 실제로 돌려 본 인터프리터만 쓴다
PATH="/usr/bin:/bin:/mingw64/bin:$PATH"
export PATH
PYTHONIOENCODING=utf-8
PYTHONDONTWRITEBYTECODE=1
export PYTHONIOENCODING PYTHONDONTWRITEBYTECODE
brain_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
for py in python3 python "py -3"; do
    if $py -c "import sqlite3; sqlite3.connect(':memory:').execute('create virtual table t using fts5(a)')" >/dev/null 2>&1; then
        exec $py "$brain_dir/brain.py" "$@"
    fi
done
echo "brain: FTS5가 되는 python을 찾지 못했다 (python3 · python · py -3)" >&2
exit 127
