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

## 项目专属经验（brave-adventure）

- **技术栈**：Godot 4.6 + Forward Plus + Jolt Physics + GdUnit4；视口 480×270，窗口 1920×1080，stretch=viewport
- **核心美术包**：`Legacy-Fantasy_High_Forest_2.3/`（itch.io 免费），提供主角7动作/3怪物/地形/道具/背景/HUD 全套
- **怪物清单**：野猪(Boar,32px,地面冲撞)/蜗牛(Snail,32px,防御缩壳)/蜜蜂(Small Bee,64px,飞行) —— 注意无兽人(Orc)，但音效包有 orc 系列，可复用
- **主角动画缺口**：无独立受击(Hurt)动画，只有 Dead；接入状态机时受击态需临时代替
- **TileSet 现状**：cave.tres(Tiles→草地)、background/foreground/geometry.tres(Tree-Assets→树冠/树梢/树干分层)，建筑/蜂巢/室内/岩石道具尚未配 TileSet
- **字体**：主题引用 SmileySans-Oblique.otf(中文)，另有未引用的同名 .ttf(冗余2.5M)；PixelOperator8 为像素英文
