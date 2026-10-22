extends RefCounted
## One native manuscript folio for the persistent hero, equipment and attributes.
## All mutations return to the shell and authoritative rule modules.

const Realm = preload("res://game/redesign/realm_rules.gd")
const Items = preload("res://game/redesign/item_rules.gd")
const Sheet = preload("res://game/redesign/character_sheet_rules.gd")
const UI = preload("res://game/redesign/manuscript_theme.gd")
const Art = preload("res://game/redesign/manuscript_art.gd")
const HeroPreview = preload("res://game/redesign/hero_preview.gd")
const Identity = preload("res://game/redesign/hero_identity.gd")
const Action = preload("res://game/redesign/action_rules.gd")
const EMBLEMS: Dictionary = {"might":"sword","finesse":"boots","vitality":"roots","spirit":"ward"}

static func build(app: Variant, content: VBoxContainer, selected: String, page: String) -> void:
	var hero: Dictionary = app.realm.hero
	var progression: Dictionary = Realm.progression_view(app.realm)
	var derived: Dictionary = Items.derive_stats(hero)
	if not app.action_state.is_empty():
		var actor: Dictionary=Action.get_actor(app.action_state,str(app.action_state.heroId))
		derived.hp=int(actor.hp)
		derived.mana=int(actor.mana)
	var item: Dictionary = Items.find_instance(hero,selected)
	if item.is_empty() and not hero.inventory.is_empty():
		selected=str(hero.inventory[0].instanceId)
	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.add_theme_constant_override("separation",6)
	content.add_child(tabs)
	for entry: Array in [["character","CHARACTER · C"],["equipment","EQUIPMENT · I"],["traits","CLASS & TRAITS"],["sets","COLLECTIONS"]]:
		var id: String=str(entry[0])
		var button: Button=app._button(str(entry[1]),func()->void:app._open_inventory(selected,id),tabs,32)
		button.name="FolioTab_"+id
		if page==id:
			button.add_theme_stylebox_override("normal",UI.tile(true))
			button.add_theme_color_override("font_color",UI.OXBLOOD)
	var experience_row: HBoxContainer=HBoxContainer.new()
	content.add_child(experience_row)
	var identity: Label=app._body("%s · LEVEL %d" % [Identity.identity_line(hero).to_upper(),int(progression.level)],15,UI.OXBLOOD)
	experience_row.add_child(identity)
	var xp_text: String="LEVEL CAP · %d EXPERIENCE" % int(progression.xp) if bool(progression.atCap) else "%d / %d XP  ·  %d TO LEVEL %d" % [int(progression.xpIntoLevel),int(progression.levelSpanXp),int(progression.xpToNextLevel),int(progression.level)+1]
	var experience: Label=app._body(xp_text,14,UI.MUTED)
	experience.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	experience_row.add_child(experience)
	var xp_bar: ProgressBar=app._bar(content,Color("637044"))
	xp_bar.name="HeroExperience"
	xp_bar.custom_minimum_size.y=7
	xp_bar.max_value=maxi(1,int(progression.levelSpanXp))
	xp_bar.value=xp_bar.max_value if bool(progression.atCap) else int(progression.xpIntoLevel)
	xp_bar.tooltip_text="Experience is earned through completed expeditions. Each level grants three attribute points."
	var row: HBoxContainer=HBoxContainer.new()
	row.add_theme_constant_override("separation",18)
	content.add_child(row)
	var left: VBoxContainer=VBoxContainer.new()
	left.custom_minimum_size.x=326 if app.size.x<1100 else 366
	left.add_theme_constant_override("separation",7)
	row.add_child(left)
	_build_figure(app,left,derived)
	var right: VBoxContainer=VBoxContainer.new()
	right.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",7)
	row.add_child(right)
	match page:
		"character":_build_attributes(app,right,progression,derived,selected)
		"sets":_build_collections(app,right)
		"traits":_build_traits(app,right)
		_:_build_pack(app,right,selected)

static func _build_figure(app: Variant, parent: VBoxContainer, derived: Dictionary) -> void:
	app._section(parent,"YOUR SWORN HERO",16)
	var figure: HBoxContainer=HBoxContainer.new()
	figure.add_theme_constant_override("separation",5)
	parent.add_child(figure)
	var left_slots: VBoxContainer=VBoxContainer.new()
	left_slots.add_theme_constant_override("separation",4)
	figure.add_child(left_slots)
	for slot: String in ["head","chest","hands","legs","feet"]:app._inventory_slot(left_slots,slot)
	var frame: PanelContainer=PanelContainer.new()
	frame.add_theme_stylebox_override("panel",UI.chrome(5))
	frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	figure.add_child(frame)
	var view: SubViewportContainer=SubViewportContainer.new()
	view.name="HeroModelView"
	view.custom_minimum_size=Vector2(156 if app.size.x<1100 else 196,310)
	view.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	view.stretch=true
	view.mouse_filter=Control.MOUSE_FILTER_STOP
	view.tooltip_text="Drag to turn Mara. Scroll to inspect her equipment more closely."
	frame.add_child(view)
	var viewport: SubViewport=SubViewport.new()
	viewport.size=Vector2i(220,310)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d=Viewport.MSAA_2X
	view.add_child(viewport)
	var preview: Node3D=HeroPreview.new()
	preview.name="LiveHeroModel"
	preview.hero=app.realm.hero
	preview.inspect_yaw=app._hero_inspect_yaw
	preview.inspect_zoom=app._hero_inspect_zoom
	viewport.add_child(preview)
	view.gui_input.connect(func(event: InputEvent)->void:
		if event is InputEventMouseMotion and (event.button_mask&MOUSE_BUTTON_MASK_LEFT)!=0:
			preview.rotate_view(event.relative.x*0.012)
			app._hero_inspect_yaw=preview.inspect_yaw
			view.accept_event()
		elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			preview.zoom(-0.12 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 0.12)
			app._hero_inspect_zoom=preview.inspect_zoom
			view.accept_event())
	var right_slots: VBoxContainer=VBoxContainer.new()
	right_slots.add_theme_constant_override("separation",4)
	figure.add_child(right_slots)
	for slot: String in ["cloak","main_hand","off_hand","amulet","ring_1"]:app._inventory_slot(right_slots,slot)
	var controls: HBoxContainer=HBoxContainer.new()
	controls.add_theme_constant_override("separation",5)
	parent.add_child(controls)
	var turn_left: Button=app._button("‹",func()->void:
		preview.rotate_view(-PI/4.0)
		app._hero_inspect_yaw=preview.inspect_yaw,controls,27)
	turn_left.name="HeroRotateLeft"
	turn_left.custom_minimum_size.x=34
	turn_left.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	var reset: Button=app._button("RESET VIEW",func()->void:
		preview.reset_view()
		app._hero_inspect_yaw=preview.inspect_yaw
		app._hero_inspect_zoom=preview.inspect_zoom,controls,27)
	reset.name="HeroResetView"
	var turn_right: Button=app._button("›",func()->void:
		preview.rotate_view(PI/4.0)
		app._hero_inspect_yaw=preview.inspect_yaw,controls,27)
	turn_right.name="HeroRotateRight"
	turn_right.custom_minimum_size.x=34
	turn_right.size_flags_horizontal=Control.SIZE_SHRINK_END
	var bottom: HBoxContainer=HBoxContainer.new()
	parent.add_child(bottom)
	app._inventory_slot(bottom,"ring_2")
	var vitals: VBoxContainer=VBoxContainer.new()
	vitals.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	vitals.add_theme_constant_override("separation",1)
	bottom.add_child(vitals)
	vitals.add_child(app._body("Health  %d / %d" % [derived.hp,derived.maxHp],15,UI.OXBLOOD))
	var health: ProgressBar=app._bar(vitals,Color("8c3d30"))
	health.max_value=derived.maxHp
	health.value=derived.hp
	vitals.add_child(app._body("Focus  %d / %d" % [derived.mana,derived.maxMana],15,UI.SLATE))
	var focus: ProgressBar=app._bar(vitals,Color("477982"))
	focus.max_value=maxi(1,int(derived.maxMana))
	focus.value=derived.mana
	var inspection: Label=app._body("Drag to turn · Scroll to zoom",13,UI.MUTED)
	inspection.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(inspection)

static func _build_attributes(app: Variant, parent: VBoxContainer, progress: Dictionary, derived: Dictionary, selected: String) -> void:
	var preview: Dictionary=Realm.preview_attribute_allocation(app.realm,app._attribute_draft)
	var cost: int=0
	for amount: Variant in app._attribute_draft.values():cost+=int(amount)
	app._section(parent,"ATTRIBUTES · %d POINTS UNSPENT" % int(progress.unspent),16)
	var note: Label=app._body("Three points per level. Raising a maximum does not refill it.",15,UI.MUTED)
	parent.add_child(note)
	for definition: Dictionary in Realm.attribute_catalog():
		var id: String=str(definition.id)
		var draft: int=int(app._attribute_draft.get(id,0))
		var panel: PanelContainer=PanelContainer.new()
		panel.add_theme_stylebox_override("panel",UI.paper(6))
		parent.add_child(panel)
		var line: HBoxContainer=HBoxContainer.new()
		line.add_theme_constant_override("separation",8)
		panel.add_child(line)
		app._art_image(line,Art.symbol(str(EMBLEMS[id])),Vector2(43,46))
		var labels: VBoxContainer=VBoxContainer.new()
		labels.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		labels.add_theme_constant_override("separation",0)
		line.add_child(labels)
		labels.add_child(UI.heading(str(definition.name),18,UI.OXBLOOD))
		var short_effects: Dictionary={"might":"+1 Attack per point","finesse":"+0.04 Movement speed per point","vitality":"+6 maximum Health per point","spirit":"+2 maximum Focus · +1 Ward per point"}
		labels.add_child(app._body(str(short_effects[id]),14,UI.MUTED))
		panel.tooltip_text=str(definition.description)
		var score: Label=UI.heading(str(int(progress.attributes[id])+draft),24,UI.INK if draft==0 else Color("466237"))
		score.name="AttributeValue_"+id
		score.custom_minimum_size.x=38
		score.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		score.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		score.tooltip_text="Base %d + %d allocated%s" % [int(definition.base),int(progress.allocations[id])," + %d planned" % draft if draft>0 else ""]
		line.add_child(score)
		var minus: Button=app._button("−",func()->void:app._draft_attribute(id,-1,selected),line,30)
		minus.name="Undo_"+id
		minus.custom_minimum_size.x=30
		minus.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
		minus.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		minus.disabled=draft<=0
		minus.tooltip_text="Undo one uncommitted point."
		var plus: Button=app._button("+",func()->void:app._draft_attribute(id,1,selected),line,30)
		plus.name="Spend_"+id
		plus.custom_minimum_size.x=30
		plus.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
		plus.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		plus.disabled=not bool(progress.canAllocate) or cost>=int(progress.unspent) or int(progress.allocations[id])+draft>=int(definition.maxInvestment)
		plus.tooltip_text="Plan one point in "+str(definition.name)+". Changes take effect when applied."
	var consequences: Label=app._body("No points planned." if cost==0 else "%d points planned · %d left after applying" % [cost,int(progress.unspent)-cost],15,UI.MUTED)
	consequences.name="AllocationSummary"
	parent.add_child(consequences)
	var after: Dictionary=preview.get("after",derived) if bool(preview.get("ok",false)) else derived
	_stat_grid(app,parent,derived,after)
	var actions: HBoxContainer=HBoxContainer.new()
	actions.add_theme_constant_override("separation",6)
	parent.add_child(actions)
	var apply_button: Button=app._button("APPLY %d POINT%s" % [cost,"" if cost==1 else "S"],func()->void:app._apply_attribute_draft(int(progress.revision),selected),actions,37)
	apply_button.name="ApplyAttributes"
	apply_button.disabled=cost==0 or not bool(preview.get("ok",false))
	var reset_preview: Dictionary=Realm.preview_attribute_reset(app.realm)
	var reset_label: String="RESET · FREE" if int(progress.resetCost)==0 else "RESET · %d GOLD" % int(progress.resetCost)
	var reset_button: Button=app._button(reset_label,func()->void:app._reset_attributes(int(progress.revision),selected),actions,37)
	reset_button.name="ResetAttributes"
	reset_button.disabled=not bool(reset_preview.get("ok",false))
	reset_button.tooltip_text=str(reset_preview.get("message","Return spent attributes at a friendly town. Equipment and current health are preserved."))
	if not bool(progress.canAllocate):parent.add_child(app._body(str(progress.lockReason),14,UI.OXBLOOD))

static func _stat_grid(app: Variant, parent: VBoxContainer, before: Dictionary, after: Dictionary) -> void:
	var grid: GridContainer=GridContainer.new()
	grid.columns=3
	grid.add_theme_constant_override("h_separation",6)
	grid.add_theme_constant_override("v_separation",4)
	parent.add_child(grid)
	for stat: String in Sheet.STAT_ORDER:
		var panel: PanelContainer=PanelContainer.new()
		panel.add_theme_stylebox_override("panel",UI.paper(5))
		panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		grid.add_child(panel)
		var labels: VBoxContainer=VBoxContainer.new()
		labels.add_theme_constant_override("separation",0)
		panel.add_child(labels)
		var heading: Label=app._body(str(Sheet.STAT_LABELS[stat]),13,UI.MUTED)
		heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		labels.add_child(heading)
		var from: float=float(before.get(stat,0.0))
		var to: float=float(after.get(stat,from))
		var text: String=Sheet.format_value(from,stat)
		if not is_equal_approx(from,to):text+=" → "+Sheet.format_value(to,stat)
		var value: Label=UI.heading(text,17,Color("466237") if to>from else UI.OXBLOOD if to<from else UI.INK)
		value.name="Derived_"+stat
		value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		labels.add_child(value)

static func _build_pack(app: Variant, parent: VBoxContainer, selected: String) -> void:
	app._section(parent,"YOUR PACK",16)
	var pack_scroll: ScrollContainer=ScrollContainer.new()
	pack_scroll.name="PackScroll"
	pack_scroll.custom_minimum_size.y=146
	pack_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	pack_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(pack_scroll)
	var grid: GridContainer=GridContainer.new()
	grid.columns=6 if app.size.x<1100 else 8
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",5)
	grid.add_theme_constant_override("v_separation",5)
	pack_scroll.add_child(grid)
	var inventory: Array=app.realm.hero.inventory
	for index: int in range(maxi(grid.columns*2,inventory.size())):
		if index<inventory.size():
			var item: Dictionary=inventory[index]
			var id: String=str(item.instanceId)
			var button: Button=app._painted("",Art.item(item),func()->void:app._open_inventory(id,"equipment"),grid,Vector2(48,60),"slot")
			button.selected=id==selected
			button.badge="✓" if app.realm.hero.equipment.values().has(id) else ""
			button.tooltip_text=Items.describe(item)
			if id==selected:pack_scroll.call_deferred("ensure_control_visible",button)
		else:
			var empty: PanelContainer=PanelContainer.new()
			empty.custom_minimum_size=Vector2(48,60)
			empty.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			empty.add_theme_stylebox_override("panel",UI.tile())
			grid.add_child(empty)
	parent.add_child(app._body("%d items · Select an item to compare" % inventory.size(),14,UI.MUTED))
	var item: Dictionary=Items.find_instance(app.realm.hero,selected)
	if item.is_empty():return
	var details_panel: PanelContainer=PanelContainer.new()
	details_panel.add_theme_stylebox_override("panel",UI.paper(10))
	parent.add_child(details_panel)
	var details: VBoxContainer=VBoxContainer.new()
	details.add_theme_constant_override("separation",4)
	details_panel.add_child(details)
	var title_row: HBoxContainer=HBoxContainer.new()
	details.add_child(title_row)
	app._art_image(title_row,Art.item(item),Vector2(54,54))
	var title_column: VBoxContainer=VBoxContainer.new()
	title_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title_row.add_child(title_column)
	var title: Label=UI.heading(Items.item_name(item),21,app.QUALITY.get(item.quality,UI.INK))
	title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	title_column.add_child(title)
	title_column.add_child(app._body(str(item.quality).capitalize()+" · "+str(item.slot).replace("_"," ").capitalize(),14,UI.MUTED))
	var description: String=Items.describe(item)
	var line_break: int=description.find("\n\n")
	if line_break>=0:description=description.substr(line_break+2)
	details.add_child(app._body(description,16,app.QUALITY.get(item.quality,UI.INK)))
	var equipped_slot: String=""
	for slot: String in app.realm.hero.equipment:
		if str(app.realm.hero.equipment[slot])==selected:equipped_slot=slot
	var locked: bool=not app.action_state.is_empty()
	if not equipped_slot.is_empty():
		var unequip: Button=app._button("UNEQUIP",func()->void:app._equip_item(selected,equipped_slot,true),parent,36)
		unequip.disabled=locked
	elif str(item.slot) not in ["","material"]:
		var slots: Array=[""] if str(item.slot)!="ring" else ["ring_1","ring_2"]
		for target_slot: String in slots:
			var comparison: Dictionary=Sheet.compare_equipment(app.realm.hero,selected,target_slot)
			if bool(comparison.get("ok",false)):
				var replacement: Dictionary=comparison.replaces
				var caption: String="REPLACES "+Items.item_name(replacement) if not replacement.is_empty() else "EMPTY "+str(comparison.slot).replace("_"," ").to_upper()
				parent.add_child(app._body(caption,13,UI.MUTED))
				var changes: Array[String]=[]
				for change: Dictionary in comparison.rows:
					changes.append(str(change.label)+" "+Sheet.format_value(float(change.before),str(change.stat))+" → "+Sheet.format_value(float(change.after),str(change.stat)))
				parent.add_child(app._body(" · ".join(changes) if not changes.is_empty() else "No numeric stat change; compare the item's special effects.",14,UI.INK))
				for effect: String in comparison.gainedTraits:
					parent.add_child(app._body("Gain: "+_effect_name(effect),14,Color("466237")))
				for effect: String in comparison.lostTraits:
					parent.add_child(app._body("Lose: "+_effect_name(effect),14,UI.OXBLOOD))
				for set_id: String in comparison.setsBefore:
					var old_count: int=int(comparison.setsBefore[set_id])
					var new_count: int=int(comparison.setsAfter.get(set_id,0))
					for threshold: int in Items.set_catalog()[set_id].bonuses:
						if old_count>=threshold and new_count<threshold:
							parent.add_child(app._body("Lose %d-piece bonus: %s" % [threshold,str(Items.set_catalog()[set_id].name)],14,UI.OXBLOOD))
			var label: String="EQUIP" if target_slot.is_empty() else "EQUIP IN "+target_slot.replace("_"," ").to_upper()
			var equip: Button=app._button(label,func()->void:app._equip_item(selected,target_slot),parent,36)
			equip.disabled=locked or not bool(comparison.get("ok",false))
			equip.tooltip_text=str(comparison.get("message","Compare all equipment and set effects before equipping."))
	if int(item.sockets.capacity)>item.sockets.contents.size():
		for material_item: Dictionary in inventory:
			if str(material_item.itemId).begins_with("rune_") or str(material_item.itemId).begins_with("gem_"):
				var material_id: String=str(material_item.instanceId)
				var socket_button: Button=app._button("SOCKET "+Items.item_name(material_item).to_upper(),func()->void:app._socket_item(selected,material_id),parent,32)
				socket_button.disabled=locked
	if locked:parent.add_child(app._body("Return to town to change equipment or sockets.",14,UI.OXBLOOD))
	if not locked and equipped_slot.is_empty():
		var sale: Dictionary=Realm.preview_item_sale(app.realm,"dawnwatch",selected)
		if bool(sale.get("ok",false)):
			var sell: Button=app._button("SELL · %d GOLD" % int(sale.gold),func()->void:app._confirm_item_sale(selected),parent,32)
			sell.name="SellSelectedItem"
			sell.tooltip_text="Sell this unequipped item to Dawnreach’s Market. Its socket contents are included."
	for progress: Dictionary in Sheet.set_progress(app.realm.hero):
		parent.add_child(app._body("%s · %d / %d pieces equipped" % [str(progress.name),progress.equipped.size(),int(progress.total)],15,app.QUALITY.set))

static func _effect_name(id: String) -> String:
	return "Vowkeeper’s Cleave Ward" if id=="cleave_ward" else id.replace("_"," ").capitalize()

static func _build_collections(app: Variant, parent: VBoxContainer) -> void:
	app._section(parent,"THE BELLWORN VIGIL",16)
	parent.add_child(app._body("Recover the wardens’ equipment. Matching pieces unlock bonuses when worn together.",18,UI.MUTED))
	var definition: Dictionary=Items.set_catalog().bellwarden
	var equipped: Dictionary=Items.derive_stats(app.realm.hero).sets
	for item_id: String in definition.pieces:
		var held: Dictionary={}
		for item: Dictionary in app.realm.hero.inventory:
			if str(item.itemId)==item_id:held=item;break
		var row: HBoxContainer=HBoxContainer.new()
		row.add_theme_constant_override("separation",9)
		parent.add_child(row)
		var catalog: Dictionary=Items.catalog()[item_id]
		app._art_image(row,Art.equipment(str(catalog.slot)),Vector2(45,45))
		var labels: VBoxContainer=VBoxContainer.new()
		labels.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		labels.add_theme_constant_override("separation",0)
		row.add_child(labels)
		labels.add_child(UI.heading(str(catalog.name),17,UI.MUTED if held.is_empty() else Color("466237")))
		var status: String="Not recovered" if held.is_empty() else "Equipped" if app.realm.hero.equipment.values().has(str(held.instanceId)) else "In your pack"
		labels.add_child(app._body(status,14,UI.MUTED))
	parent.add_child(HSeparator.new())
	for threshold: int in definition.bonuses:
		var active: bool=int(equipped.get("bellwarden",0))>=threshold
		var effects: Array[String]=[]
		for stat: String in definition.bonuses[threshold]:
			effects.append("+"+Sheet.format_value(float(definition.bonuses[threshold][stat]),stat)+" "+str(Sheet.STAT_LABELS.get(stat,stat)))
		parent.add_child(app._body("%d PIECES · %s%s" % [threshold," · ".join(effects)," · ACTIVE" if active else ""],16,Color("466237") if active else UI.MUTED))
	parent.add_child(app._body("Two pieces support a mixed build. Four strengthen Ward further.",16,UI.MUTED))

static func _build_traits(app: Variant, parent: VBoxContainer) -> void:
	var view: Dictionary=Identity.trait_view(app.realm.hero)
	app._section(parent,str(view["class"].name).to_upper(),18)
	parent.add_child(app._body(str(view["class"].playstyle),18,UI.INK))
	var skill_row: HBoxContainer=HBoxContainer.new()
	skill_row.add_theme_constant_override("separation",12)
	parent.add_child(skill_row)
	for id: String in view.supportedSkills:
		var panel: PanelContainer=PanelContainer.new()
		panel.add_theme_stylebox_override("panel",UI.paper(6))
		panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		skill_row.add_child(panel)
		var row: HBoxContainer=HBoxContainer.new()
		panel.add_child(row)
		app._art_image(row,Art.ability(id),Vector2(54,54))
		var label: Label=app._body(str(Action.ABILITIES[id].name)+"\n%d Focus" % int(Action.ABILITIES[id].cost),17,UI.OXBLOOD)
		label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		row.add_child(label)
	parent.add_child(app._body("Race and class are permanent. Spending or resetting attributes keeps this identity.",15,UI.MUTED))
	app._section(parent,"MARA’S PERSONAL SIGNATURE",16)
	for trait_data: Dictionary in view.personalTraits:
		_trait_entry(app,parent,trait_data)
	app._section(parent,str(view.race.name).to_upper()+" RACIAL TRAITS",16)
	for trait_data: Dictionary in view.racialTraits:
		_trait_entry(app,parent,trait_data)

static func _trait_entry(app: Variant, parent: VBoxContainer, trait_data: Dictionary) -> void:
	var line: HBoxContainer=HBoxContainer.new()
	line.add_theme_constant_override("separation",8)
	parent.add_child(line)
	var name_label: Label=UI.heading(str(trait_data.name),17,UI.OXBLOOD)
	name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	line.add_child(name_label)
	var active: bool=str(trait_data.get("status","design_only"))=="implemented"
	line.add_child(app._body("Active" if active else "In development",13,Color("466237") if active else UI.MUTED))
	parent.add_child(app._body(str(trait_data.get("mechanic","")),15,UI.INK))
	if trait_data.has("limitCounter"):
		parent.add_child(app._body(str(trait_data.limitCounter),14,UI.MUTED))
