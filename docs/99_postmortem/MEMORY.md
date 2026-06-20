# MEMORY — 经验教训

> 每次任务后追加，禁止输出重复经验。

---

## 原则

<!-- 从此处追加原则，格式：
- {原则描述}
-->

## 实例

<!-- 从此处追加实例，格式：
- **场景**：什么情况下遇到
- **教训**：学到了什么
- **规则**：以后怎么做
-->

- **场景**：开发 M1（主角水平移动，2026-06-20）
- **教训**：
  - **Godot 碰撞层是位掩码，不是层号本身**：`collision_layer`/`collision_mask` 是 32 位位掩码，第 N 层（UI 显示 layer 1~32）对应 bit(N-1)，即值 `2^(N-1)`。我误把"可碰撞地形(layer_6)"写成 64（实际是 layer_7 触发区的值），正确应为 `2^5=32`。AI 配置碰撞层是自身职责，不能想当然
  - **headless SceneTree 脚本模式不生成 .uid 文件**：用 `extends SceneTree` + `--script` 运行的配置脚本不走 EditorFileSystem，反复 `ResourceSaver.save` 不会生成 Godot 4 的 `.uid` 映射文件。若 `.tscn` 内部声明了 `uid="uid://xxx"` 但无对应 `.uid` 文件，加载时会报 `invalid UID` 警告并 fallback 到 text path。解决办法：resave 时让 Godot 移除内部 uid 声明（首次 save 无 uid，后续编辑器打开会自动补全并生成 .uid）
  - **"加载场景→add_child→保存"脚本会累积重复节点**：用 `packed.instantiate()` 加载已有场景再 `add_child`，每次跑都会在原有节点基础上追加，导致 `@StaticBody2D@2` 这类自动命名重复节点。正确做法：配置脚本应**从零构建**（`Node2D.new()` 全新实例），不要加载已有场景做增量修改
  - **ColorRect 是 Control 节点，用 offset_* 而非 size/position**：占位方块用 ColorRect 时，尺寸通过 `offset_left/top/right/bottom` 定义，且需 `set_anchor(四边, 0)` 防止被父节点尺寸拉伸；直接设 `size`/`position` 不生效
  - **GdUnit4 API 版本差异**：本版 GdUnit4 无 `add_child_autoqfree()`，自动清理用 `auto_free(obj)`；新版 runner 路径从 `addons/gdUnit4/src/runner/GdUnitRunnerCmd.gd` 变为 `addons/gdUnit4/bin/GdUnitCmdTool.gd`；headless 跑测试需加 `--ignoreHeadlessMode`
  - **纯逻辑函数抽离提升可测性**：将 `compute_horizontal_velocity` 抽成纯函数（不依赖 Input/场景树），单测可直接传参验证加速度/摩擦力模型，绕开 headless 下 Input 事件不可注入的问题
- **规则**：
  - 以后配 Godot 碰撞层：layer N → 值 `2^(N-1)`，必须换算确认；layer(自己是什么)与 mask(检测谁)分开配；在文档/代码注释里标注"layer_6=可碰撞地形=bit5=值32"
  - 以后用脚本批量生成/配置场景：**从零构建**（`Xxx.new()`），禁用"加载已有场景增量改"；配置完跑一次 `godot_validate_scenes` 确认无重复/断裂
  - 以后 headless 配置 `.tscn`/`.tres`：接受首次无 .uid 文件（编辑器打开会自动补），不要为了消除 uid 警告反复 save
  - 以后写 GdUnit4 测试：自动清理一律用 `auto_free()`，不假设 `add_child_autoqfree` 存在；headless 命令固定用 `bin/GdUnitCmdTool.gd ... --ignoreHeadlessMode`
  - 以后做手感/移动逻辑：把核心计算抽成纯函数单测，避免依赖 Input/物理引擎的集成测试（headless 难注入）

- **场景**：分析项目游戏资产生成资产说明文档（2026-06-20）
- **教训**：
  - 精灵表帧数可通过 `sips -g pixelWidth -g pixelHeight` 取尺寸后，结合"单行布局 + 已知帧高"精确计算 `hframes`（帧数 = 宽 ÷ 帧宽），无需依赖 AI 视觉识别猜测
  - 项目是像素艺术游戏，全局 `default_texture_filter=0`（Nearest）+ 视口 `480×270` 是关键设计约束：16×16 瓦片网格、主角 64×80 帧、小怪 32×32 帧，所有资产尺寸需符合此基准
  - 资产命名存在源包遗留问题（`Legac-Fantasy` 少 y、`Jumlp-All` 拼错、`Small Bee` 含空格、`Walk-Base-SheetBlack.png` 命名不一致），接入脚本 `load` 时易踩坑
  - `cave.tres` 放在 `texture/` 目录实为 TileSet 且内容是草地非洞穴，命名/路径/内容三者不一致，是典型"早期随手建资源"的债务
  - 音频是包体大头（49MB），Minifantasy 的 WAV 音乐单首 13~15MB，正式发布前必须转 OGG
  - `bus.tres` 有未命名的 `New Bus 2`，必须重命名为 `Music`
- **规则**：
  - 以后分析精灵资产：先用 `sips` 批量取尺寸 + 目测帧高，数学计算帧数，再用 AI 视觉分析补充内容识别（验证而非猜测）
  - 以后新建 `.tres` 资源：目录、文件名、内容三者必须语义一致（TileSet 放 `tileset/` 目录、草地叫 `forest_ground` 而非 `cave`）
  - 以后接入动画表：记录每个动画的 `hframes`/`vframes`/`loop`/`fps` 到文档速查表（本项目已建 `docs/03_美术规范/01_美术资产清单.md` 附录 A）
  - 以后导入音频：音乐统一 OGG，短音效 WAV，禁止 WAV 用于长音乐
  - 以后配置 AudioBus：所有总线必须语义命名，禁用 Godot 默认 `New Bus N`

- **场景**：开发 M2（重力与跳跃，2026-06-20）
- **教训**：
  - **跳跃判定可纯函数化**：`is_on_floor() && just_pressed` 这种依赖物理/Input 的判定，抽成 `should_jump(on_floor: bool, jump_pressed: bool) -> bool`（`return on_floor and jump_pressed`）纯函数，单测直接传布尔值覆盖 3 分支，绕开 headless 无法注入 Input/物理状态的难题（延续 M1「纯函数抽离提升可测性」经验）
  - **变速跳跃最简洁实现**：`if Input.is_action_just_released(&"jump") and velocity.y < 0.0: velocity.y *= variable_jump_multiplier`——松键瞬间只裁剪上升阶段速度，一行实现可控高度，无需维护额外计时器
  - **project.godot [input] 可手写文本新增 action**：[input] 段是 INI 配置非 .tscn/.tres 场景，不属宪法 §12.1「场景文件必须由工具生成」约束，可直接 Edit 文本新增 action；但**必须**在编辑器重载项目（Project → Reload Current Project）让 InputMap 重新加载生效
  - **Input Action 绑定速查**：键盘用 `InputEventKey` + `physical_keycode`（Space=32，A=65，D=68，方向键左=4194319/右=4194321）；手柄按键用 `InputEventJoypadButton` + `button_index`（A=0 即 JOY_BUTTON_A），摇杆用 `InputEventJoypadMotion` + `axis`/`axis_value`
  - **godot-ultimate MCP 路径前缀**：`godot_lint_file` 用 `scripts/player/player.gd`（无 res:// 前缀）能识别，`godot_validate_inputs` 对 `Input.get_axis(&"a",&"b")` 这类间接引用的 action 可能误报 unused（实际有用），需结合代码人工判断
- **规则**：
  - 以后做依赖物理状态/Input 的判定逻辑：尽量抽纯函数（入参传基本类型 bool/float），单测传参覆盖分支，集成验证靠玩家手工
  - 以后加新 Input Action：直接 Edit `project.godot [input]` 文本（非场景文件，§12.1 不约束），改完提醒用户重载项目
  - 以后写变速跳跃：固定用 `is_action_just_released + velocity.y < 0` 裁剪上升速度方案，简洁且足够

- **场景**：开发 M3/M4（主角 idle/run/jump 动画，2026-06-20）
- **教训**：
  - **AnimatedSprite2D 的 offset 是节点级单一值，无 per-animation offset**：当不同动画帧高不一致（如 idle/run 高 80px、jump 高 64px）时，固定 offset 无法同时脚底对齐。解决方案：在代码切动画时**动态设 offset**（`_apply_offset(anim)`），按帧高算 `offset.y = -frame_h/2` 使脚底恒贴碰撞框脚底（架构 §14.2 帧尺寸对齐风险）
  - **SpriteFrames 切帧用 AtlasTexture + add_frame 而非 hframes**：`AnimatedSprite2D` 本身无 hframes 属性（那是 Sprite2D/Sprite3D 的）。SpriteFrames 要从精灵表切帧，需为每帧创建 `AtlasTexture`（设 `atlas`=源纹理 + `region`=Rect2 切片），用 `frames.add_frame(anim_name, atlas)` 逐帧添加。切片 region 用 `Rect2i(i*frame_w, 0, frame_w, frame_h)` 横向切（单行表）
  - **非循环动画每帧重复调 play 会被重置重播**：`_physics_process` 里每帧调 `body_sprite.play("jump")`，即使 loop=false 也会反复从头播放（用户验证发现"jump 在空中播放多次"）。修复：仅在动画名变化时调 play（`if body_sprite.animation != anim: play(anim)`），落地后 is_on_floor() 转 true 自然触发切回 idle
  - **@onready 引用使旧测试夹具失效**：M3 起 player.gd 加了 `@onready body_sprite = $BodySprite`，M1/M2 用 `Player.new()` 纯代码创建的测试夹具会因无 BodySprite 子节点在 `_ready` 报 "Node not found"。修复：测试夹具统一改为 `load("res://scenes/player.tscn").instantiate()` 实例化真实场景（遵 §4.2 场景可复用可实例化）
  - **SpriteFrames.take_over_path 让场景引用独立 .tres**：`ResourceSaver.save(frames, path)` 后默认会被场景内联为 SubResource（重复存储）。在 save 前调 `frames.take_over_path(path)` 设资源路径，pack 场景时即引用外部 .tres 而非内联
  - **配置脚本生成的 SpriteFrames 首次带 default 空动画**：`SpriteFrames.new()` 自带一个空的 `default` 动画（frames=[], speed=5），生成时需 `if has_animation(&"default"): remove_animation(&"default")` 清理
  - **Godot API 用 ClassDB 脚本现场查最准**：Context7/MCP 文档缓存常不全（SpriteFrames/AtlasTexture 不在 godot-ultimate 缓存）。写个 `extends SceneTree` 临时脚本用 `ClassDB.class_get_method_list("ClassName")` / `class_get_property_list("ClassName")` 直接查引擎实例，比查文档可靠
- **规则**：
  - 以后做帧高不一致的多动画（如跳跃 vs 移动）：用代码动态切 offset 脚底对齐，不指望 AnimatedSprite2D 有 per-animation offset
  - 以后用 SpriteFrames 从精灵表切帧：每帧建 AtlasTexture（atlas+region）+ add_frame，不要找不存在的 hframes
  - 以后播非循环动画：只在动画名变化时调 play，禁每帧重复调（防重置重播）
  - 以后被测类有 @onready 节点引用：测试夹具用场景实例化，不用纯 new()
  - 以后查 Godot API：优先用 ClassDB SceneTree 脚本现场查，比文档/MCP 可靠

## 项目专属经验（brave-adventure）

- **技术栈**：Godot 4.6 + Forward Plus + Jolt Physics + GdUnit4；视口 320×180，窗口 2560×1440（8×缩放），stretch=viewport（**M4 用户精调由 480×270 收窄至 320×180**）
- **核心美术包**：`Legacy-Fantasy_High_Forest_2.3/`（itch.io 免费），提供主角7动作/3怪物/地形/道具/背景/HUD 全套
- **怪物清单**：野猪(Boar,32px,地面冲撞)/蜗牛(Snail,32px,防御缩壳)/蜜蜂(Small Bee,64px,飞行) —— 注意无兽人(Orc)，但音效包有 orc 系列，可复用
- **主角动画缺口**：无独立受击(Hurt)动画，只有 Dead；接入状态机时受击态需临时代替
- **TileSet 现状**：cave.tres(Tiles→草地)、background/foreground/geometry.tres(Tree-Assets→树冠/树梢/树干分层)，建筑/蜂巢/室内/岩石道具尚未配 TileSet
- **字体**：主题引用 SmileySans-Oblique.otf(中文)，另有未引用的同名 .ttf(冗余2.5M)；PixelOperator8 为像素英文
- **GdUnit4 测试命令**：headless 跑测试用 `"$GODOT_HOME/godot" --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/{目录} --ignoreHeadlessMode`（非宪法附录 A 的旧 runner 路径，且需 `--ignoreHeadlessMode`）；测试清理用 `auto_free()` 无 `add_child_autoqfree`
- **碰撞层位掩码速查**：layer_1玩家=1, layer_2敌人=2, layer_3玩家攻击区=4, layer_4敌人攻击区=8, layer_5受击区=16, layer_6可碰撞地形=32, layer_7触发区=64（值=2^(层号-1)）
- **物理层配置**：玩家 layer=玩家(1) mask=可碰撞地形(32)；敌人 layer=敌人(2) mask=可碰撞地形(32)；地面 layer=可碰撞地形(32) mask=0
- **场景生成方式**：用 `extends SceneTree` + `--script` 的配置脚本 + `ResourceSaver.save` 从零构建 .tscn/.tres（非手写文本，符合宪法 §12.1）；首次无 .uid 文件属正常，编辑器打开自动补
- **Story 收尾必做：刷新进度索引**：每个 Story 完成并通过玩家手工验证（§12.5）后，**必须**刷新 `docs/07_story/01_MVP/README.md` 中该 Story 的状态列（`⬜ 待开发` → `✅ 已完成`）+ 更新对应 Story 文档头部的「状态」字段；该动作纳入 §12.6 收尾闭环，与经验沉淀同一 docs commit 提交
- **主角 SpriteFrames**：`assets/resources/animation/player_spriteframes.tres`，含 idle(4帧/fps8/loop)/run(10帧/fps12/loop)/jump(15帧/fps15/非循环)；帧高差异 idle+run=80、jump=64，靠 player.gd `_apply_offset` 动态切 offset（idle+run→-40，jump→-32）。源素材在 `assets/sprites/Legacy-Fantasy_High_Forest_2.3/Character/{Idle,Run,Jumlp-All}/`（注意 Jumlp 源包拼写错误）
- **视口分辨率已收窄**：M4 用户精调将视口 480×270 → 320×180、窗口 1920×1080 → 2560×1440（8× 缩放）。架构文档/GDD/美术清单已同步刷新（关卡物理宽度 2400px 不变，屏数由 5 屏变 7.5 屏）。瓦片网格 16×16 不变，一行由 30 格变 20 格
- **配置脚本目录**：`scripts/tools/setup_player_m{3,4}.gd`（extends SceneTree），已纳入 git（.gitignore 无 tools/ 忽略），用 `godot --headless --path . --script res://scripts/tools/xxx.gd` 运行。后续角色/资源生成脚本放此处
