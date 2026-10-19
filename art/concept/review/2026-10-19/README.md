# 영웅 컨셉 첫 시안 검증 키트 (2026-10-19)

3성 영웅 다섯(아이아스·세라피나·베스퍼·이그니스·실비아)의 컨셉 첫 시안에 외부 피드백을 받기 위한 묶음이다.
리뷰어는 다른 AI 채팅이나 사람이다. 이 폴더의 파일만 넘기면 검토할 수 있게 담았다.

## 쓰는 법

1. `images/`의 PNG 8장을 첨부한다.
2. [prompt.md](prompt.md)의 코드 블록 안을 통째로 붙여 넣는다.
3. [sources.md](sources.md)도 첨부한다. 리뷰어가 고칠 위치를 함수 이름으로 짚는 데 쓴다.
   - 리뷰어가 코드를 읽을 수 있으면 `tools/art/concept/`의 생성기 `.py`도 함께 준다. 없어도 검토는 된다.
4. 받은 피드백을 Claude Code 세션에 붙여 넣는다. 영웅별로 반영한다.

## 파일

| 파일 | 내용 |
|---|---|
| `prompt.md` | 리뷰어에게 붙여 넣을 프롬프트. 영웅별 [고정] 결정·[기본값]·약점, 검토 기준, 출력 형식 |
| `sources.md` | 생성기 파일 위치와 부분별 함수 목록 |
| `images/aias.png` 외 4장 | 검토 대상 컨셉 시트(1920×1080) |
| `images/chronos_ref.png` | 승인된 기준작 크로노스 시트(1920×1080) |
| `images/chronos_24px_ref.png` | 크로노스 24px 스프라이트 원본(`art/trial/chronos/idle_45_D_f24p_24.png`). 칸 8개를 세로로 이은 26×208 시트 |
| `images/chronos_24px_ref_x8.png` | 위를 8배로 키운 것(최근접 보간) |
| `.gdignore` | Godot가 이 폴더의 PNG를 가져오지 않게 한다(`.import` 파일이 생기지 않는다) |

## 영웅 상태

| 영웅 | 역할 · 이명 | 생성기 | 상태 |
|---|---|---|---|
| 아이아스 | 탱커 · 강철의 성채 | `tools/art/concept/aias.py` | 첫 시안, 피드백 전 |
| 세라피나 | 힐러 · 새벽빛의 성녀 | `tools/art/concept/seraphina.py` | 첫 시안, 피드백 전 |
| 베스퍼 | 디버퍼 · 그림자 역병의 설계자 | `tools/art/concept/vesper.py` | 첫 시안, 피드백 전 |
| 이그니스 | 마법사 · 원소의 지배자 | `tools/art/concept/ignis.py` | 첫 시안, 피드백 전 |
| 실비아 | 원거리 · 취풍의 명사수 | `tools/art/concept/sylvia.py` | 첫 시안, 피드백 전 |
| 크로노스 | 버퍼 · 시계탑의 지휘관 | `tools/art/concept/chronos.py` | 승인(`art/concept/chronos/`), 기준작 |

## 이미지 다시 굽기

이미지는 생성기를 `--scale 1`(가로 1920px)로 돌려 컨셉 시트 PNG만 옮긴 것이다. 난수 시드가 고정이라 같은 소스는 같은 그림을 낸다.
생성기를 고친 뒤 이 묶음을 새로 만들 때는 저장소 루트에서 아래를 돌린다(Git Bash).

```bash
R=art/concept/review/<날짜>; T=$(mktemp -d)
for h in aias seraphina vesper ignis sylvia chronos; do
  PYTHONUTF8=1 python tools/art/concept/$h.py --out "$T/$h" --scale 1 && cp "$T/$h/${h}_1920.png" "$R/images/$h.png"
done
mv "$R/images/chronos.png" "$R/images/chronos_ref.png"
```

`--out`을 빼면 `art/concept/<영웅>/`에 4K로 굽는다. 그것은 승인 뒤에 한다.
