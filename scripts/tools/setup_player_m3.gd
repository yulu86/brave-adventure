## 主角动画资源与场景生成脚本（M3 阶段）。
##
## 一次性工具：从零构建 `assets/resources/animation/player_spriteframes.tres`
## （含 idle/run 两动画）并重建 `scenes/player.tscn`（BodySprite 从 ColorRect
## 换为 AnimatedSprite2D）。
##
## 遵从宪法 §12.1「场景文件必须由工具生成，禁止手写」+ MEMORY 既有经验：
## - 从零构建（SpriteFrames.new() / CharacterBody2D.new()），禁加载已有场景增量改
## - 首次 save 无 .uid 文件属正常，编辑器打开自动补
##
## 运行（Windows）：
##   "E:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" \
##     --headless --path . --script res://scripts/tools/setup_player_m3.gd
extends SceneTree


# === Constants ===

## 素材根目录（相对 res://）。
const _SPRITE_ROOT: String = "assets/sprites/Legacy-Fantasy_High_Forest_2.3/Character"

## SpriteFrames 资源输出路径（相对 res://）。
const _FRAMES_PATH: String = "res://assets/resources/animation/player_spriteframes.tres"

## player 场景输出路径。
const _SCENE_PATH: String = "res://scenes/player.tscn"

## player 脚本路径。
const _PLAYER_SCRIPT: String = "res://scripts/player/player.gd"

## PlayerStats 资源路径。
const _STATS_RES: String = "res://assets/resources/stats/player_stats.tres"

## idle 动画帧高（含持剑高举空间，美术清单附录 A）。
const _FRAME_H_80: int = 80
## BodyShape 脚底锚定在 Player 原点 Y=0，帧居中需 offset.y = -frame_h/2。
const _OFFSET_Y_80: int = -40


# === Lifecycle ===

func _init() -> void:
	var frames: SpriteFrames = _build_sprite_frames()
	# 设路径使场景引用独立 .tres（避免 SubResource 内联）。
	frames.take_over_path(_FRAMES_PATH)
	var err_frames: int = ResourceSaver.save(frames, _FRAMES_PATH)
	push_if_error(err_frames, "保存 SpriteFrames 失败: " + _FRAMES_PATH)

	var packed: PackedScene = _build_player_scene(frames)
	var err_scene: int = ResourceSaver.save(packed, _SCENE_PATH)
	push_if_error(err_scene, "保存 player.tscn 失败: " + _SCENE_PATH)

	print("[M3] 完成：已生成 player_spriteframes.tres + player.tscn")
	quit()


# === Private Methods ===

## 构建含 idle/run 两动画的 SpriteFrames（每帧用 AtlasTexture 从精灵表切片）。
func _build_sprite_frames() -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	# 清理 SpriteFrames.new() 自带的 default 空动画。
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	# idle：Idle-Sheet.png 256x80，hframes=4，fps=8，loop。
	_add_sliced_animation(frames, &"idle",
		_SPRITE_ROOT + "/Idle/Idle-Sheet.png", 4, 8, true, _FRAME_H_80)
	# run：Run-Sheet.png 640x80，hframes=10，fps=12，loop。
	_add_sliced_animation(frames, &"run",
		_SPRITE_ROOT + "/Run/Run-Sheet.png", 10, 12, true, _FRAME_H_80)
	return frames


## 从单行精灵表切出 hframes 帧，添加为一条动画。
##
## [param frames] 目标 SpriteFrames。[br]
## [param anim_name] 动画名。[br]
## [param tex_path] 源纹理 res:// 路径。[br]
## [param hframes] 横向帧数。[br]
## [param fps] 帧率。[br]
## [param loop] 是否循环。[br]
## [param frame_h] 单帧高度（用于计算切片 region；帧宽由纹理宽/hframes 推导）。
func _add_sliced_animation(frames: SpriteFrames, anim_name: StringName,
		tex_path: String, hframes: int, fps: int, loop: bool, frame_h: int) -> void:
	var tex: Texture2D = load(tex_path)
	if tex == null:
		push_error("无法加载纹理: " + tex_path)
		return
	var frame_w: int = int(tex.get_width()) / hframes
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, float(fps))
	frames.set_animation_loop(anim_name, loop)
	for i in hframes:
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2i(i * frame_w, 0, frame_w, frame_h)
		frames.add_frame(anim_name, atlas)


## 从零构建 player.tscn（CharacterBody2D + AnimatedSprite2D + CollisionShape2D）。
func _build_player_scene(frames: SpriteFrames) -> PackedScene:
	var root: CharacterBody2D = CharacterBody2D.new()
	root.name = "Player"
	root.collision_mask = 32  # 可碰撞地形层（layer_6=bit5=值32）
	root.set_script(load(_PLAYER_SCRIPT))
	root.set("stats", load(_STATS_RES))

	# BodySprite：AnimatedSprite2D，offset 锚定脚底中心（帧高 80 → offset.y=-40）。
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.name = "BodySprite"
	sprite.sprite_frames = frames
	sprite.offset = Vector2(0, _OFFSET_Y_80)
	root.add_child(sprite)
	sprite.set_owner(root)

	# BodyShape：32x40 矩形，position=(0,-20) 使脚底贴 Player 原点 Y=0。
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(32, 40)
	var col: CollisionShape2D = CollisionShape2D.new()
	col.name = "BodyShape"
	col.position = Vector2(0, -20)
	col.shape = shape
	root.add_child(col)
	col.set_owner(root)

	var packed: PackedScene = PackedScene.new()
	packed.pack(root)
	return packed


## 错误码非 OK 则 push_error。
func push_if_error(err: int, msg: String) -> void:
	if err != OK:
		push_error(msg + " (code=" + str(err) + ")")
