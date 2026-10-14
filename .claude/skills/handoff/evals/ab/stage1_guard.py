"""단계 1 격리 훅(PreToolUse): 원본 저장소·원본 대화 기록·실험 자료 경로를 쓰는 도구 호출을 막고 기록한다.

stage1_rubric.md §2의 6. 사용: python stage1_guard.py <기록 파일> (도구 호출 JSON은 stdin)
"""
import json, re, sys

BAD = re.compile(r'bhy99[\\/]+td-proj|C--Users-bhy99-td-proj|handoff-ab|file-history|history\.jsonl|[\\/]_hook', re.I)
# 쓰는 글(계획 파일 본문 등)에 경로가 적힌 것은 접근이 아니다. 파일럿에서 계획 파일 쓰기가 막혀 모델이 본문을 고쳤다
TEXT_KEYS = {'content', 'new_string', 'old_string', 'description', 'plan'}

d = json.loads(sys.stdin.buffer.read().decode('utf-8'))
s = json.dumps({k: v for k, v in d.get('tool_input', {}).items() if k not in TEXT_KEYS}, ensure_ascii=False)
m = BAD.search(s)
if m:
    with open(sys.argv[1], 'a', encoding='utf-8') as f:
        f.write(json.dumps({'tool': d.get('tool_name'), 'hit': m.group(0), 'input': s[:300]}, ensure_ascii=False) + '\n')
    print('작업 저장소 밖 경로라 막았다.', file=sys.stderr)
    sys.exit(2)
