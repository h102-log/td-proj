# 소스 위치

리뷰어가 «코드 위치»를 짚을 때 쓰는 목록이다. 경로는 저장소 루트 기준이다.

## 공통

- 그림 크기는 1920×1080이고, y는 아래로 갈수록 커진다. 인물 중심은 x≈960, 발바닥은 y≈996이다.
- 색은 생성기마다 맨 위의 `K` 사전에 있다. 주석에 f24p 색이 표시돼 있다.
- 그리는 순서는 `hero()`의 `parts`(인물)와 `build()`의 `scene`(장면 전체)에 있다. 뒤에 적힌 것이 위에 그려진다.
- 시트 글자·확대 원·팔레트는 `sheet()`에 있다. 확대 원이 보는 곳은 `INSETS`, 팔레트 칸은 `PALETTE`에 있다.

| 파일 | 하는 일 |
|---|---|
| `tools/art/concept/chronos.py` | 승인된 크로노스 생성기. 다른 생성기가 도구를 가져다 쓴다: `smooth`(곡선), `cel`(채움·셀 음영·외곽선), `limb`(팔다리), `along`(선분 위의 점), `ribbon`(띠), `label`(글자), `lin`·`rad`(그라데이션), `diamond`, `pol`·`circ` |
| `tools/art/concept/shot.py` | SVG → PNG 촬영(헤드리스 Chrome) |
| `tools/art/concept/vesper.py`의 `rot`·`ell`·`polyline` | 회전·타원·꺾은선. `ignis.py`·`sylvia.py`도 가져다 쓴다 |

## 아이아스 — `tools/art/concept/aias.py`

| 부분 | 함수 |
|---|---|
| 배경·효과 | `background()` 먼 성채 탑, `rampart()` 등 뒤의 빛의 성벽, `floor()` 룬 원과 충격파 고리, `embers()` 불티 |
| 투구 | `helmet()` 코린트식 투구와 진홍 깃, `crest_tail()` 깃 꼬리, `eyes_glow()` 투구 속 눈빛 |
| 몸 | `cuirass()` 근육 흉갑, `pauldron()` 어깨 갑옷, `skirt()` 치마 끝단과 가죽 띠, `legs()`·`sabaton()` 다리와 철신, `cape()` 망토, `neck()` |
| 창 | `arm_spear()` 오른팔, `fist()` 주먹, `spear()` 자루·창날·술 |
| 방패 | `arm_shield()` 왼팔, `shield()` 탑 방패(성가퀴 `crenel()`), `emblem()` 문장, `runes()` 룬 기호 |
| 빛 | `fill_light()` 인물 안 채움빛 |

## 세라피나 — `tools/art/concept/seraphina.py`

| 부분 | 함수 |
|---|---|
| 배경·효과 | `background()` 기둥·아치, `rose_window()`·`tracery()` 장미창, `rays()` 빛줄기, `floor()` 정화의 성역 문양, `motes()` 빛 알갱이·깃털 |
| 머리 | `veil_cap()`·`veil_back()` 베일, `hair_back()`·`hair_front()` 머리, `face()` 얼굴, `diadem()` 해 관, `neck()`·`collar()` |
| 몸 | `bodice()` 몸판, `skirt()` 치마, `stole()` 영대, `belt()`, `shoes()` |
| 팔·지팡이 | `arm_upper()` 위팔, `sleeve()` 종 소매, `arm_staff()`·`fist()`·`staff()` 지팡이 쪽, `arm_bless()`·`orb()` 빛 구슬 쪽 |
| 빛 | `fill_light()` |
| 도우미 | `strip()` 고른 폭 띠, `sunburst()` 햇살 삼각형 |

## 베스퍼 — `tools/art/concept/vesper.py`

| 부분 | 함수 |
|---|---|
| 배경·효과 | `background()` 역병 도시 첨탑, `blueprint()` 공중의 저주 도면(7각 별), `swamp()` 늪, `mist()` 향로 독안개(`PLUMES`), `front_fog()` 앞 안개, `spores()` 포자 |
| 머리 | `hat()` 챙 모자, `hood()` 두건, `lenses()` 렌즈, `beak()` 새부리 가면(`BEAK`) |
| 몸 | `coat()` 긴 코트(`COAT_L`·`HEM`·`OPEN`), `capelet()` 어깨 망토, `straps()` 가슴 끈·허리띠·약병, `boots()` |
| 팔·소품 | `sleeve()`·`cuff()`·`fist()` 팔과 장갑(`ARM_C`·`ARM_P`), `censer()` 독 향로와 사슬, `compass()` 컴퍼스 |
| 빛 | `fill_light()` |

## 이그니스 — `tools/art/concept/ignis.py`

| 부분 | 함수 |
|---|---|
| 배경·효과 | `background()` 밤하늘·운석우(`METEORS`)·산, `floor()` 불·서리 반반 문양, `orbit()`·`orb()` 원소 구슬 궤도(`ORBS`), `fireball()` 화염구, `frost()` 서리 파편(`FROST_PATH`) |
| 머리 | `hair_back()` 불꽃 뒷머리(`HAIR`), `hair_front()` 앞머리·옆 가닥, `face()` 얼굴, `collar()`·`neck()` |
| 몸 | `bodice()` 몸판, `belt()` 원소 보석 허리띠, `skirt()` 로브 자락(`SK_L`·`SK_R`·`HEM`·`OPEN`), `boots()` |
| 팔 | `sleeve_up()`·`hand_up()` 화염구를 든 팔, `sleeve_dn()`·`hand_dn()` 서리를 흘리는 팔, `fingers()` 손가락 |
| 빛 | `fill_light()` |
| 도우미 | `tongue()` 불꽃 혀 모양, `ring_pt()` 궤도 위의 점 |

## 실비아 — `tools/art/concept/sylvia.py`

| 부분 | 함수 |
|---|---|
| 배경·효과 | `background()` 고원·구름·산, `grass()` 바람에 눕는 풀, `trap()` 숨긴 폭풍의 덫, `wind_streaks()` 바람결·잎, `gale()` 화살을 감은 바람 나선 |
| 머리 | `hair()` 머리통·귀, `ponytail()` 포니테일, `face()` 반측면 얼굴(`FACE`), `hood()` 내린 후드 |
| 몸 | `torso()` 웃옷·가죽 코르셋·멜빵, `skirt()` 웃옷 자락(`SKIRT`), `leg()` 다리·장화, `cloak()` 망토(`CLOAK`), `scarf_wrap()`·`scarf_tails()` 스카프, `quiver()` 등의 화살통 |
| 팔·활 | `arm_draw()` 시위 당긴 팔(`SH_N`·`EL_N`·`D`), `arm_bow()`·`hand_bow()` 활 든 팔(`SH_F`·`EL_F`·`WR_F`), `bow()` 활(`G`·`LIMB`), `string()` 시위, `arrow()` 화살(`TIP`) |
| 빛 | `fill_light()` |
| 도우미 | `taper()` 가늘어지는 띠, `on_arrow()` 화살 선 위의 y, `leaf()` 잎 |
