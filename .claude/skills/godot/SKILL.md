---
name: godot
description: td-proj에서 Godot 4.7.2를 명령줄로 다루는 법 — 실행 파일 찾기, SceneTree 스크립트(-s) 실행, 새 .gd의 .uid 만들기(--import)와 뒷정리, 테스트 하나만 돌리기, 게임 창 캡처·녹화, 입력 넣기(tools/play 하네스), 바꾸기 전후 재생 비교. Godot을 띄우거나, GDScript를 실행하거나, 화면을 찍어 확인하거나, .gd 파일을 새로 만들 때 먼저 읽는다.
---

# Godot (td-proj)

명령은 Git Bash에서 저장소 루트(`--path .`) 기준이다. 2026-10-20에 모두 돌려 확인했다.

## 실행 파일

PATH에 `godot`이 없다. winget에 설치된 콘솔판을 쓴다(테스트 conftest와 같은 탐색).

```bash
G="${GODOT:-$(ls -d "$LOCALAPPDATA"/Microsoft/WinGet/Packages/GodotEngine.*/Godot_v4*_console.exe | tail -1)}"
"$G" --version   # 4.7.2.stable.official.ed1daf0bf
```

- 셸 변수는 Bash 툴 호출 사이에 남지 않는다. 호출마다 첫 줄을 다시 붙인다.
- pytest는 `GODOT` → PATH → winget 순서로 스스로 찾는다. `tools/balance/sweep.py`는 winget을 찾지 않으니 `GODOT="$G"`를 넣어 부른다.
- 클라우드(Linux) 세션은 스크래치패드에서 받는다. 받은 뒤 `--import`를 먼저 한 번 돌린다.
  ```bash
  curl -sSL -o godot.zip https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
  ```
  압축을 풀고, 풀린 `Godot_v4.7.2-stable_linux.x86_64`의 절대 경로를 `GODOT`에 넣는다.

## 스크립트 실행

```bash
"$G" --headless --path . -s res://tools/x.gd -- 인자...
timeout 60 "$G" --headless --path . -s "<스크래치패드 절대 경로>/x.gd" -- 인자...
```

- 일회성 측정·캡처 스크립트는 스크래치패드에 두고 저장소에 넣지 않는다. 절대 경로를 `-s`로 넘겨도 `res://`는 저장소다.
- 스크립트는 `extends SceneTree`로 쓴다. 시작은 `_initialize()`, 인자는 `OS.get_cmdline_user_args()`(`--` 뒤), 끝은 `quit(코드)`다.
- **런타임 오류가 나면 프로세스가 끝나지 않는다.** 그 함수만 멈추고 `quit()`에 닿지 못해 창도 프로세스도 남는다. 그래서 일회성 스크립트는 `timeout`으로 감싼다.
- `--headless`면 그림이 없다. 캡처할 때는 빼고 띄운다(창 1280×720).
- `load("res://src/main.tscn").instantiate()`를 `root.add_child`해도 `_ready`는 바로 돌지 않는다. `_process`에서 `main.is_node_ready()`를 확인한 뒤 손댄다. 그 전에 `set_process(false)`를 하면 READY 알림이 도로 켠다.
- `add_child`로 붙인 씬은 `current_scene`이 null이다. 진입 씬으로 띄우면 `current_scene`이 자기 자신이다.
- `_initialize` 안에서는 root가 아직 트리 밖이라, 붙인 노드의 `_ready`가 돌지 않는다. 평가 러너가 이 상태라서 평가 코드는 static 함수를 직접 부른다.
- `-s`로 띄운 것은 편집기 빌드다(feature `editor`). export 템플릿이 없어서, 내보낸 빌드에서만 생기는 동작은 확인할 수 없다.

## .uid와 --import

새 `.gd`를 만들면 `.gd.uid`를 만들어 함께 커밋한다. 평가 `.gd`는 eval 락 **전에** 만든다(락 뒤에 생기면 잠근 파일 집합이 바뀐다).

```bash
"$G" --headless --path . --import       # 약 13초
git ls-files --others --exclude-standard -z -- '*.import' | xargs -0 rm -f
git status --short -- '*.import'
```

- 둘째 줄: art/ PNG마다 미추적 `.import`가 생기므로 지운다(2026-10-20에 437개).
- 셋째 줄: 추적 중인 `.import`(Galmuri7·heroes)가 `M`으로 뜨면 `git diff`가 비었는지 보고 `git checkout --`로 되돌린다. 줄 끝만 바뀐 것이다.
- 내가 만들지 않은 `.gd.uid`가 새로 생기면 지운다. 미추적 `.gd`에 붙어 생긴 것이다.

## 테스트

- 전체: 루트에서 `pytest`(PATH의 python 3.12)를 돌린다. 유닛(`tests/unit/gd/test_*.gd`)과 평가가 함께 돈다.
- 유닛 하나: `"$G" --headless --path . -s res://tests/unit/gd/runner.gd -- res://tests/unit/gd/test_x.gd` → `ALL PASS`
- 평가 하나: `"$G" --headless --path . -s res://tests/eval/gd/runner.gd -- <스위트> EV147` → `PASS EV147`. 끝에 나오는 «ObjectDB instances were leaked» 경고는 늘 나온다.

## 화면 찍기

화면 크기: 기준 해상도 640×360을 창 1280×720(2배)에 그린다(`canvas_items`, 정수배).

| 무엇을 | 방법 | 크기 |
|---|---|---|
| 게임 화면 한 장 | `await RenderingServer.frame_post_draw` 뒤 `root.get_texture().get_image().save_png(p)` | 1280×720 |
| 연속 프레임(GIF·mp4 재료) | `"$G" --path . --write-movie <폴더>/f.png --fixed-fps 30 --quit-after N` | 1280×720, `f00000000.png`…와 `f.wav` |
| 창 테두리·검은 띠까지 | `DisplayServer.screen_get_image(scr).get_region(창 영역)` | 주 모니터 3840×2160 |
| 모니터에 실제로 보이는 픽셀 | `powershell -NoProfile -ExecutionPolicy Bypass -File .claude/skills/godot/grab.ps1 -Out <png> [-X -Y -W -H]` | 물리 픽셀, 범위를 안 주면 두 모니터 전체(5760×2160) |

- 여러 장은 `Image.blit_rect`로 한 장에 잇는다.
- 창 영역은 `window_get_position() - screen_get_position(scr)`과 `window_get_size()`다.
- 화면 캡처(셋째·넷째 줄)는 그리기보다 늦게 찍힌다. 입력하고 0.5초쯤 기다린다.
- 화면 캡처에는 오른쪽 아래 OS 알림도 찍힌다. 저장소에 넣을 그림은 그 자리를 가린다.
- Godot은 주 모니터 배율(150%) 하나로 DPI를 다룬다. 그래서 보조 모니터 좌표가 가상값이고, 보조 모니터 전체화면은 번진다. 실제로 어떻게 보이는지는 `grab.ps1`로만 보인다. 이 스크립트는 Per-Monitor DPI 인식을 켜고 `CopyFromScreen`으로 찍는다.

## 입력 넣기

보통은 `tools/play` 하네스로 넣는다. 입력이 사람과 같은 길(GUI → main → controls)로 들어가고, 판 시간은 `wait`에서만 흐른다.

```bash
P=<스크래치패드>/play; mkdir -p "$P"     # 실행마다 새 폴더
("$G" --path . -s res://tools/play/play.gd -- "$P" 7 > "$P/godot.log" 2>&1 &)
python tools/play/send.py "$P" "key Enter" "click 300 200" "wait 3"
cat "$P/state.json"
python tools/play/send.py "$P" quit
```

- 둘째 줄의 `7`은 씨앗이다. 영입 목록·미션이 고정된다.
- `send.py`는 캡처 PNG 경로와 못 알아들은 명령을 출력한다.
- 명령 목록은 `play.gd` 머리 주석에 있다.
- 좌표는 640×360 기준이다. 캡처는 1280×720이니 캡처에서 잰 좌표는 반으로 줄인다.
- `log.txt`가 그 판의 명령 기록이다.

직접 스크립트로 넣을 때:
- `root.push_input(e, true)`로 넣는다. `true`는 좌표가 이미 640×360 기준이라는 뜻이다.
- 키는 `keycode`와 `physical_keycode`를 둘 다 넣는다. 그래야 `ui_accept`가 어느 쪽으로 묶여 있어도 맞는다.
- 실시간 진행은 `main.set_process(false)`로 끄고 `battle.step(dt)`로 직접 돌린다.
- 카메라도 `set_process(false)`로 끈다. 실제 마우스 위치를 따라가는 가장자리 스크롤이 꺼진다.
- Controls는 `handle()`에서만 판 단계 변화를 본다. `controls.placing` 같은 모드 값을 직접 넣으면 다음 입력에서 꺼지니, 모드는 키 입력으로 들어간다.
- 위쪽 HUD 띠가 맵 윗줄을 가린다. 가려진 칸을 누르면 HUD가 클릭을 먹으니, 누를 칸은 캡처로 먼저 확인한다.
- `warp_mouse`는 실제 커서를 옮긴다. 쓰기 전에 사용자에게 알린다.

## 바꾸기 전후 비교

뷰포트·카메라·GUI 구조처럼 입력이 지나는 길을 바꿨다면, 같은 판을 옛 코드와 새 코드에 재생해 상태를 비교한다. 단위 시험이 못 잡은 회귀가 여기서 잡힌다(2026-10-19 Enter 포커스 회귀).

```bash
O=<스크래치패드>/old; mkdir -p "$O" && git archive HEAD | tar -x -C "$O" && cp -r .godot "$O/"
```

1. 두 쪽(`--path "$O"`와 `--path .`)에 같은 씨앗으로 `play.gd`를 띄운다.
2. 한 판의 `log.txt` 명령을 같은 묶음으로 나눠 양쪽 `send.py`에 보낸다.
3. 캡처마다 `state.json`을 비교한다. 처음 갈리는 명령이 회귀 지점이다.

## 다른 도구

사용법은 각 파일 머리 주석에 있다.
- `tools/balance/autoplay.gd`·`sweep.py`: 봇 밸런스 측정(headless). sweep이 도는 동안에는 평가 final을 돌리지 않고 `autoplay.gd`도 고치지 않는다.
- `tools/bench/*.gd`: 렌더 측정과 장면 캡처(4.1a).
