## 主角数值配置。
##
## 承载主角移动/手感/战斗数值，配置存 `.tres`（可在 Inspector 调参）。
## 重力不在本类，改由 ProjectSettings 全局配置（架构 ADR-2）。
class_name PlayerStats
extends StatsResource

# === Movement ===
## 水平最大移动速度（px/s）。
@export var move_speed: float = 160.0
## 加速度（px/s²），影响起步响应。
@export var acceleration: float = 1200.0
## 摩擦力（px/s²），影响松手减速。
@export var friction: float = 1200.0
## 跳跃初速度（px/s，负值朝上）。
@export var jump_velocity: float = -280.0
## 变速跳跃倍率：松开跳跃键时上升速度乘以此值（控制跳跃高度）。
@export var variable_jump_multiplier: float = 0.5

# === Jump Feel ===
## 土狼时间（秒）：离开平台边缘后仍可起跳的宽限期（架构 ADR-12）。
@export var coyote_time: float = 0.10
## 跳跃缓冲（秒）：落地前按跳跃键的缓冲期，落地自动起跳（架构 ADR-12）。
@export var jump_buffer_time: float = 0.10

# === Combat ===
## 单次攻击伤害。
@export var attack_damage: int = 15
## 攻击冷却时间（秒）。
@export var attack_cooldown: float = 0.45
## 受击无敌帧持续时间（秒）。
@export var invincible_duration: float = 1.0
## 受击击退力（px/s）。
@export var knockback: float = 150.0
