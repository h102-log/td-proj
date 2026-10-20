extends CanvasLayer
# 골드·다음 세금(I75)·라운드(I94)·웨이브·단계를 보이고, 놓기 모드·«전투 시작»(I13) 버튼과 라운드를 이기거나 도전이 끝난 뒤의 결과 창(S117)을 둔다.
# 판매 후보가 있으면 그 옆에 판매 버튼을 띄운다(S70, I58). 전투 단계에 생산 시설을 고르면 그 옆에 파는 용병마다 구매 버튼을 띄운다(S81, I61, I71).
# 고른 구조물에 따라 같은 자리에 철거(S74)·이어 짓기·취소(전투 단계)와 완성(준비 단계) 버튼도 띄운다(S83). 대포면 옮기기(S91)도 띄운다.
# 성곽 칸을 고르면 같은 자리에 성문 열기·닫기(S85)와 업그레이드(S86) 버튼을 띄운다. 거점을 고르면 마을 레벨 올리기(S100) 버튼을 띄운다.
# 고른 것 가운데 깎인 것이 있으면 수리(S116, I90), 잔해를 고르면 복구(I89) 버튼도 같은 자리에 띄운다.
# 영입 창(도전 시작 전 S122·라운드 사이 S117)이면 결과 창 안에 영입 칸을 띄운다: 목록 영입·리롤·출전 전환·내보내기(S54, I110),
# 보유 영웅의 레벨·경험치(I117), 라운드 사이의 경험치 이관(S127, I116), 라운드 사이의 의뢰 목록과 수락(S77, I121).
# 준비·전투 단계에는 윗줄 아래에 이번 라운드의 미션과 수락한 의뢰를 보이고, 결과 창에 지난 라운드의 달성·실패를 보인다(I122).
# 결과 창의 버튼만 키보드 포커스를 받는다. 창이 열리면 «1라운드 시작»·«다음 라운드»·«새 도전»에 포커스가 간다(I12, I110)
# 출전 영웅 셋을 한 줄에 이름과 Q·W·E·R 스킬 버튼(좌클릭은 쓰기, 우클릭은 자동 시전, I151)과 쓰러짐(I129), 고른 용병의 이동 방식·홀드 버튼(I139)을 보인다. 눌리지 않는 놓기·공병 지시 버튼에는 이유를 붙인다(I128, I132)
# 위 띠의 조작에는 툴팁을 단다(S187, I162). 테마는 hud_theme.gd

const NAMES := {"wall": "방벽", "tower": "타워", "magic": "마법 타워", "soldier": "용병", "barracks": "병영", "engineer": "공병", "workshop": "작업장", "archer": "궁수", "cannon": "대포", "archery": "사격장", "house": "집", "church": "교회"}
const STATES := {"prep": "준비", "battle": "전투", "hiring": "영입", "cleared": "라운드 사이", "won": "승리", "lost": "패배"}
const HEROES := {"aias": "아이아스(탱커)", "sylvia": "실비아(원거리)", "seraphina": "세라피나(힐러)", "vesper": "베스퍼(디버퍼)", "ignis": "이그니스(마법사)", "chronos": "크로노스(버퍼)"}  # 이름(역할), S97·S157
const GRADES := ["1성", "2성", "3성"]  # S94
const GAPS := {"none": " (공병 없음)", "far": " (닿는 공병 없음)"}  # 공병 지시를 맡을 공병이 없는 이유(I128)
const SKILLS := {  # 영웅마다 Q·W·E·R의 [이름, 요약](S97 표). 툴팁(S187)이 쓴다
	"aias": [["방패 강타", "부채꼴 기절"], ["전장의 포효", "도발·보호막"], ["반격의 태세", "감소 뒤 충격파"], ["절대 방어선", "에너지 성벽"]],
	"sylvia": [["관통의 바람살", "직선 관통"], ["돌풍 갈래살", "토글 4명 사격"], ["폭풍의 덫", "속박·치명타"], ["천공의 화살비", "처형"]],
	"seraphina": [["성스러운 빛줄기", "회복·피해 도약"], ["정화의 성역", "회복 장판"], ["수호 천사의 날개", "불사"], ["기적의 강림", "전체 회복·축복"]],
	"vesper": [["부식의 독안개", "방어력 −10"], ["쇠약의 저주", "둔화·공격력 감소"], ["영혼 사슬", "피해 나누기"], ["심연의 늪", "봉인"]],
	"ignis": [["화염구 작렬", "발화"], ["서리 고리", "열충격 빙결"], ["비전 블랙홀", "끌어당김"], ["메테오 스웜", "운석·용암"]],
	"chronos": [["무기 과충전", "자동 시전"], ["시간 되감기", "마나·대기"], ["황금의 율법", "골드 +30%"], ["시간 왜곡장", "가속·감속"]],
}
const HudTheme := preload("res://src/ui/hud_theme.gd")
const HudTip := preload("res://src/ui/hud_tip.gd")

var battle
var controls
var map: SubViewport  # 맵(전장)을 그리는 SubViewport(S30). 팝업 위치를 그 카메라 변환으로 잡는다
var bar: PanelContainer  # 위 띠
var tip := HudTip.new()  # 위 띠 조작의 툴팁(S187)
var _info := Label.new()
var _hint := Label.new()
var _start: Button
var _popup := HBoxContainer.new()  # 판매·완성·구매·철거·이어 짓기·취소 버튼. 클릭하거나 드래그를 놓은 지점 옆에 뜬다
var _sell: Button
var _finish: Button
var _buy := {}  # 용병 kind → 구매 버튼
var _demolish: Button
var _move: Button
var _resume: Button
var _cancel: Button
var _gate: Button
var _upgrade: Button
var _repair: Button
var _restore: Button
var _village: Button
var _heal := []  # 교회 팝업: 출전 영웅마다 치료 버튼(S137, I140)
var _place := {}  # kind → 버튼
var _result := PanelContainer.new()
var _result_label := Label.new()
var _next: Button  # 결과 창의 «1라운드 시작»·«다음 라운드»·«새 도전»
var _hire := VBoxContainer.new()  # 결과 창 안의 영입 칸
var _hire_info := Label.new()
var _offers := []  # 목록 칸마다 영입 버튼
var _reroll: Button
var _members := []  # 보유 영웅마다 [출전·대기 전환 버튼, 내보내기 버튼, 이관 버튼]
var _giver = null  # 이관(I116)에서 먼저 고른 주는 영웅
var _quest := Label.new()  # 준비·전투 단계의 미션·수락한 의뢰(I122)
var _quests := VBoxContainer.new()  # 라운드 사이 영입 칸 안의 의뢰 목록(I121)
var _quests_info := Label.new()
var _commissions := []  # 의뢰 목록 칸마다 수락 버튼
var _seen := ""  # 마지막으로 본 판 단계. 바뀌었을 때 결과 창이 떠 있으면 포커스를 준다
var _place_text := {}  # kind → 이유를 붙이기 전의 놓기 버튼 글자(I132)
var _mode: Button  # 고른 용병의 이동 방식 전환(I139)
var _hold: Button  # 고른 용병의 홀드 전환(I139)
var _heroes := Label.new()  # 출전 영웅 줄 아래의 안내(«— 스킬은 전투 단계에만», S136)
var _hero_line := HBoxContainer.new()  # 출전 영웅 셋을 한 줄에(I129)
var _hero_rows := []  # 출전 칸마다 [보일 노드들, 이름 글, {칸: 스킬 버튼}](I129, I151)
var _gap := ""  # 고른 것의 칸에 공병 지시를 맡을 공병이 없는 이유(I128). _engineer_gap이 _gap_for 칸에서 _gap_at(ms)에 쟀다
var _gap_for := []
var _gap_at := 0

func _init(b, c, m) -> void:
	battle = b
	controls = c
	map = m

func _ready() -> void:
	var root := Control.new()  # 글자 크기를 한 번에 주는 틀. 클릭은 아래 맵으로 흘린다
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = HudTheme.make(10)
	add_child(root)
	bar = PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)  # 화면 너비에 맞춰 버튼 줄이 줄바꿈된다(S105)
	root.add_child(bar)
	var col := VBoxContainer.new()
	bar.add_child(col)
	var row := HFlowContainer.new()
	col.add_child(row)
	row.add_child(_info)
	var costs: Dictionary = battle.STRUCTURE_KINDS.merged(battle.MERC_KINDS)
	for key in controls.PLACE_KEYS:
		var kind: String = controls.PLACE_KEYS[key]
		var key_name := OS.get_keycode_string(key).replace("Minus", "-").replace("Equal", "=")
		_place[kind] = _button(row, "%s %d (%s)" % [NAMES[kind], costs[kind].cost, key_name], func(): controls.placing = kind)
		_place[kind].toggle_mode = true
		_place_text[kind] = _place[kind].text
		tip.add(_place[kind], func(): return _place_tip(kind, key_name))
	_start = _button(row, "전투 시작 (Enter)", _start_battle)
	_mode = _button(row, "", controls.toggle_move_mode)
	_hold = _button(row, "", controls.toggle_hold)
	tip.add(_start, func(): return ["전투 시작", "Enter", "", "웨이브 %d/%d를 부른다" % [mini(battle.wave_index + 1, battle.waves.size()), battle.waves.size()], "" if battle.state == "prep" else "준비 단계에만"])
	tip.add(_mode, func(): return ["이동 방식", "A", "", "이동 중 공격 ↔ 무조건 이동", ""])
	tip.add(_hold, func(): return ["홀드", "H", "", "켜면 기준 지점 반경 안의 적만 친다", ""])
	col.add_child(_quest)
	_hero_line.add_theme_constant_override("separation", 2)  # 줄 안 2px, 영웅 사이는 빈칸을 더해 6px(640px 안에 든다)
	col.add_child(_hero_line)
	for i in battle.HIRE.lineup:
		var nodes := []
		if i > 0:
			var gap := Control.new()
			gap.custom_minimum_size.x = 2
			_hero_line.add_child(gap)
			nodes.append(gap)
		var who := Label.new()
		_hero_line.add_child(who)
		_fix_width(who, "F3 세라피나")
		nodes.append(who)
		var buttons := {}
		for slot in battle.SLOTS:
			var sb := _button(_hero_line, "", func(): controls.skill_for(battle.heroes[i] if i < battle.heroes.size() else null, slot))
			sb.gui_input.connect(func(e): _auto_click(e, i, slot))
			_fix_width(sb, "W88*")  # 조준 중 «▶»는 넓이에 넣지 않는다. 넣으면 셋이 640px를 넘는다
			buttons[slot] = sb
			tip.add(sb, func(): return _skill_tip(i, slot))
		_hero_rows.append([nodes, who, buttons])
	col.add_child(_heroes)
	col.add_child(_hint)  # 영웅 줄 아래. 조준·놓기 안내가 뜨고 질 때 스킬 버튼이 밀리지 않게
	# 윗변과 너비를 고정해 아래로만 자란다. 영입·리롤·내보내기로 줄이 바뀌어도 위의 버튼이 움직이지 않게(I136)
	_result.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_result.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_result.offset_top = 8
	_result.custom_minimum_size.x = 480
	root.add_child(_result)
	var box := VBoxContainer.new()
	_result.add_child(box)
	for v in [box, _hire, _quests]:  # 줄 사이를 좁혀 가장 긴 라운드 사이 창(보유 4명·결과 2줄·의뢰 2개, 기본 간격이면 370px)도 화면(360px) 안에 든다(I136)
		v.add_theme_constant_override("separation", 2)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_result_label)
	box.add_child(_hire)
	_hire_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hire.add_child(_hire_info)
	for i in battle.HIRE.slots:
		_offers.append(_window_button(_hire, func(): battle.hire(i)))
	_reroll = _window_button(_hire, func(): battle.reroll())
	for i in battle.HIRE.cap:
		var member := HBoxContainer.new()
		_hire.add_child(member)
		var toggle := _window_button(member, func(): battle.set_lineup(battle.roster[i], battle.roster[i] not in battle.lineup))
		toggle.toggle_mode = true
		_members.append([toggle, _window_button(member, func(): battle.dismiss(battle.roster[i])), _window_button(member, func(): _give(battle.roster[i]))])
	_hire.add_child(_quests)
	_quests_info.text = "의뢰 — 다음 라운드에 걸린다. 하나만 수락한다"
	_quests.add_child(_quests_info)
	for i in battle.QUEST_OFFERS:
		_commissions.append(_window_button(_quests, func(): battle.accept(i)))
	_next = _window_button(box, proceed)
	root.add_child(_popup)
	_sell = _button(_popup, "", _sell_now)
	_finish = _button(_popup, "완성", func(): _apply(battle.finish, battle.unfinished(controls.selling)))
	for kind in battle.MERC_KINDS:
		_buy[kind] = _button(_popup, "", func(): battle.recruit(controls.facility, kind))
	_demolish = _button(_popup, "철거", func(): _apply(func(s): battle.demolish([s]), controls.picked))
	_move = _button(_popup, "옮기기", _start_move)
	_resume = _button(_popup, "이어 짓기", func(): _apply(battle.resume, battle.unfinished(controls.picked)))
	_cancel = _button(_popup, "취소", func(): _apply(battle.cancel, battle.unfinished(controls.picked)))
	_gate = _button(_popup, "", func(): battle.set_gate(controls.fort, not controls.fort.open))
	_upgrade = _button(_popup, "", func(): battle.upgrade(controls.fort))
	_repair = _button(_popup, "", func(): _apply(battle.repair, _to_repair()))
	_restore = _button(_popup, "", func(): battle.restore(controls.fort))
	_village = _button(_popup, "", func(): battle.raise_village())
	for i in battle.HIRE.lineup:
		_heal.append(_button(_popup, "", func(): battle.heal(battle.heroes[i])))
	root.add_child(tip)  # 맨 위에 그린다(I162)

func _process(_delta: float) -> void:
	var prep: bool = battle.state == "prep"
	var n: int = battle.waves.size()
	var round_no: int = battle.round_index + 1
	_info.text = "골드 %d (세금 +%d) · 라운드 %d/%d · 웨이브 %d/%d · %s · 마을 Lv%d" % [battle.gold, battle.tax(), round_no, battle.rounds.size(), mini(battle.wave_index + 1, n), n, STATES[battle.state], battle.village_level]
	var none: String = GAPS.get(battle.engineer_gap([]), "") if battle.state == "battle" else ""  # 놓기 버튼은 칸을 모르니 공병이 아예 없을 때만(I128)
	for kind in _place:
		var lock := _place_lock(kind, none) if battle.state in ["prep", "battle"] else ""
		_place[kind].text = _place_text[kind] + lock
		_place[kind].disabled = battle.state not in ["prep", "battle"] or lock != ""
		_place[kind].button_pressed = controls.placing == kind
	_start.disabled = not prep
	var mercs: Array = controls.selected.filter(func(u): return not u.is_hero and u.alive)  # 고른 용병의 이동 방식·홀드(U11, I139)
	_mode.visible = battle.state in ["prep", "battle"] and not mercs.is_empty()
	_hold.visible = _mode.visible
	if _mode.visible:
		var moving: int = mercs.filter(func(u): return u.move_mode == "move").size()
		_mode.text = ("무조건 이동" if moving == mercs.size() else "이동 중 공격" if moving == 0 else "이동 방식 섞임") + " (A)"
		var held: int = mercs.filter(func(u): return u.hold).size()
		_hold.text = ("홀드 켬" if held == mercs.size() else "홀드 끔" if held == 0 else "홀드 섞임") + " (H)"
	_hint.visible = controls.placing != "" or controls.moving != null or controls.aiming != ""
	_hint.text = "%s 놓기: 좌클릭 · 끝내기: 우클릭·ESC" % NAMES.get(controls.placing, "")
	if controls.moving:
		_hint.text = "대포 옮길 칸: 좌클릭 · 끝내기: 우클릭·ESC"
	if controls.aiming != "":  # 조준 중(S147)
		_hint.text = "%s %s 대상: 좌클릭 · 취소: 우클릭·ESC" % [HEROES[controls.aim_hero.kind].get_slice("(", 0), controls.aiming.to_upper()]
	_quest.visible = battle.state in ["prep", "battle"] and (battle.mission != "" or battle.commission != "")
	_quest.text = " · ".join(_quest_lines())
	_show_heroes()
	_result.visible = battle.state in ["hiring", "cleared", "won", "lost"]
	_result_label.text = {"hiring": "도전 시작 — 영웅 영입", "cleared": "%d라운드 승리" % round_no, "won": "도전 성공!", "lost": "%d라운드 패배 — 도전 끝" % round_no}.get(battle.state, "")
	for s in battle.settled:  # 지난 라운드의 미션·의뢰 판정(I120, I122)
		var q: Dictionary = battle.QUEST_KINDS[s[0]]
		_result_label.text += "\n%s «%s» %s" % ["의뢰" if q.commission else "미션", q.text, "달성 +%d골드" % q.reward if s[1] else "실패"]
	_next.text = {"hiring": "1라운드 시작 (Enter)", "cleared": "다음 라운드 (Enter)"}.get(battle.state, "새 도전 (Enter)")
	if battle.state != _seen:
		_seen = battle.state
		_giver = null
		if _result.visible:
			_next.grab_focus()
	_hire.visible = battle.hiring_open()
	if _hire.visible:
		_show_hire()
	if not prep or controls.placing != "":  # 전투가 시작되거나 놓기 모드에 들어가면 판매 팝업을 닫는다(I58)
		controls.selling = []
	_sell.visible = not controls.selling.is_empty()
	_sell.text = "판매 +%d골드" % controls.selling.reduce(func(n, t): return n + battle.refund(t), 0)
	_finish.visible = not battle.unfinished(controls.selling).is_empty()
	if controls.facility and not controls.facility.alive:  # 파괴되거나 팔린 시설
		controls.facility = null
	for kind in _buy:
		_buy[kind].visible = battle.state == "battle" and controls.facility != null and kind in controls.facility.produces
		_buy[kind].text = "%s 구매 %d골드" % [NAMES[kind], battle.MERC_KINDS[kind].cost]
	if battle.state != "battle" or controls.placing != "":
		controls.picked = []
	controls.picked = controls.picked.filter(func(s): return s.alive)  # 부서지거나 허물거나 취소된 것은 뺀다
	var todo: Array = battle.unfinished(controls.picked)
	_demolish.visible = controls.picked.any(battle.can_demolish)
	_move.visible = _cannon() != null
	_resume.visible = todo.any(func(s): return s.worker == null)
	_cancel.visible = not todo.is_empty()
	if controls.placing != "" or (controls.fort and not controls.fort.alive and battle.rubble.get(controls.fort.cell) != controls.fort):  # 놓기 모드거나 판에서 사라진 성곽 칸. 잔해는 남긴다(I89)
		controls.fort = null
	var k = controls.fort
	var live: bool = k != null and k.alive
	# 공병 지시 버튼(철거·옮기기·이어 짓기·업그레이드·수리·복구)은 고른 것의 칸에 맡을 공병이 없으면 끄고 이유를 붙인다(I128)
	var gap: String = GAPS.get(_engineer_gap((controls.picked + ([k] if k else []) + ([battle.base] if controls.village else [])).map(func(t): return t.cell)), "")
	_demolish.text = "철거" + gap
	_move.text = "옮기기" + gap
	_resume.text = "이어 짓기" + gap
	for b in [_demolish, _move, _resume, _upgrade, _repair]:
		b.disabled = gap != ""
	_gate.visible = live and k.kind == "gate" and battle.state in ["prep", "battle"]
	if _gate.visible:  # 쿨타임 중이면 누르지 못하고 남은 초를 올림해 붙인다(I123). 성문 칸에 누가 있어 못 닫으면 «(칸 막힘)»(I124)
		var stuck: bool = k.open and battle.occupied(k.cell)
		_gate.text = ("닫기" if k.open else "열기") + (" (%d초)" % ceili(k.lock) if k.lock > 0.0 else "") + (" (칸 막힘)" if stuck else "")
		_gate.disabled = k.lock > 0.0 or stuck
	# 공병이 올리는 중이면 숨긴다. 그만둔 업그레이드는 «계속»으로 골드 없이 이어 올린다(I68)
	_upgrade.visible = live and battle.state in ["prep", "battle"] and k.level < battle.UPGRADE_MAX and k.worker == null
	if _upgrade.visible:
		_upgrade.text = ("업그레이드 계속" if k.lift >= 0.0 else "업그레이드 %d골드" % battle.upgrade_cost(k)) + gap
	if controls.placing != "":
		controls.village = false
	_village.visible = controls.village and prep and battle.village_level <= battle.VILLAGE_UP.size()
	if _village.visible:  # 그 레벨에 열리는 시설 이름을 붙인다(I132)
		var opens: Array = battle.STRUCTURE_KINDS.keys().filter(func(s): return battle.STRUCTURE_KINDS[s].village_level == battle.village_level + 1).map(func(s): return NAMES[s])
		_village.text = "마을 레벨 %d로 올리기 %d골드" % [battle.village_level + 1, battle.VILLAGE_UP[battle.village_level - 1]] + ("" if opens.is_empty() else " — " + ", ".join(opens))
	var fix := _to_repair()
	_repair.visible = not fix.is_empty()
	if _repair.visible:
		_repair.text = "수리 %d골드" % fix.reduce(func(n, t): return n + battle.repair_cost(t), 0) + gap
	_restore.visible = k != null and battle.rubble.get(k.cell) == k and k.worker == null and battle.state in ["prep", "battle"]
	if _restore.visible:  # 잔해 칸에 누가 있으면 복구하지 못한다(I124)
		var blocked: bool = battle.occupied(k.cell)
		_restore.text = "복구 %d골드" % battle.repair_cost(k) + (" (칸 막힘)" if blocked else "") + gap
		_restore.disabled = blocked or gap != ""
	# 고른 교회의 치료 버튼(S137): 살아 있고 깎인 출전 영웅마다. 전투 단계에는 끄고 이유를 붙인다(I140)
	var church: bool = (controls.selling + controls.picked).any(func(s): return s.kind == "church")
	for i in _heal.size():
		var h = battle.heroes[i] if i < battle.heroes.size() else null
		_heal[i].visible = church and h != null and h.alive and h.hp < h.max_hp
		if _heal[i].visible:
			_heal[i].text = "%s 치료 %d골드" % [HEROES[h.kind].get_slice("(", 0), battle.heal_cost(h)] + ("" if prep else " (준비 단계에만)")
			_heal[i].disabled = not prep
	_popup.reset_size()
	# 맵 px → 화면 좌표. 전투 화면(BattleView)이 맵 SubViewport 원점에 있고, SubViewport는 HUD와 같은 기준 해상도 좌표라 그 카메라 변환만 곱한다. 화면 밖으로 나가면 안으로 당긴다(I137)
	var at: Vector2 = map.get_canvas_transform() * controls.sell_at + Vector2(6, 6)
	_popup.position = at.clamp(Vector2.ZERO, get_viewport().get_visible_rect().size - _popup.size)

# 가장 긴 글자(sample)가 들어가는 너비로 고정한다. 마나 숫자·칸 상태 글자가 바뀌어도 뒤 버튼이 옆으로 움직이지 않게(I151)
func _fix_width(c, sample: String) -> void:  # c: Label·Button
	var text: String = c.text
	c.text = sample
	c.custom_minimum_size.x = c.get_minimum_size().x
	c.text = text

# 키보드 포커스를 받지 않는다. 받으면 Enter·Space가 맵 대신 마지막에 누른 버튼을 누른다
func _button(parent: Control, text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b

func _start_battle() -> void:
	controls.placing = ""
	battle.start_battle()

# 결과 창의 버튼(S117): 영입 창이면 1라운드나 다음 라운드로, 도전이 끝났으면 새 도전을 시작한다. main이 Enter로도 부른다(I94)
func proceed() -> void:
	if battle.hiring_open():
		battle.next_round()
	elif battle.state in ["won", "lost"]:
		_restart()

# 결과 창 안의 버튼. 키보드 포커스를 받아 방향키로 옮기고 Enter로 누른다(I12, I110)
func _window_button(parent: Control, on_press: Callable) -> Button:
	var b := _button(parent, "", on_press)
	b.focus_mode = Control.FOCUS_ALL
	b.gui_input.connect(_refocus)
	return b

# 창 버튼을 마우스로 누른 뒤 포커스를 진행 버튼에 돌려준다. 안 그러면 Enter가 방금 누른 리롤·내보내기를 다시 누른다(I110)
func _refocus(e: InputEvent) -> void:
	if e is InputEventMouseButton and not e.pressed:
		_next.grab_focus.call_deferred()

# 영입 칸(I110): 골드·보유·출전 수, 목록 칸마다 영웅 이름(역할)·등급·영입 비용, 리롤, 보유 영웅마다 출전·대기와 내보내기
func _show_hire() -> void:
	var hire = battle.HIRE
	_hire_info.text = "골드 %d · 보유 %d/%d · 출전 %d/%d" % [battle.gold, battle.roster.size(), hire.cap, battle.lineup.size(), hire.lineup]
	for i in _offers.size():
		var k: String = battle.offers[i]
		if k == "":
			_offers[i].text = "(영입함)"
			_offers[i].disabled = true
			continue
		var grade: int = battle.HERO_KINDS[k].grade
		_offers[i].text = "%s «%s» · %s · 영입 %d골드" % [HEROES[k], battle.HERO_KINDS[k].title, GRADES[grade - 1], hire.cost[grade - 1]]  # 이명(S157)
		_offers[i].disabled = battle.gold < hire.cost[grade - 1] or battle.roster.size() >= hire.cap
	_reroll.text = "리롤 %d골드" % hire.reroll
	_reroll.disabled = battle.gold < hire.reroll or battle.roster.size() >= hire.cap  # 상한이면 리롤해도 영입하지 못한다(I127)
	for i in _members.size():
		var here: bool = i < battle.roster.size()
		_members[i][0].get_parent().visible = here  # 줄째 숨긴다. 버튼만 숨기면 빈 줄이 창에 틈을 남긴다
		if here:
			var h = battle.roster[i]
			var out: bool = h in battle.lineup
			_members[i][0].text = "%s · %s · %s · %s" % [HEROES[h.kind], GRADES[h.grade - 1], _level(h), "출전" if out else "대기"]
			_members[i][0].button_pressed = out
			_members[i][0].disabled = not out and battle.lineup.size() >= hire.lineup
			_members[i][1].text = "내보내기"
			_members[i][2].visible = battle.state == "cleared"  # 이관은 라운드 사이에만(S127)
			_members[i][2].text = "이관" if _giver == null else ("취소" if _giver == h else "여기로")
			_members[i][2].disabled = (_giver == null and h.xp == 0) or (_giver not in [null, h] and not battle.can_transfer(_giver, h))  # 넘치는 이관은 «여기로»를 끈다(I116)
	_quests.visible = battle.state == "cleared" and not battle.commission_offers.is_empty()  # 의뢰는 라운드 사이에만(I121)
	for i in _commissions.size():
		var here: bool = i < battle.commission_offers.size()
		_commissions[i].visible = here
		if here:
			var q: Dictionary = battle.QUEST_KINDS[battle.commission_offers[i]]
			var on: bool = battle.commission == battle.commission_offers[i]
			_commissions[i].text = "%s · +%d골드 · %s" % [q.text, q.reward, "수락함 (다시 누르면 무름)" if on else "수락"]

# 미션·수락한 의뢰 줄(I122): «미션: 조건 (+N골드)»와 «의뢰: 조건 (+N골드)». 조건이 깨졌으면 «— 실패»를 붙인다(I131)
func _quest_lines() -> Array:
	var out := []
	for pair in [["미션", battle.mission], ["의뢰", battle.commission]]:
		if pair[1] != "":
			var q: Dictionary = battle.QUEST_KINDS[pair[1]]
			out.append("%s: %s (+%d골드)" % [pair[0], q.text, q.reward] + ("" if battle.quest_met(pair[1]) else " — 실패"))
	return out

# 출전 영웅 줄(I129, I151): 셋을 한 줄에 «F1 아이아스» 뒤 스킬 버튼 넷. 쓰러졌으면 버튼 없이 «F1 아이아스 쓰러짐».
# 전투 단계가 아니면 아래에 «— 스킬은 전투 단계에만»(S136)
func _show_heroes() -> void:
	var on: bool = battle.state in ["prep", "battle"]
	_hero_line.visible = on and not battle.heroes.is_empty()
	for i in _hero_rows.size():
		var row: Array = _hero_rows[i]
		var h = battle.heroes[i] if on and i < battle.heroes.size() else null
		for n in row[0]:
			n.visible = h != null
		for slot in battle.SLOTS:
			row[2][slot].visible = h != null and h.alive
		if h == null:
			continue
		row[1].text = "F%d %s%s" % [i + 1, HEROES[h.kind].get_slice("(", 0), "" if h.alive else " 쓰러짐"]
		for slot in battle.SLOTS:
			var st: Array = _slot_state(h, slot)
			row[2][slot].text = st[0]
			row[2][slot].modulate.a = 0.4 if st[1] else 1.0
	_heroes.visible = on and not battle.heroes.is_empty() and battle.state != "battle"
	_heroes.text = "— 스킬은 전투 단계에만"

# 스킬 버튼 우클릭: 그 칸의 자동 시전을 켜고 끈다(S158, I151)
func _auto_click(e: InputEvent, i: int, slot: String) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT and e.pressed and i < battle.heroes.size():
		battle.toggle_auto(battle.heroes[i], slot)

# 칸 하나의 버튼 글과 흐리게 할지(I129): 칸 글자에 조준 중 «▶», 켜진 토글 «+», 재사용 대기(올림한 초), 자동 시전 «*»를 붙인다.
# 열리기 전이거나 마나가 모자라면 흐리게
func _slot_state(h, slot: String) -> Array:
	var sk: Dictionary = h.get(slot)
	var key := slot.to_upper()
	if h.level < battle.LEVELS.unlock[slot]:
		return [key, true]
	var text := key
	if controls.aiming == slot and controls.aim_hero == h:
		text = "▶" + key
	elif h.toggle and sk.aim == "toggle":
		text = key + "+"
	elif h.cd[slot] > 0.0:
		text = key + str(ceili(h.cd[slot]))
	return [text + ("*" if h.auto and sk.get("auto", false) else ""), h.mana < sk.mana]

# 놓기 버튼이 눌리지 않는 이유(I132): 마을 레벨(S99), 전투 단계의 공병(none, I128)·용병(S81), 준비 단계의 시설(S50). 눌리면 ""
func _place_lock(kind: String, none: String) -> String:
	if kind in battle.STRUCTURE_KINDS:
		var need: int = battle.STRUCTURE_KINDS[kind].village_level
		return " (마을 Lv%d)" % need if need > battle.village_level else none
	if battle.state == "battle":
		return " (시설에서 구매)"
	if battle.can_buy(kind):
		return ""
	for s in battle.STRUCTURE_KINDS:  # 그 용병을 파는 시설
		if kind in battle.STRUCTURE_KINDS[s].produces:
			return " (%s 없음)" % NAMES[s]
	return ""

# 놓기 버튼 툴팁(S187): 이름·키·비용, 데이터로 만든 한 줄 설명, 이유는 _process가 버튼 글에 붙인 것을 괄호 없이(I132). 이유가 없고 골드가 모자라면 그것
func _place_tip(kind: String, key: String) -> Array:
	var d = battle.STRUCTURE_KINDS.get(kind, battle.MERC_KINDS.get(kind))
	var why: String = _place[kind].text.trim_prefix(_place_text[kind]).strip_edges().trim_prefix("(").trim_suffix(")")
	if why.begins_with("마을 Lv"):
		why += " 필요"
	if why == "" and battle.gold < d.cost:
		why = "골드 %d 모자람" % (d.cost - battle.gold)
	var about := "체력 %d · 적의 길을 막는다" % d.hp
	if kind in battle.MERC_KINDS:
		for s in battle.STRUCTURE_KINDS:
			if kind in battle.STRUCTURE_KINDS[s].produces:
				about = "%s에서 산다 · 체력 %d" % [NAMES[s], d.hp]
	elif not d.produces.is_empty():
		about = "마을 · %s를 판다" % ", ".join(d.produces.map(func(k): return NAMES[k]))
	elif d.tax > 0:
		about = "마을 · 준비 단계마다 세금 +%d" % d.tax
	elif d.heal > 0.0:
		about = "마을 · 영웅 체력을 골드로 치료"
	elif d.range > 0.0:
		about = "사거리 %s칸 · 공격력 %s" % [_num(d.range), _num(d.damage)] + (" · 범위 피해" if d.splash > 0.0 else "")
	return [NAMES[kind], key, "%d골드" % d.cost, about, why]

# 4.0 → «4», 1.5 → «1.5»
func _num(x: float) -> String:
	return str(int(x)) if x == roundf(x) else str(x)

# 스킬 버튼 툴팁(S187): 이름·키·마나, 요약·재사용 대기 초·자동 시전, 못 쓰는 이유 하나(S145 해금 > S136 단계 > 마나 > 대기)
func _skill_tip(i: int, slot: String) -> Array:
	var h = battle.heroes[i]
	var sk: Dictionary = h.get(slot)
	var name_about: Array = SKILLS[h.kind][battle.SLOTS.find(slot)]
	var why := ""
	if h.level < battle.LEVELS.unlock[slot]:
		why = "Lv%d에 열림" % battle.LEVELS.unlock[slot]
	elif battle.state != "battle":
		why = "스킬은 전투 단계에만"
	elif h.mana < sk.mana:
		why = "마나 %d 모자람" % ceili(sk.mana - h.mana)
	elif h.cd[slot] > 0.0:
		why = "재사용 대기 %d초" % ceili(h.cd[slot])
	var about := "%s · 재사용 %s초" % [name_about[1], _num(sk.gap)] + (" · 우클릭: 자동 시전" if sk.get("auto", false) else "")
	return [name_about[0], slot.to_upper(), "마나 %d" % sk.mana, about, why]

# 고른 것의 칸에 공병 지시를 맡을 공병이 없는 이유(I128). 전투 단계가 아니거나 고른 것이 없으면 ""
# ponytail: 닿는지 보는 A*가 무거워(성문이 모두 닫히면 1회 7ms) 같은 칸이면 0.3초마다만 다시 잰다. 그사이 바뀐 공병 사정은 늦게 보인다
func _engineer_gap(cells: Array) -> String:
	if battle.state != "battle" or cells.is_empty():
		return ""
	if cells != _gap_for or Time.get_ticks_msec() - _gap_at > 300:
		_gap = battle.engineer_gap(cells)
		_gap_for = cells
		_gap_at = Time.get_ticks_msec()
	return _gap

# 레벨과 경험치(I117): «Lv2 35/50»(다음 레벨의 누적 경험치까지). 최대 레벨이면 «Lv5 최대»
func _level(h) -> String:
	var steps: Array = battle.LEVELS.steps
	if h.level > steps.size():
		return "Lv%d 최대" % h.level
	return "Lv%d %d/%d" % [h.level, h.xp, steps.slice(0, h.level).reduce(func(s, x): return s + x, 0)]

# 이관(S127, I116): 주는 영웅의 «이관»을 누른 뒤 받는 영웅의 «여기로»를 누른다. 주는 영웅을 다시 누르면 그만둔다
func _give(h) -> void:
	if _giver == null:
		_giver = h
	elif _giver == h:
		_giver = null
	else:
		battle.transfer(_giver, h)
		_giver = null

# 고른 유닛·놓기 모드도 비운다. 재시작 뒤의 영웅은 새 객체다. 새 도전도 영입 창에서 시작한다(S122)
func _restart() -> void:
	battle.restart()
	battle.begin_hiring()
	controls.selected = []
	controls.selling = []
	controls.placing = ""
	controls.facility = null
	controls.picked = []
	controls.fort = null
	controls.village = false

# 고른 구조물마다 f를 부르고 팝업을 닫는다
func _apply(f: Callable, things: Array) -> void:
	for t in things:
		f.call(t)
	controls.selling = []
	controls.picked = []

# 고른 것 가운데 고칠 수 있는 것(S116, I90): 판매·철거 후보, 고른 성곽 칸, 고른 거점
func _to_repair() -> Array:
	var all: Array = controls.selling + controls.picked + ([controls.fort] if controls.fort else []) + ([battle.base] if controls.village else [])
	return all.filter(battle.can_repair)

# 고른 구조물 가운데 옮길 수 있는 첫 대포(S44)
func _cannon():
	for s in controls.picked:
		if s.kind == "cannon" and battle.can_demolish(s):
			return s
	return null

func _start_move() -> void:
	controls.moving = _cannon()
	controls.picked = []

# 팔린 용병은 고른 상태에서도 뺀다
func _sell_now() -> void:
	battle.sell(controls.selling)
	controls.selling = []
	controls.selected = controls.selected.filter(func(u): return u.alive)
