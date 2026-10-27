# 07. 무료 도트 이펙트 팩

[README](README.md)로 돌아가기.

배포 페이지의 라이선스·규격 문구를 워크플로가 3표로 확인했다. **zip은 아무도 열어 보지 않았다.** 그래서 안에 다른 라이선스 파일이 있는지, 실제 그림 크기·프레임 수·색 수는 모른다.

---

## 1. 쓸 수 있는 것 — CC0 [S21~S24] **3표**

상업 스팀 게임에 비용·출처 표기 없이 쓰고, 우리 팔레트(F24+)로 다시 칠해도 된다.

| 팩 | 받는 곳 | 들어 있는 것 | 규격(페이지 기준) | 단서 |
|---|---|---|---|---|
| Pixel Magic Sprite Effects (Foozle) | itch.io | 마법 이펙트(Fire Ball, Molten Spear, Water, Geyser, Rocks, Earth Spikes, Wind, Tornado, Portal 등) | 크기 주장(32×32 10종)은 **기각**됨 | Construct.net 유료판($3.99)이 따로 있다. CC0는 itch.io 판만 |
| Pixel Art Spells (DevWizard) | OpenGameArt, 2024-03-21 | 23종, 대부분 투사체(Fireball, Firebomb, Ice lance, Light bolt, Magic Ray, Magic shield, Water blast, Wind bolt, Darkness orb 등) | 16×16 태그, «스프라이트가 작다»는 댓글 | 직선·투사체 참고에 가깝다. «흑백으로 그려 엔진에서 칠한다»는 주장은 검증자끼리 어긋나 **쓰지 않는다** |
| PVFX Foundry (nerijs) | itch.io, name your own price, v0.10.0 | 44종(Frost Nova, Acid Splash, Radiant Heal, Void Implosion, Warm Explosion 등), 투명 PNG 시트 88장 | 모든 애니메이션 96×96, 20FPS(프레임당 50ms), 5열 격자, 매니페스트에 `loop_mode` | CC0 범위는 렌더된 시트·메타데이터이고 소스 프로젝트는 빠진다. 문서 일부를 AI로 썼다고 밝힌다(이미지는 절차적 렌더) |
| Gothicvania Magic Pack 9 (ansimuz) | OpenGameArt, 2022-03-10 | Dark Bolt, Fire Bomb, Lightning, Spark 4종 | 크기 주장(약 64×64, 6~12프레임)은 **기각**됨 | 작가가 다른 팩에서는 크레딧을 청했다. 표기해 두는 편이 예의다(필수 아님) |

## 2. 조심할 것 [S25][S26] **3표**

- **Free Pixel Effects Pack (CodeManu)**: Pixel FX Designer로 만든 20종, 프레임 100×100. 라이선스가 페이지 안에서 어긋난다. itch.io «Asset license» 칸은 CC BY 4.0(표기 필요)인데, 설명문은 «public domain…No credit required»다. OpenGameArt 판은 CC0다. 쓴다면 CC BY 4.0 기준으로 크레딧을 표기하는 것이 안전하다(추론).
- **Free Effect and Bullet 16x16 (BDragon1727)**: 비상업 게임만 무료다. 상업 게임은 금액 제한 없는 기부가 조건이고, CC0가 아니며, 재판매·재배포가 금지다.

## 3. 우리 게임에 넣으려면 (추론)

- **크기:** 96·100px은 캔버스 크기라 실제 그림은 더 작을 수 있다. 그래도 24px 유닛 기준으로 보면 범위 마법(반경 2~3칸 = 64~96px)에는 맞는 크기일 수 있고, 피격·투사체에는 크다. 축소는 칸 평균이 필요하니 `Image.resize`의 LANCZOS로 한다(TRILINEAR는 BILINEAR와 같다 — 메모리 «Godot 축소 필터»).
- **색:** 팔레트 고정은 `tools/art/palettes.json`의 F24+로 가장 가까운 색을 찾아 바꾸는 스크립트 하나면 된다. 다만 이펙트에는 F24+에 없는 보라·형광 연두 계열 램프가 필요할 수 있다([08](08_for_our_game.md) 결정 질문).
- **프레임 속도:** PVFX의 20FPS(50ms)는 Saint11 예시의 80ms보다 빠르다. 우리 흔적 길이(0.3초)라면 PVFX는 6프레임, Saint11 간격이면 4프레임이다.
- **어울림:** 남의 팩은 형태 언어가 우리 유닛과 다를 수 있다. 통째로 쓰기보다는 **형태와 타이밍을 참고해 우리 도트 스크립트(`tools/art/*.py`)로 다시 그리는** 쪽이 화면이 하나로 보인다. 팩을 그대로 쓰는 것은 일정이 급할 때의 대안이다.
- 사용자는 돈을 쓰지 않는 쪽을 원하고, AI 공개는 감점 요인이 아니다(메모리 «AI 공개 수용»). 쓰게 되면 `CREDITS.md`에 적는다.
