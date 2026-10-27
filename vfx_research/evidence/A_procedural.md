# A. 코드로 그리는 이펙트: Mindustry와 Shattered Pixel Dungeon 소스 확인

> 보충 조사 에이전트 A가 쓴 원본 메모다(2026-10-27). 본문의 `vfx_supp/src/`·`img_a/` 경로는 세션 스크래치에 있었고 저장소에는 없다. 남의 그림(SPD 아틀라스 확대본)은 넣지 않았다. 핵심 주장 셋(blastExplosion, effectChance 0.15, Drawf.circles)은 정리 단계에서 받은 소스와 다시 대조했다.


조사일 2026-10-27. 두 게임의 소스를 커밋을 고정해 받아서 읽기만 했다. 웹 검색은 쓰지 않았다(0회).

- Mindustry `b873c01e`, Arc(Mindustry 엔진) `7445105c`, SPD `57a4e06a`
- 받은 파일: `vfx_supp/src/mindustry/`, `src/arc/`, `src/spd/`(SPD 그림 두 장은 `src/spd/assets/`). 확대 이미지는 `vfx_supp/img_a/`.
- 표기: 출처 링크가 붙은 문장은 **코드로 확인한 사실**이다. 내 해석이나 계산은 **(추론)**이라고 붙였다.
- 단위: Mindustry는 tick 단위다(60 tick = 1초). 거리는 world unit이며 타일 한 칸이 8이다([Vars#tilesize]). SPD는 초와 아트 픽셀 단위이며 타일 한 칸이 16px이다([DungeonTilemap.SIZE=16], `tiles/DungeonTilemap.java:36`).

---

## 0. 먼저 결론

1. **두 게임 모두 순수 코드도, 순수 스프라이트도 아니다.** Mindustry의 순간 이펙트는 거의 모두 `Lines`·`Fill`로 그린 코드 이펙트다. 그러나 타일 위 불은 40프레임 스프라이트다([FireComp#draw]). 텍스처를 늘려 레이저를 그리는 헬퍼 `Drawf.laser(TextureRegion …)`도 따로 있다([Drawf#laser], 어디서 쓰는지는 확인 안 함). SPD의 파티클은 단색 정사각형을 코드로 움직인다. 반면 번개·광선·가스·물결은 7×7~16×16 크기의 아주 작은 스프라이트를 늘이거나 색을 입혀 쓴다([Effects#get], [Speck#film]).
2. **굵기를 고정하지 않는다.** Mindustry는 굵기에 `stroke(k * e.fout())`를 쓰고 반경에 `a + b * e.finpow()`를 쓴다. 고리가 빠르게 퍼지면서 동시에 가늘어진다([Fx#healWave], [Scaled]). 우리 이펙트처럼 1~2px에 알파만 줄이는 방식은 두 게임 어디에도 없다.
3. **한 번의 폭발을 3~4겹으로 쌓는다.** 겹마다 수명 곡선과 무작위 시드가 다르다. 예를 들어 `blastExplosion`은 빠른 고리(6 tick) + 회색 연기 5개 + 주황 불티 4개 + 빛으로 구성된다([Fx#blast]). 색도 겹마다 다르게 준다. 밝은 front, 진한 back, 중립 회색을 나눠 쓰고 순수 RGB는 쓰지 않는다([Pal]).
4. **상태이상을 고리로 그리지 않는다.** Mindustry는 매 tick 확률(`effectChance`, 기본 0.15)로 몸 안의 무작위 지점에서 지름 1~3 unit의 작은 파티클을 내보낸다. 이게 전부다. 몸 틴트도 없다([StatusEffect#update], [StatusEffect#draw]). SPD는 두 가지를 섞는다. 불탐·냉기는 스프라이트 사각형 범위 안에서 파티클을 뿜고, 빙결·암흑·발광은 스프라이트 색을 바꾼다([CharSprite#states], [IceBlock]).
5. **장판도 반투명 원판으로 그리지 않는다.** SPD는 칸마다 매 주기 파티클을 하나씩 뿌린다. 그래서 가장자리가 칸 모양으로 불규칙해진다([BlobEmitter#emit]). Mindustry 웅덩이는 불투명한 큰 원 1개 + 시드로 정한 위성 원 3개로 그린다([Liquid#drawPuddle]).
6. **읽혀야 하는 표시에는 외곽선을 깐다.** Mindustry의 범위 원·타깃 표시는 아래에 3px 짙은 회색(`Pal.gray` #454545)을 깔고 그 위에 1px 색선을 긋는다([Drawf#circles], [Drawf#target]). 우리 상태 고리에 없는 것이 바로 이것이다(추론).
7. **무작위는 시드로 고정해 매 프레임 다시 그린다.** Mindustry 이펙트는 상태를 저장하지 않는다. 그리는 함수 안에서 `rand.setSeed(e.id)`로 같은 난수를 다시 뽑고 위치에 `fin`을 곱해 움직인다([Angles#randLenVectors], [EffectStateComp]). Godot `_draw()`에 그대로 옮길 수 있는 방식이다(추론).
8. **빛은 이펙트 층에만 준다.** Mindustry는 bloom을 bullet~effect 층에만 걸고([Renderer#bloom]), SPD는 불·불꽃·폭발 파티클만 가산 블렌딩한다([Blending#light], [FlameParticle]). 그래서 유닛은 탁해지지 않고 이펙트만 빛난다.

---

## 1. Mindustry

### 1.1 구조

- **이펙트는 그리는 함수 하나다.** `new Effect(수명, clip, e -> {...})`로 만들고, 매 프레임 `EffectContainer e`를 받아 그린다. `e.time`·`e.lifetime`·`e.id`·`e.color`·`e.rotation`·`e.data`를 쓸 수 있다([Effect#container]).
- **곡선**([Scaled]):
  - `fin()`: 0→1, `fout()`: 1→0
  - `finpow()`: `pow3Out(fin)`. 처음에 빠르고 끝에서 느리다.
  - `foutpow()`
  - `fslope()`: 0→1→0 삼각형
  - `fout(Interp)`: 원하는 곡선을 넣는다.
- **두 시간축**: `e.scaled(t, s -> ...)`는 큰 수명 안에서 앞부분 t tick만 따로 0→1로 다시 잰다([Effect#scaled]). "순간 충격 + 남는 잔해"를 한 이펙트에 담는 데 쓴다.
- **시드**: `Angles.randLenVectors(seed, 개수, 길이, cons)`는 seed로 난수를 다시 맞춘 뒤 방향·거리를 뽑는다([Angles#randLenVectors]). 이펙트들은 `e.id`와 `e.id + 1`을 써서 서로 다른 두 묶음을 얻는다([Fx#blast]). `e.id`는 이펙트 엔티티의 id다([EffectStateComp]). 저장된 파티클 배열이 없는 셈이다.
- **원 꼭짓점 수**는 `11 + 반경 * 0.4`다([Lines#circleVertices]). 반경 20 unit 원이 19각형이다.
- **빛과 bloom**:
  - `Drawf.light`는 별도 광원 버퍼에 원형 빛을 더한다([Drawf#light]).
  - bloom은 기본으로 켜져 있다([Settings#bloom]). 범위는 `Layer.bullet - 0.02`부터 `Layer.effect + 0.02`까지로, 이 층만 번진다([Renderer#bloom]).
- **도트 모드**: `pixelate`(기본 꺼짐, [Settings#pixelate])를 켜면 화면을 world unit 해상도 버퍼에 그리고 `nearest`로 키운다([Pixelator]). 우리 640×360 정수배와 같은 구조다. 기본값은 고해상도 선이므로, Mindustry 선은 평소에 도트 격자보다 매끈하게 보인다(추론).

### 1.2 대표 이펙트 표

| 이름 | 용도 | 수명 | 굵기·크기 곡선 | 색 | 파티클·겹 | 근거 |
|---|---|---|---|---|---|---|
| `blastExplosion` | 범위 폭발(미사일) | 22 tick(0.37초) | ① 고리: 앞 6 tick만, 굵기 `3·fout` → 0, 반경 `3 + 15·fin`<br>② 연기 원: 반경 `4·fout + 0.5`, 퍼짐 `2 + 23·finpow`<br>③ 불티 선: 길이 `1 + 3·fout`, 굵기 `fout` | 고리 `missileYellow` #ffd2ae, 연기 `Color.gray`, 불티 `missileYellowBack` #e58956, 빛 반경 45, 알파 `0.8·fout` | 4겹(고리, 연기 5개[seed id], 불티 4개[seed id+1], 빛) | [Fx#blast] |
| `explosion` | 일반 폭발 | 30 tick | 고리: 앞 7 tick만 `3·fout`<br>연기 6개: 큰 원 `3·fout + 0.5`와 그 절반 거리의 작은 원 `fout`을 같이 찍는다<br>불티 8개: 굵기 `1.5·fout` | 불티 색 `lighterOrange` #f6e096 → `lightOrange` #f68021 → gray, 3단 보간 | 3겹 + 연기 2중 | [Fx#explosion] |
| `dynamicExplosion` | 크기 가변 폭발 | `43 + 35·세기` tick | 연기: 4묶음, 묶음마다 수명 비율을 시드로 0.4~1배, 퍼짐 `pow10Out`<br>고리: `5 + 2.5·세기` tick<br>불티: `9·세기`개, 불티마다 빛 | 연기 gray, 알파 0.9 / 불티 위와 같은 3단 보간 | 6겹 이상 | [Fx#dynamicExplosion] |
| `shockwave` | 충격파 고리 | 10 tick | 굵기 `2·fout + 0.2`, 반경 `28·fin` | white → lightGray | 1겹 | [Fx#shockwave] |
| `pointShockwave` | 지점 충격 | 20 tick | 고리 굵기 `2·fout`, 반경 `finpow·r`<br>방사선 8개: 길이 `1 + 3·fout` | `e.color` | 2겹 | [Fx#pointShockwave] |
| `hitBulletSmall` | 피격 스파크 | 14 tick | 안쪽 고리: 앞 7 tick, 반경 `5·fin`, 굵기 `0.5 + fout`<br>방사선 5개: 길이 `3·fout + 1`, 퍼짐 `15·fin`, 진행 방향으로 눕힘 | white → `lightOrange`, fin으로 보간 | 3겹(고리, 선, 빛 20) | [Fx#hitBulletSmall] |
| `hitLancer` | 레이저 피격 | 12 tick | 방사선 8개, 굵기 `1.5·fout`, 퍼짐 `17·finpow` | white | 1겹 | [Fx#hitLancer] |
| `healWave` / `heal` | 힐 범위 고리 / 개별 힐 | 22 / 11 tick | 굵기 `2·fout`, 반경 `4 + 60·finpow` / `2 + 7·finpow` | `Pal.heal` #98ffa9 | 1겹 | [Fx#healWave] |
| `greenBomb` | 힐 폭발 | 40 tick | 고리 `2·fout`, 반경 `4 + 65·finpow`<br>십자 삼각형 4개: 길이 `100·fout`<br>안쪽 흰 삼각형 4개: 길이 `35·fout` | heal + white 심 | 4겹(고리, 색 십자, 흰 십자, 빛) | [Fx#greenBomb] |
| `LaserBulletType.draw` | 직선 레이저 | 16 tick | 색 3겹, 겹마다 굵기를 절반으로: `7.5 → 3.75 → 1.875`, 모두 `× fout`<br>길이는 수명 앞 20% 동안 늘어남(`curve(fin, 0, 0.2)`)<br>끝에 뾰족한 삼각형, 총구 원과 옆 날개 삼각형 | `lancerLaser` #a9d8ff(알파 0.4) → `lancerLaser` → white | 3색 × (선, 끝 삼각형, 총구 원, 옆 삼각형 2) + 선형 빛 | [Laser#colors], [Laser#draw] |
| `chainLightning` | 연쇄 번개 | 20 tick | 6 unit마다 꺾임점을 두고, 각 점을 무작위 방향으로 3 unit 민다. 굵기 `2.5·fout` | white → `e.color`, fin으로 보간 | 1겹 polyline. seed `e.id`라 매 프레임 모양이 같다(깜빡이지 않음) | [Fx#chainLightning] |
| `lightning` | 분기 번개 | 10 tick | 굵기 `3·fout`, 꺾임점마다 `Fill.circle(굵기/2)`로 이음매를 둥글게 | `e.color` → white(사라지면서 하얘짐) | 1겹 + 둥근 이음. 점 좌표는 ±3 흔들고 표적이 없으면 ±20° 꺾어 진행 | [Fx#lightning], [Lightning#create] |
| `shootSmallFlame` | 화염 부채꼴 | 32 tick | 원 12개, 진행 방향 ±10° 안, 거리 `60·finpow`, 반경 `0.65 + 1.5·fout` | `lightFlame` #ffdd55 → `darkFlame` #db401c → gray | 1겹 | [Fx#shootSmallFlame] |
| `scatheSlash` | 베기 | 40 tick | 수직 삼각형 2개, 폭 `25·fout`, 길이 `66·foutpow + 6` | `e.color` | 1겹 | [Fx#scatheSlash] |
| `smokeAoeCloud` | 지속 구름 장판 | 180 tick | 원 80개를 반경 90 안에 둠. 크기 `6 · clamp(fin/0.1) · clamp(fout/0.1)`: 앞뒤 10%만 커지고 줄어 평평하게 유지 | `e.color` 알파 0.65 | 1겹 | [Fx#smokeAoeCloud] |
| `drawPuddle` | 액체 웅덩이 | 상시 | 큰 원 `8f` + 위성 원 3개 `5f`(seed `id`, 반경 `6f` 안). 액체 바닥에선 sin으로 출렁 | 액체색에서 명도만 −0.05, **불투명** | 4원 + 빛 | [Liquid#drawPuddle] |
| `lancerLaserCharge` / `ChargeBegin` | 충전·예고 | 38 / 60 tick | 선 14개가 `1 + 20·fout` 거리에서 **안쪽으로 모인다**(±120°), 길이 `fslope·3 + 1`<br>중심 원: 반경 `fin·3`, 흰 심 `fin·2`, 90% 지점에서 꺼짐 | `lancerLaser`, white 심 | 2개 이펙트 | [Fx#lancerCharge] |
| `greenLaserCharge` | 큰 충전 | 80 tick | 고리가 `4 + 100·fout`로 **줄어들며** 굵기는 `2·fin`으로 굵어짐<br>원 20개가 모여들고 중심 원은 커짐 | heal + white 심 | 4겹 | [Fx#greenLaserCharge] |

모든 Fx가 같은 패턴이다(추론, 표의 근거 범위에서). 굵기는 fout을, 거리는 fin 또는 finpow를 곱하고, 색은 white 또는 front에서 accent·back·gray로 보간한다.

### 1.3 상태이상 표시

**방식은 몸에서 나오는 파티클 하나뿐이다.** 고리도 틴트도 아니다.

- 매 tick `Mathf.chanceDelta(effectChance)`가 참이면 이펙트를 하나 낸다. 위치는 유닛 중심에서 `±hitSize/2` 범위의 무작위 지점이다([StatusEffect#update] 164~166행). `chanceDelta`는 `random < 확률 × Time.delta`다([Mathf#chanceDelta]).
- 기본 `effectChance`는 0.15다([StatusEffect#fields]). 계산하면 초당 약 9개가 나온다(계산).
- `StatusEffect.draw(Unit)`의 기본 구현은 비어 있다([StatusEffect#draw]). 유닛은 그냥 이 빈 draw를 부른다([StatusComp#draw]).
- `StatusComp.statusColor()`는 걸린 상태 색들의 평균을 낸다([StatusComp#statusColor]). 하지만 이번에 읽은 `UnitType.java`·`UnitComp.java`에서는 이 함수를 부르지 않는다. 몸 틴트로 쓰이지 않는 것으로 보인다(추론, 확인 범위 한정).
- 몸 색이 바뀌는 경우는 두 가지뿐이다.
  - 피격: `Draw.mixcol(white, hitTime)`. 피격 시 1에서 시작해 9 tick에 걸쳐 0이 된다([UnitType#applyColor], [HealthComp#hitTime]).
  - 힐: white에서 `Pal.heal`로 가는 플래시를 20 tick 동안 준다([UnitComp#healTime]).

| 상태 | 상태 색 | 이펙트 | 수명 | 파티클 | 크기 곡선 | 확률/tick | 근거 |
|---|---|---|---|---|---|---|---|
| 불탐 burning | #ffc455 | `Fx.burning` | 35 | 원 3개, 퍼짐 `2 + 7·fin` | `0.1 + 1.4·fout` | 0.15(기본) | [SE#burning], [Fx#burning] |
| 얼음 freezing | #6ecdec | `Fx.freezing` | 40 | 원 2개, 퍼짐 `1 + 2·fin` | `1.2·fout` | 0.15 | [SE#freezing], [Fx#freezing] |
| 젖음 wet | `Color.royal` | `Fx.wet` | 80 | 원 1개(물방울) | 반경 `fout`, 알파 `clamp(fin·2)`(나타났다 줄어듦) | 0.09 | [SE#wet], [Fx#wet] |
| 녹음 melting | #ffa166 | `Fx.melting` | 40 | 원 2개 | `0.2 + 1.2·fout`. 슬래그색→white 보간 양을 id 시드로 ±0.12 흔든다 | 0.15 | [Fx#melting] |
| 흡수 sapped | `Pal.sap` | `Fx.sapped` | 40 | **마름모**(`Fill.square` 45°) 2개 | `1.1·fslope` | 0.1 | [SE#sapped], [Fx#sapped] |
| 감전 electrified | `Pal.heal` | `Fx.electrified` | 40 | 마름모 2개 | `1.1·fslope` | 0.1 | [SE#electrified], [Fx#electrified] |
| 과부하 overdrive(버프) | `Pal.accent` | `Fx.overdriven` | 20 | 정사각형 2개 | `2.3·fout + 0.5` | 0.15 | [SE#overdrive], [Fx#overdriven] |
| 부식 corroded | #e4ffd6 | `corrosionVapor` | 50 | 원 2개, 반경 3 | 알파 `pow2Out(fslope)·0.5` | 0.1 | [SE#corroded], [Fx#corrosionVapor] |
| 감속 slow | lightishGray | **없음** | | | | | [SE#slow] |
| 보스 boss | crux 팀색 | **없음** | | | | | [SE#boss] |

- 파티클 크기는 반경 1~2.5 unit이다. 타일(8)의 1/8~1/3, 유닛 hitSize보다 훨씬 작은 점이다.
- 상태마다 모양이 다르다. 불·얼음은 원, 흡수·감전은 마름모, 버프는 정사각형이다. 수명 곡선도 다르다. 불은 fout으로 줄고, 감전은 fslope로 반짝이고, 물은 나타났다 사라진다. 색이 비슷해도 모양과 움직임으로 구분된다(추론).
- 상태가 여럿이면 파티클이 섞여 나올 뿐 겹이 쌓이지 않는다. 상태 3~4개가 걸려도 몸 둘레 크기는 그대로다(추론).

---

## 2. Shattered Pixel Dungeon

### 2.1 구조

- **파티클은 단색 정사각형 한 장이다.** `PixelParticle`은 `PseudoPixel`을 상속하고, 흰 1×1 텍스처를 `size`배로 늘린다([PseudoPixel], [PixelParticle]). 원은 그리지 않는다.
  - `Shrinking` 계열은 매 프레임 `size × 남은 시간 / 수명`으로 줄어든다([PixelParticle#shrinking]).
- **파티클은 물리로 움직이는 진짜 객체다.** `speed`·`acc`(중력이나 부력)를 갖고 시작값을 `Random.Float`로 정한다. 시드로 다시 그리는 Mindustry와 다르다. 풀(`emitter.recycle`)로 재사용한다.
- **Emitter**:
  - `pour(factory, 간격)`은 계속 내보내고, `burst(factory, n)`은 한 번에 n개를 낸다.
  - 대상 Visual을 지정하면 그 사각형 안 무작위 지점에서 나온다([Emitter#emit]).
  - factory의 `lightMode()`가 참이면 가산 블렌딩(`GL_SRC_ALPHA, GL_ONE`)을 쓴다([Emitter#light], [Blending#light]).
- **도트 격자**:
  - 카메라 스크롤은 화면 픽셀로 반올림한다([PixelCamera#align]). 줌은 정수다(`defaultZoom`).
  - 파티클 좌표는 실수라 아트 픽셀 격자에 붙지 않는다(`Image`·`Visual`에 반올림 코드가 없는 것을 확인했다). 크기도 줄어들면서 4.0→2.7 같은 소수가 된다.
  - 즉 SPD는 스프라이트만 격자에 맞추고 파티클은 화면 픽셀 단위로 움직인다(추론. 줌이 정수라 화면에선 덩어리처럼 보이지만 아트 격자와 어긋날 수 있다).
- **스프라이트를 쓰는 효과**:
  - `effects.png` 32×64: 물결 16×16 고리, 번개 16×8, 광선 16×8 띠 3종, 사슬 등([Effects#get]). 쓰인 색은 알파 포함 20개(계산, `img_a/spd_effects_x12.png`).
  - `specks.png` 128×8: 7×7 조각 16종(십자, 별, 증기, 하트 등)([Speck#film]). 색 37개(계산).
  - 광선 띠는 가로 줄무늬로 단면을 미리 그려 둔 그림이다. 흰 심, 색 띠, 반투명 테두리 순이다(이미지 확인).

### 2.2 대표 이펙트 표

| 이름 | 용도 | 수명 | 크기 곡선 | 색 | 파티클 | 근거 |
|---|---|---|---|---|---|---|
| `BlastParticle` × 30 + 칸마다 `SmokeParticle` × 4 | 폭탄 폭발 | 불: 0~1초 무작위 / 연기: 0.6~1초 | 불: 8px에서 0으로 줄어듦. 위쪽 반원으로 32~64px/s, 중력 +50<br>연기: 8에서 16px로 커지며 위로 떠오름 | 불 #EE7722 단색 **가산** / 연기 #222222, 알파 최대 0.4 | 중심 버스트 1 + **피해 칸마다** 연기(범위가 고리가 아니라 칸으로 보인다) | [Bomb#explode], [BlastParticle], [SmokeParticle] |
| `FlameParticle` | 불(상태, 장판, 화염탄) | 0.6초 | 4px에서 0으로. 위로 가속 −80. 앞 20%에서 알파가 차오름 | #EE7722 가산 | 1색 | [FlameParticle] |
| `SparkParticle` | 전기 스파크 | 0.5~1초 | 최대 5px. **매 프레임 무작위 크기**(`Random(size × 남은 비율)`)라 깜빡인다 | 생성 시 색 지정(기본 흰색), 가산 | 1색 | [SparkParticle] |
| `Splash` | 피격 튐 | 0.5~1초 | 4px에서 0으로. 원뿔 안 40~80px/s, 중력 +100 | 호출자가 주는 1색 | n개 | [Splash#factory] |
| `bloodBurstA` | 피격 피 | 같음 | 같음 | #BB0000 | **개수 = min(9·√(피해/최대HP), 9)**, 공격자 반대쪽 90° 원뿔 | [CharSprite#bloodBurst] |
| `Lightning` | 연쇄 번개 | 0.3초 | 알파가 직선으로 1→0 | 번개 스프라이트를 늘림, 가산 | 호(arc)마다 2토막. 중간점을 **매 프레임** ±4px 다시 뽑아 지글거린다 | [SPD-Lightning] |
| `Beam` | 직선 광선 | DeathRay 0.5초, LightRay 1초, HealthRay 0.75초 | 두께 `scale.y = p`와 알파 `p`가 함께 1→0 | 띠 텍스처, 가산 | 1장 | [Beam] |
| `MagicMissile` 원뿔형 | 부채꼴 마법 | 비행 시간 = 거리/200px/s | 10×10 영역에서 0.03초마다 파티클을 뿜는다 | 파티클 종류에 따름 | 원뿔 **바깥 광선마다 미사일 하나**를 쏜다 | [MagicMissile#cone], [Fireblast#fx] |
| `Flare` | 오라, 섬광 | 지정 | 앞 25%에서 0→1로 커지고 이후 1→0. 기본 180°/s 회전 | 방사형 그라디언트(흰색에서 투명), 가산 | 광선 n개 삼각형 메시 | [Flare] |
| `Ripple` | 물결 | 0.5초 | 크기 0→1, 알파 1→0 | 16×16 고리 스프라이트 | 1장 | [Ripple] |
| `GooSprite.pumpUp` | **보스 예고** | 예고 동안 | 위험 칸마다 0.04초 간격으로 검은 4px 파티클을 뿜음. 0.3초 수명, 위로 32~48px/s | #000000 | 발동 순간 칸마다 초록 `ElmoParticle` 10개 버스트 + 소리 | [Goo#pumpUp] |
| `TargetedCell` | 공격 예정 칸 표시 | 공격 턴까지 | 알파는 공격 턴 전까지 **0.6 아래로 내려가지 않음**. 이후 줄면서 크기 `alpha^0.33` | 타깃 아이콘에 `hardlight(0xFF0000)` | 칸마다 1장 | [TargetedCell] |

### 2.3 상태이상 표시

`CharSprite.processStateAddition`이 상태마다 표현 방식을 하나씩 고른다([CharSprite#states]).

| 상태 | 방식 | 값 | 근거 |
|---|---|---|---|
| 불탐 BURNING | 몸 사각형에서 파티클 | `FlameParticle`을 0.06초마다. 계산하면 약 10개가 동시에 떠 있다 | [CharSprite#burning] |
| 냉기 CHILLED | 파티클 | `SnowParticle` 0.1초마다. 1px 흰 점이 5~8px/s로 떨어지고 1.2초 수명, 알파는 삼각형 모양 | [CharSprite#chilled], [SnowParticle] |
| 표식 MARKED | 파티클 | `ShadowParticle.UP` 0.1초마다. 검정과 #440044 사이를 보간 | [CharSprite#marked], [ShadowParticle] |
| 치유 HEALING | 스프라이트 조각 | 7×7 십자 Speck을 0.5초마다. 1초 동안 20px/s로 떠오름 | [CharSprite#healing], [Speck#healing] |
| 빙결 FROZEN | **스프라이트 틴트** | `tint(0.83, 1.17, 1.33, s)`. s는 0.5초에 걸쳐 0→0.6. 풀릴 때 #B2D6FF 튐 파티클 5개 | [IceBlock] |
| 암흑 DARKENED | 밝기 | `brightness(0.4)` | [DarkBlock] |
| 발광 GLOWING | 틴트 맥동 | `tint(1.33, 1.33, 0.83, 0.5 ± 0.1)`, 1Hz | [GlowBlock] |
| 투명 INVISIBLE | 알파 | 0.4 | [CharSprite#invisible] |
| 마비 PARALYSED | 애니메이션 정지 | `paused = true` | [CharSprite#paralysed] |
| 보호막 SHIELDED | 후광 | `ShieldHalo`. 반경 = 스프라이트 대각선의 절반, #BBAACC, 가산. `am = −0.33`이라 중심보다 가장자리가 밝은 테 모양으로 보인다(추론: Halo 텍스처가 중심이 밝은 그라디언트라고 가정) | [ShieldHalo] |
| 오라 AURA | 회전 광선 | `Flare(n, max(크기 + 4, 16))`, 90°/s | [CharSprite#aura] |
| 피격 | 흰 플래시 | `ra = ga = ba = 1`(흰색 더하기)을 0.05초 | [CharSprite#flash] |
| 버프 목록 | UI 아이콘 | 7px(작게) 또는 16px(크게). 남은 시간은 회색 덮개 높이로 보여 주고, 그 높이를 **픽셀 단위로 반올림** | [BuffIndicator] |

- 틴트 공식: 최종색 = 원색 × (1 − s) + (r, g, b) × s([Visual#tint]). (r, g, b)가 1을 넘을 수 있어서 밝게 물들이는 데도 쓴다.
- 몸 자체가 바뀌는 상태(빙결, 암흑, 발광, 투명, 마비)는 틴트나 애니메이션으로, 몸에서 무언가 나오는 상태(불, 냉기, 표식, 치유)는 파티클로 나눈다. 상태 둘이 같은 방식으로 겹치는 경우가 드물다(추론).

### 2.4 지속 장판(blobs)

`BlobEmitter.emit`은 한 번 불릴 때 값이 0보다 큰 **보이는 칸마다** 칸 안 무작위 위치에 파티클을 하나씩 낸다([BlobEmitter#emit]). 판이나 외곽선은 그리지 않는다.

| 장판 | 파티클 | 간격 | 근거 |
|---|---|---|---|
| Fire | `FlameParticle` | 0.03초. 칸마다 약 20개가 동시에 떠 있다(계산) | [Fire#use] |
| ToxicGas | Speck `TOXIC`: 7×7 증기 조각에 `hardlight(0x50FF60)`, 30°/s 회전, 1~3초 수명, 크기 1→2배, 알파 최대 약 0.5 | 0.4초 | [ToxicGas#use], [Speck#toxic], [Speck#gasUpdate] |
| Freezing | `SnowParticle` | 0.05초 | [Freezing#use] |
| Electricity | `SparkParticle` | 0.05초 | [Electricity#use] |

가스 여러 종이 증기 조각 하나를 공유하고 hardlight 색만 바꾼다([Speck#film] 133~145행). 스프라이트 한 장을 코드로 색칠하는 절충이다.

---

## 3. 코드로 그려도 조잡해 보이지 않게 하는 공통 기법

| # | 기법 | Mindustry 근거 | SPD 근거 | 우리 현재와 차이(추론) |
|---|---|---|---|---|
| 1 | **굵기와 크기를 시간 곡선으로 함께 줄인다.** 굵기 `k·fout`, 반경 `a + b·finpow`. 끝까지 남는 일정한 1~2px 선은 없다 | [Fx#healWave], [Scaled] | `Shrinking` [PixelParticle#shrinking], Beam `scale.y = p` [Beam] | 우리는 굵기를 고정하고 알파만 줄인다 |
| 2 | **짧은 충격과 긴 잔해를 나눈다.** 6~7 tick 고리를 22~30 tick 이펙트 안에 넣는다 | `e.scaled(6, …)` [Fx#blast], [Effect#scaled] | 폭탄 = 중심 불 버스트 + 칸 연기 [Bomb#explode] | |
| 3 | **겹을 3~4개 쌓고 겹마다 역할을 다르게 준다.** 고리(범위), 연기(무게), 불티(속도), 빛(열) | [Fx#blast], [Fx#greenBomb] | | 우리는 한 색 한 겹이다 |
| 4 | **팔레트를 짝으로 쓴다.** front(밝음)/back(진함) 짝, white→accent 보간, 끝은 gray로 보낸다. 순수 RGB는 쓰지 않는다 | [Pal] 31~32, 38~39, 46~47행, [Fx#explosion] | 파티클마다 1색. 2색이면 보간 [PoisonParticle], [ShadowParticle] | 우리 상태 고리는 순수 RGB |
| 5 | **흰 심을 둔다.** 색 바깥 + 흰 안쪽 | 레이저 3색의 마지막이 white [Laser#colors], greenBomb 흰 십자, ChargeBegin 흰 원 | 광선 띠 중앙이 흰색(`effects.png`) | |
| 6 | **빛은 이펙트 층에만 준다.** bloom이나 가산 블렌딩. 겹치면 저절로 하얘진다 | [Renderer#bloom], [Drawf#light] | [Blending#light], 불·불꽃·폭발·에너지 `lightMode = true` | |
| 7 | **표시물에는 외곽선을 깐다.** 3px 짙은 회색 위에 1px 색 | [Drawf#circles], [Drawf#target], [Drawf#dashCircle] | 타깃 칸은 아이콘 스프라이트 [TargetedCell] | 우리 고리는 배경 위에 그대로 그린다 |
| 8 | **큰 도형 하나보다 작은 조각 여러 개를 쓴다.** 폭발·피격 하나에 2~12개 | `randLenVectors(id, 5, …)` [Fx#hitBulletSmall] | 30개 버스트 [Bomb#explode] | |
| 9 | **불티는 방사선으로 그린다.** 중심에서 바깥 방향으로 눕힌 짧은 선이고 길이는 `fout`으로 준다. 속도감이 생긴다 | `lineAngle(…, Mathf.angle(x, y), 3·fout + 1)` [Fx#hitBulletSmall] | | |
| 10 | **원 말고 정사각형·마름모를 쓴다.** 상태마다 모양을 다르게 준다 | `Fill.square(…, 45)` [Fx#sapped] | 파티클이 모두 정사각형 [PseudoPixel] | |
| 11 | **시드로 정한 무작위를 쓴다.** 저장 없이 매 프레임 같은 모양이 나오고, `id + 1`로 두 번째 묶음을 얻는다 | [Angles#randLenVectors], [Fx#chainLightning] `rand.setSeed(e.id)` | (SPD는 물리 파티클) | Godot `_draw()`에선 이펙트 id로 `RandomNumberGenerator.seed`를 맞추면 같은 효과를 낸다(추론) |
| 12 | **흔들림은 의도해서 고른다.** Mindustry 번개는 고정 시드로 모양이 안정적이고, SPD 번개는 매 프레임 다시 뽑아 지글거린다 | [Fx#chainLightning] | [SPD-Lightning] 150행 | |
| 13 | **모이는 파티클은 예고, 퍼지는 파티클은 발동이다.** 거리에 `fout`을 곱하면 안으로 모인다 | [Fx#lancerCharge], [Fx#greenLaserCharge] | Goo 예고 → 발동 버스트 [Goo#pumpUp] | |
| 14 | **수명 곡선으로 성격을 준다.** `fslope`(톡 나타났다 사라짐), `clamp(fin/0.1)·clamp(fout/0.1)`(장판용으로 앞뒤만 페이드) | [Fx#sapped], [Fx#smokeAoeCloud] | Flare 25% 지점 정점 [Flare] | |
| 15 | **장판은 칸 파티클이나 불투명 덩어리로 그린다.** 가장자리가 불규칙하고 움직인다 | [Liquid#drawPuddle] | [BlobEmitter#emit] | 우리는 반투명 원판이다 |
| 16 | **상태는 파티클과 틴트로 나눈다.** 고리를 겹쳐 쌓지 않는다 | [StatusEffect#update] | [CharSprite#states] | 우리는 RGB 고리 3~4겹 |
| 17 | **피격 강도를 개수로 비례시킨다.** | | `min(9·√(피해/최대HP), 9)` [CharSprite#bloodBurst] | |
| 18 | **도트 정렬**: 저해상도 버퍼 + nearest 확대, 또는 카메라를 화면 픽셀로 반올림 | [Pixelator] | [PixelCamera#align], 버프 덮개 픽셀 반올림 [BuffIndicator] | |

**우리 32색 팔레트에 주의할 점(추론).** 두 게임 모두 색을 연속으로 보간하고 가산 블렌딩을 써서 팔레트 밖의 색을 만든다. 32색을 지키려면 다음 두 가지를 쓰면 된다.

- `lerp` 대신 fin 구간마다 팔레트 색을 계단식으로 바꾼다(예: fin < 0.3 white, < 0.6 accent, 그 뒤 back).
- 가산 블렌딩 대신 흰 심 겹을 따로 그린다.

**크기 환산(추론).** Mindustry 수치는 타일 = 8 기준, SPD는 타일 = 16 기준이다. 우리 유닛 24px를 한 칸으로 보면 Mindustry 수치는 약 ×3, SPD 수치는 ×1.5에 해당한다. 그러면 Mindustry 폭발 고리의 굵기 3은 우리 화면에서 약 9px에서 시작해 0으로 줄어드는 셈이다. 지금 1~2px로 고정된 것과 차이가 크다. 이 배율은 상수 하나로 두면 조정하기 쉽다.

---

## 4. 우리 스킬 유형별 대응 예

각 칸의 "옮길 점"은 내 제안이다(추론). 수치는 원작 단위 그대로 적었다.

| 우리 유형 | Mindustry 예 | SPD 예 | 옮길 점 (추론) |
|---|---|---|---|
| **범위 폭발** | `blastExplosion`: 6 tick 고리 + 회색 연기 5 + back색 불티 4 + 빛 [Fx#blast]. 큰 것은 `dynamicExplosion` [Fx#dynamicExplosion] | 중심 30개 가산 버스트 + 피해 칸마다 연기 4 [Bomb#explode] | 범위 고리는 앞 25%만 굵게(3→0) 보여 주고, 무게감은 연기와 불티로 준다. 범위 경계를 오래 남기지 않는다 |
| **부채꼴** | `shootSmallFlame`: 원 12개를 진행 방향 ±10° 안에 `finpow`로 [Fx#shootSmallFlame]. 베기는 `scatheSlash` 삼각형 2개 [Fx#scatheSlash] | 원뿔 바깥 광선마다 파티클을 뿜는 미사일 [Fireblast#fx], [MagicMissile#cone] | 부채꼴 테두리선 대신 각도 범위 안의 파티클 흐름으로 모양을 드러낸다. `randLenVectors(seed, n, 길이, 각도, 범위)` 형태 |
| **직선** | 레이저: 3색, 굵기 절반씩(7.5/3.75/1.875 × fout), 앞 20%에 길이가 다 뻗고 뾰족한 끝과 총구 날개 [Laser#draw]. 끝점 `hitLaserBlast` [Fx#hitLaserBlast] | 띠 텍스처를 늘리고 두께·알파를 함께 줄임 [Beam] | 선 하나를 색 3겹(바깥 반투명, 중간 색, 흰 심)으로 쪼개고 두께를 fout으로 줄인다. 끝점에 방사 불티를 둔다 |
| **연쇄** | `chainLightning`: 6 unit 간격 꺾임, 3 unit 밀기, 굵기 2.5·fout, white→색 [Fx#chainLightning]. 둥근 이음 `Fx.lightning` [Fx#lightning] | 호마다 2토막, 중간점 ±4 지글거림, 0.3초. 맞은 대상마다 스파크 3개 + 흰 플래시 [SPD-Lightning], [WandOfLightning] 87~89행 | 꺾임 간격을 고정 px로 두고 굵기를 fout으로 준다. 맞은 적마다 짧은 흰 플래시와 스파크를 넣는다 |
| **장판** | 웅덩이: 불투명 원 4개를 시드로 배치하고 출렁임 [Liquid#drawPuddle]. 구름: 원 80개, 앞뒤 10%만 페이드 [Fx#smokeAoeCloud]. 불: 스프라이트 애니메이션 + 깜빡이는 빛 [FireComp#draw] | 칸마다 주기적으로 파티클 [BlobEmitter#emit]. 가스는 7×7 조각에 색 [Speck#toxic] | 반투명 원판 대신 경계 안에 시드로 흩은 작은 덩어리나 파티클을 둔다. 판을 꼭 깔아야 하면 불투명 낮은 명도 + 위성 원으로 가장자리를 깨뜨린다 |
| **버프** | 적용 순간 `heal` 고리 11 tick [Fx#healWave]. 지속 중엔 `overdriven` 정사각형 파티클 [Fx#overdriven]. 몸 힐 플래시 20 tick [UnitComp#healTime] | `Flare` 회전 광선 [Flare], `ShieldHalo` [ShieldHalo], `GlowBlock` 1Hz 틴트 [GlowBlock], 7×7 십자 상승 [Speck#healing] | 적용 순간엔 고리 한 번. 지속 표시는 몸에서 오르는 작은 정사각형이나 틴트 맥동으로 한다. 고리를 계속 띄우지 않는다 |
| **상태이상** | 몸 범위 무작위 지점에서 tick마다 확률 0.09~0.15로 1~3 unit 파티클. 상태마다 모양과 곡선이 다르다 [StatusEffect#update], [Fx#burning]~[Fx#overdriven] | 파티클형(불, 냉기, 표식)과 틴트형(빙결, 암흑, 발광)으로 나눔 [CharSprite#states], [IceBlock] | 3~4겹 RGB 고리를 없앤다. 상태마다 "파티클 하나 또는 틴트 하나"를 배정한다. 정확한 남은 시간은 머리 위 7px 아이콘 같은 UI로 옮긴다 [BuffIndicator] |
| **보스 예고** | 모이는 선 14개 + 커지는 흰 심 원 [Fx#lancerCharge]. 줄어드는 고리와 굵어지는 선 [Fx#greenLaserCharge]. 외곽선 타깃 `Drawf.target`(회전 사각형 + 가시, 3px 회색 밑칠) [Drawf#target] | 위험 칸마다 검은 파티클 분출 → 발동 시 칸마다 버스트 [Goo#pumpUp]. 빨간 타깃 칸, 발동 전까지 알파 0.6 이상 유지 [TargetedCell] | 예고는 모이는 움직임과 외곽선 있는 범위 표시로, 발동은 퍼지는 버스트로 구분한다. 예고는 발동 직전까지 일정 밝기를 유지한다 |

---

## 5. 코드냐 스프라이트냐: 판단 재료

(이 절 전체가 추론이다. 근거 사실은 위 표에 있다.)

- **코드로 해도 되는 것.** 피격 스파크, 폭발 고리, 충격파, 힐 고리, 불티, 연기, 상태 파티클, 충전·예고. Mindustry가 사실상 전부 `Lines`·`Fill`로 처리한다. 조잡함은 코드냐 아니냐보다 1~7번 기법(곡선, 겹, 팔레트 짝, 흰 심, 빛, 외곽선, 조각 수)이 빠진 탓이 크다.
- **스프라이트가 나은 것.** 단면이 있는 광선, 번개 결, 가스 조각, 불꽃 타일, 상태 아이콘. SPD는 이것들을 7×7~16×16 크기의 아주 작은 그림으로 처리하고 움직임과 색은 코드로 준다. Mindustry도 불 타일은 텍스처로 그리고, 텍스처 레이저 헬퍼를 따로 둔다.
- **절충안.** 지금의 `_draw()` 방식을 유지하면서 ① 1~4번 기법으로 순간 이펙트를 다시 쓴다. ② 광선 띠, 번개, 가스 조각만 작은 스프라이트로 만들어 `draw_texture_rect`로 늘이거나 색을 입힌다. 이렇게 하면 두 게임의 실제 구성과 같아진다.

---

## 6. 링크 (커밋 고정)

[Vars#tilesize]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/Vars.java#L135
[DungeonTilemap.SIZE=16]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/tiles/DungeonTilemap.java#L36
[Pal]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/graphics/Pal.java#L31-L82
[Scaled]: https://github.com/Anuken/Arc/blob/7445105cd2683daf5b9ac7033ebb07265d3e814d/arc-core/src/arc/math/Scaled.java#L1-L57
[Angles#randLenVectors]: https://github.com/Anuken/Arc/blob/7445105cd2683daf5b9ac7033ebb07265d3e814d/arc-core/src/arc/math/Angles.java#L109-L156
[Lines#circleVertices]: https://github.com/Anuken/Arc/blob/7445105cd2683daf5b9ac7033ebb07265d3e814d/arc-core/src/arc/graphics/g2d/Lines.java#L17-L26
[Mathf#chanceDelta]: https://github.com/Anuken/Arc/blob/7445105cd2683daf5b9ac7033ebb07265d3e814d/arc-core/src/arc/math/Mathf.java#L236-L238
[Effect#container]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/entities/Effect.java#L291-L329
[Effect#scaled]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/entities/Effect.java#L317-L323
[EffectStateComp]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/entities/comp/EffectStateComp.java#L10-L21
[Renderer#bloom]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/core/Renderer.java#L392-L396
[Settings#bloom]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/ui/dialogs/SettingsMenuDialog.java#L531
[Settings#pixelate]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/ui/dialogs/SettingsMenuDialog.java#L533
[Pixelator]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/graphics/Pixelator.java#L18-L46
[Drawf#light]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/graphics/Drawf.java#L301-L304
[Drawf#target]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/graphics/Drawf.java#L279-L289
[Drawf#dashCircle]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/graphics/Drawf.java#L398-L404
[Drawf#circles]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/graphics/Drawf.java#L410-L416
[Drawf#laser]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/graphics/Drawf.java#L501-L541
[Fx#blast]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L1233-L1255
[Fx#explosion]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L1656-L1675
[Fx#dynamicExplosion]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L1677-L1713
[Fx#shockwave]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L1626-L1648
[Fx#pointShockwave]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L224-L230
[Fx#hitBulletSmall]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L855-L871
[Fx#hitLancer]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L993-L1001
[Fx#hitLaserBlast]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L973-L981
[Fx#healWave]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L812-L822
[Fx#greenBomb]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L756-L773
[Fx#greenLaserCharge]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L775-L791
[Fx#chainLightning]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L2877-L2912
[Fx#lightning]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L189-L206
[Fx#lancerCharge]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L2373-L2390
[Fx#shootSmallFlame]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L2203-L2217
[Fx#scatheSlash]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L731-L736
[Fx#smokeAoeCloud]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L606-L612
[Fx#burning]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L1400-L1406
[Fx#corrosionVapor]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L1500-L1507
[Fx#freezing]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L1543-L1549
[Fx#melting]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L1551-L1557
[Fx#wet]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L1559-L1564
[Fx#sapped]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L1573-L1579
[Fx#electrified]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L1581-L1587
[Fx#overdriven]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/Fx.java#L1603-L1609
[Laser#colors]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/entities/bullet/LaserBulletType.java#L13-L19
[Laser#draw]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/entities/bullet/LaserBulletType.java#L94-L122
[Lightning#create]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/entities/Lightning.java#L42-L99
[Liquid#drawPuddle]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/type/Liquid.java#L124-L149
[FireComp#draw]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/entities/comp/FireComp.java#L103-L115
[StatusEffect#fields]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/type/StatusEffect.java#L42-L57
[StatusEffect#update]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/type/StatusEffect.java#L145-L168
[StatusEffect#draw]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/type/StatusEffect.java#L203-L209
[StatusComp#statusColor]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/entities/comp/StatusComp.java#L115-L130
[StatusComp#draw]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/entities/comp/StatusComp.java#L254-L258
[UnitType#applyColor]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/type/UnitType.java#L1986-L1995
[HealthComp#hitTime]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/entities/comp/HealthComp.java#L9-L26
[UnitComp#healTime]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/entities/comp/UnitComp.java#L750-L753
[SE#burning]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/StatusEffects.java#L20-L34
[SE#freezing]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/StatusEffects.java#L36-L53
[SE#slow]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/StatusEffects.java#L60-L66
[SE#wet]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/StatusEffects.java#L75-L92
[SE#sapped]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/StatusEffects.java#L119-L125
[SE#electrified]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/StatusEffects.java#L127-L133
[SE#overdrive]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/StatusEffects.java#L153-L161
[SE#boss]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/StatusEffects.java#L178-L183
[SE#corroded]: https://github.com/Anuken/Mindustry/blob/b873c01ed559a8803c2dad5c5c79d7ad750d5b95/core/src/mindustry/content/StatusEffects.java#L195-L202

[PseudoPixel]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/SPD-classes/src/main/java/com/watabou/noosa/PseudoPixel.java#L26-L46
[PixelParticle]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/SPD-classes/src/main/java/com/watabou/noosa/particles/PixelParticle.java
[PixelParticle#shrinking]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/SPD-classes/src/main/java/com/watabou/noosa/particles/PixelParticle.java#L60-L66
[Emitter#emit]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/SPD-classes/src/main/java/com/watabou/noosa/particles/Emitter.java#L149-L170
[Emitter#light]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/SPD-classes/src/main/java/com/watabou/noosa/particles/Emitter.java#L173-L180
[Blending#light]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/SPD-classes/src/main/java/com/watabou/glwrap/Blending.java#L42-L49
[Visual#tint]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/SPD-classes/src/main/java/com/watabou/noosa/Visual.java#L210-L226
[PixelCamera#align]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/scenes/PixelScene.java#L348-L354
[Effects#get]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/Effects.java
[Speck#film]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/Speck.java#L76-L151
[Speck#healing]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/Speck.java#L165-L168
[Speck#toxic]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/Speck.java#L333-L338
[Speck#gasUpdate]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/Speck.java#L504-L514
[FlameParticle]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/particles/FlameParticle.java#L36-L67
[SparkParticle]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/particles/SparkParticle.java#L64-L107
[BlastParticle]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/particles/BlastParticle.java#L52-L65
[SmokeParticle]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/particles/SmokeParticle.java#L49-L83
[SnowParticle]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/particles/SnowParticle.java#L38-L58
[PoisonParticle]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/particles/PoisonParticle.java#L84-L91
[ShadowParticle]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/particles/ShadowParticle.java#L90-L96
[Splash#factory]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/Splash.java#L124-L135
[SPD-Lightning]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/Lightning.java#L38-L165
[Beam]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/Beam.java#L44-L98
[Flare]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/Flare.java#L54-L168
[Ripple]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/Ripple.java
[TargetedCell]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/TargetedCell.java#L45-L80
[IceBlock]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/IceBlock.java#L44-L62
[DarkBlock]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/DarkBlock.java#L38-L43
[GlowBlock]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/GlowBlock.java#L39-L45
[ShieldHalo]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/ShieldHalo.java#L35-L74
[BlobEmitter#emit]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/BlobEmitter.java#L44-L72
[Fire#use]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/actors/blobs/Fire.java#L117-L120
[ToxicGas#use]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/actors/blobs/ToxicGas.java#L59-L63
[Freezing#use]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/actors/blobs/Freezing.java#L97-L100
[Electricity#use]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/actors/blobs/Electricity.java#L119-L122
[MagicMissile#cone]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/effects/MagicMissile.java#L212-L271
[Fireblast#fx]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/items/wands/WandOfFireblast.java#L215-L248
[WandOfLightning]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/items/wands/WandOfLightning.java#L85-L90
[Bomb#explode]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/items/bombs/Bomb.java#L147-L175
[Goo#pumpUp]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/sprites/GooSprite.java#L93-L137
[CharSprite#states]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/sprites/CharSprite.java#L388-L468
[CharSprite#burning]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/sprites/CharSprite.java#L390-L397
[CharSprite#invisible]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/sprites/CharSprite.java#L403-L410
[CharSprite#paralysed]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/sprites/CharSprite.java#L411-L413
[CharSprite#chilled]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/sprites/CharSprite.java#L422-L426
[CharSprite#marked]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/sprites/CharSprite.java#L431-L435
[CharSprite#healing]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/sprites/CharSprite.java#L436-L440
[CharSprite#aura]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/sprites/CharSprite.java#L454-L466
[CharSprite#flash]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/sprites/CharSprite.java#L359-L362
[CharSprite#bloodBurst]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/sprites/CharSprite.java#L347-L353
[BuffIndicator]: https://github.com/00-Evan/shattered-pixel-dungeon/blob/57a4e06a4caf162446d1c28caa7983f0493fecf0/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/ui/BuffIndicator.java#L140-L141

(`BuffIndicator`의 픽셀 반올림 부분은 346~356행이다.)
