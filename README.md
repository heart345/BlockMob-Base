# MC Mob in GMod

目标：把 Minecraft Java Edition 的生物做成 Garry's Mod NPC，并且尽量接近原版 Minecraft 的移动、声音、攻击节奏和行为，而不是只换模型。

当前目标基线：Minecraft Java Edition 26.1 系列，以 26.1.2 hotfix 为准。

## 方向

先做一条最小但完整的纵向切片：

1. 先做一只敌对生物，建议从 Zombie 开始。
2. 第一版先用 Source 占位模型，随后替换成 Minecraft 风格模型和动画。
3. 先验证移动、脚步声、待机叫声、受伤/死亡声、索敌、追击和近战。
4. 做一套可重复测试清单，再扩展到更多生物。

本仓库不包含 Minecraft 原版资产。公开发布到 Workshop 时，模型、贴图和声音必须是原创、有授权，或以符合 Mojang/Microsoft 规则的方式处理。

## 本地 Addon

addon 骨架在：

```text
gmod_addon/
```

测试时，把这个文件夹复制或链接到 Garry's Mod：

```text
GarrysMod/garrysmod/addons/mc_mobs_in_gmod
```

然后进沙盒地图，生成：

```text
BMB Zombie
```

## 为什么从小做起

自然的 Minecraft 手感不是单个功能，而是一组细节叠在一起：

- 模型比例和骨骼轴心要对
- 短循环走路动画要匹配移动速度
- 脚步声要跟实际速度绑定
- 行为规则要简单但稳定
- 攻击距离、冷却、声音、受击反应要接近 Minecraft
- 寻路不能每帧过度纠正方向

如果一只生物做得像，后面的生物才能复用同一套系统。
