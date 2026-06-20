## 实体数值配置基类。
##
## 所有可受击实体（主角/野猪）共享的数值容器基类，提供阵营与血量。
## 子类（PlayerStats/BoarStats）按角色专属参数扩展。遵从宪法 §1.4 数据驱动。
class_name StatsResource
extends Resource

## 最大血量。
@export var max_health: int = 100
