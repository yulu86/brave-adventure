## 主角动画资源生成脚本（M4 阶段）。
##
## 一次性工具：从零重建 `assets/resources/animation/player_spriteframes.tres`，
## 在 M3 的 idle/run 基础上新增 jump 动画（Jump-All 表 hframes=15，fps=15，非循环）。
## player.tscn 无需改动（引用的 .tres 路径不变，内容更新即可）。
##
## 遵从宪法 §12.1 + MEMORY 既有经验：从零构建，首次无 .uid 属正常。
##
## 运行（Windows）：
##   "E:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" \
##     --headless --path . --script res://scripts/tools/setup_player_m4.gd
extends SceneTree


# === Constants ===

## 素材根目录（相对 res://）。
const _SPRITE_ROOT: String = "assets/sprites/Legacy-Fantasy_High_Forest_2.3/Character"

## SpriteFrames 资源输出路径（相对 res://）。
const _FRAMES_PATH: String = "res://assets/resources/animation/player_spriteframes.tres"

## idle/run 动画帧高（含持剑高举空间）。
const _FRAME_H_80: int = 80
## jump 动画帧高（起跳/滞空/落地合并表，无高举空间）。
const _FRAME_H_64: int = 64


# === Lifecycle ===

func _init() -> void:
	var frames: SpriteFrames = _build_sprite_frames()
	frames.take_over_path(_FRAMES_PATH)
	var err: int = ResourceSaver.save(frames, _FRAMES_PATH)
	push_if_error(err, "保存 SpriteFrames 失败: " + _FRAMES_PATH)

	print("[M4] 完成：player_spriteframes.tres 已含 idle/run/jump")
	quit()


# === Private Methods ===

## 构建含 idle/run/jump 三动画的 SpriteFrames。
func _build_sprite_frames() -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	# idle：Idle-Sheet.png 256x80，hframes=4，fps=8，loop。
	_add_sliced_animation(frames, &"idle",
		_SPRITE_ROOT + "/Idle/Idle-Sheet.png", 4, 8, true, _FRAME_H_80)
	# run：Run-Sheet.png 640x80，hframes=10，fps=12，loop。
	_add_sliced_animation(frames, &"run",
		_SPRITE_ROOT + "/Run/Run-Sheet.png", 10, 12, true, _FRAME_H_80)
	# jump：Jump-All-Sheet.png 960x64，hframes=15，fps=15，非循环（起势→滞空→落地一次性播完）。
	# 注意源包目录名拼写为 Jumlp-All（源包遗留错误，美术清单已记录）。
	_add_sliced_animation(frames, &"jump",
		_SPRITE_ROOT + "/Jumlp-All/Jump-All-Sheet.png", 15, 15, false, _FRAME_H_64)
	return frames


## 从单行精灵表切出 hframes 帧，添加为一条动画。
##
## [param frames] 目标 SpriteFrames。[br]
## [param anim_name] 动画名。[br]
## [param tex_path] 源纹理 res:// 路径。[br]
## [param hframes] 横向帧数。[br]
## [param fps] 帧率。[br]
## [param loop] 是否循环。[br]
## [param frame_h] 单帧高度（帧宽由纹理宽/hframes 推导）。
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


## 错误码非 OK 则 push_error。
func push_if_error(err: int, msg: String) -> void:
	if err != OK:
		push_error(msg + " (code=" + str(err) + ")")
