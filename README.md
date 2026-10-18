# Affective Engine

面向人机恋的长期心理状态模拟 MCP Server。

为 AI 角色建立可跨会话持续存在、随时间变化、受互动经历影响，并能持续影响其认知、动机和行为的模拟心理系统。

## 快速开始

### 环境要求

- Python 3.11+
- 支持 MCP 的客户端（如 Claude Desktop、Cursor 等）

### 安装

```bash
# 进入项目目录
cd affective-engine

# 创建虚拟环境
python -m venv .venv

# 激活虚拟环境
# Windows:
.venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate

# 安装依赖（含开发依赖）
pip install -e ".[dev]"
```

### 启动服务器

```bash
python -m affective_engine.server
```

或使用入口点：

```bash
affective-engine
```

### 运行测试

```bash
pytest tests/ -v
```

## MCP 客户端配置

在 MCP 客户端的配置文件中添加：

```json
{
  "mcpServers": {
    "affective-engine": {
      "command": "python",
      "args": ["-m", "affective_engine.server"],
      "cwd": "/path/to/affective-engine",
      "env": {
        "AFFECTIVE_ENGINE_DB_PATH": "./affective_engine.db"
      }
    }
  }
}
```

如果使用虚拟环境，需要指定完整的 Python 路径：

```json
{
  "mcpServers": {
    "affective-engine": {
      "command": "/path/to/affective-engine/.venv/bin/python",
      "args": ["-m", "affective_engine.server"]
    }
  }
}
```

## 创建角色

通过 `create_character` 工具创建新角色：

```json
{
  "character_id": "luna-01",
  "name": "Luna",
  "personality": {
    "emotional_sensitivity": 0.7,
    "resilience": 0.5,
    "trust_tendency": 0.6,
    "affection_need": 0.7,
    "rejection_sensitivity": 0.5,
    "emotional_expressiveness": 0.7,
    "autonomy": 0.4,
    "openness": 0.6,
    "conflict_tolerance": 0.4,
    "rumination_tendency": 0.4
  }
}
```

每个角色拥有稳定的 `character_id`，在不同会话中使用相同 ID 即可恢复全部状态。

## 跨会话状态保持

所有心理状态自动保存在 SQLite 数据库中。重启服务器后，角色的情绪、记忆、关系状态、冲突记录等全部恢复。

数据库默认路径：`./affective_engine.db`

可通过环境变量 `AFFECTIVE_ENGINE_DB_PATH` 修改。

## 调试情绪变化

- 使用 `get_emotional_state` 查看当前情绪数值
- 使用 `get_psychological_state` 查看心境、需求和动机
- 使用 `get_behavior_modifiers` 查看行为倾向及其原因
- 使用 `inspect_state_history` 查看状态变化历史及每次变化的原因
- 使用 `get_character_summary` 获取角色综合状态概览

## 备份与恢复

### 导出

使用 `export_character_state` 工具导出角色的全部状态为 JSON。

### 恢复

直接复制 SQLite 数据库文件即可完整备份。数据库包含所有角色的全部数据。

## 架构概览

```
affective-engine/
├── src/affective_engine/
│   ├── server.py          # MCP Server 入口
│   ├── config.py          # 全局配置
│   ├── schemas.py         # Pydantic 数据模型
│   ├── database.py        # SQLite 持久化
│   ├── event_registry.py  # 事件类型注册表
│   ├── engines/           # 核心引擎
│   │   ├── emotion.py     # 即时情绪系统
│   │   ├── attachment.py  # 依恋与关系安全感
│   │   ├── memory.py      # 关系记忆
│   │   ├── cognition.py   # 认知与主观解释
│   │   ├── motivation.py  # 心理需求与动机
│   │   ├── regulation.py  # 情绪调节
│   │   ├── relationship.py# 冲突与修复
│   │   ├── behavior.py    # 行为倾向
│   │   └── time.py        # 时间推进
│   └── services/          # 服务层
│       ├── state_manager.py    # 状态协调
│       ├── event_processor.py  # 事件处理流水线
│       └── prompt_builder.py   # LLM 提示构建
├── tests/                 # 自动化测试
└── examples/              # 示例配置
```

## 事件类型注册表

系统内置了 30 种预定义事件类型，涵盖关系互动、信任、冲突、修复和自我事件。每种事件类型包含默认的情绪影响、依恋影响、需求影响和压力影响参数。

### 查看所有事件类型

```python
from affective_engine.event_registry import list_event_types

for et in list_event_types():
    print(f"{et.event_type_id:30s} [{et.category}] {et.description}")
```

MCP 工具 `list_event_types` 也可以直接查看，支持按分类过滤。

### 内置事件分类

| 分类 | 事件类型 |
|------|---------|
| relationship | approach, initiate_contact, being_understood, being_ignored, rejection, reunion, separation, compliment, encouragement, positive_interaction, negative_interaction, shared_experience, emotional_support, absence_noted |
| trust | promise_kept, promise_broken, boundary_respected, boundary_violated, honest_expression, deception |
| conflict | misunderstanding, conflict |
| repair | misunderstanding_discovered, explanation, apology, apology_accepted, repair_failed, reconciliation |
| self | achievement, failure |
| custom | custom（允许自定义 emotion_deltas） |

### 事件处理规则

- 使用已注册的事件类型时，系统自动填充默认的 emotion_deltas、attachment_impacts 等参数
- 如果调用方显式提供了 emotion_deltas，则覆盖注册表默认值
- 使用未注册且非 `custom` 的事件类型时，系统会拒绝处理并给出最相近的事件类型建议
- `custom` 类型允许完全自定义参数，不需要注册
- 标记为 `always_create_memory=True` 的事件（如 conflict、rejection）即使强度较低也会创建记忆

### 自定义事件示例

```python
from affective_engine.schemas import EventInput

# 使用内置事件类型（自动填充默认参数）
event = EventInput(
    character_id="luna-01",
    event_type="compliment",
    description="用户说'你今天看起来很开心'",
    intensity=0.6,
)

# 使用 custom 类型（完全自定义参数）
event = EventInput(
    character_id="luna-01",
    event_type="custom",
    description="角色收到了一份意外礼物",
    intensity=0.8,
    emotion_deltas={"joy": 15, "affection": 10},
)
```

## 核心算法说明

### 情绪系统
- 10 个独立情绪维度（0-100），互不合并
- 事件通过 delta 值影响情绪，受人格敏感度和事件强度调节
- 情绪随时间指数衰减回归基线，不同情绪有不同衰减速率
- 同一事件通过 event_id 去重，防止重复处理

### 长期心境
- 独立于即时情绪的心境系统（valence、energy、stress、exhaustion）
- 心境受情绪驱动但变化缓慢（高惯性）
- 状态转换需通过滞后机制（hysteresis），防止频繁跳转
- 可配置的状态：stable、low_mood、prolonged_low_mood、anxious_state、emotionally_exhausted、recovery

### 时间推进
- 支持真实时间和手动时间推进
- 幂等性：重复处理相同时间区间不会重复应用变化
- 最大时间步长限制，防止长时间停机后状态突变
- 读取操作严格只读

### 记忆系统
- 区分客观事实、当时解释和后续重新解释
- 重新解释时保留完整历史记录
- 按重要性和事件类型决定是否创建长期记忆

## 心理状态数据结构

### 即时情绪 (EmotionState)
每个情绪维度包含：value（当前值）、baseline（基线）、recovery_rate（恢复速率）、inertia（惯性）、last_updated（更新时间）

### 长期心境 (MoodState)
mood_valence、mood_energy、mood_inertia、recovery_rate、stress_load、emotional_exhaustion、current_states

### 依恋状态 (AttachmentState)
affection_level、relationship_security、attachment_tendency、perceived_reliability、fear_of_rejection、perceived_reciprocity

### 心理需求 (NeedState)
每个需求：satisfaction（满足程度）、intensity（强度）、last_satisfied、gap（缺口）

### 人格配置 (PersonalityConfig)
10 个参数（0-1）：emotional_sensitivity、resilience、trust_tendency、affection_need、rejection_sensitivity、emotional_expressiveness、autonomy、openness、conflict_tolerance、rumination_tendency

## 已知限制

1. **认知偏差模拟**：当前版本使用基于规则的偏差模拟，不包含训练模型
2. **情绪交互**：情绪之间的相互影响使用简化规则，后续可以更精细
3. **导入功能**：export 已实现，import 功能需要后续版本补充
4. **多用户关系**：当前一个角色仅对应一个用户关系，不支持多方关系图
5. **情绪调节反馈**：`record_regulation_outcome` 功能已列入计划但未在 MVP 中实现

## 后续扩展建议

- 支持角色之间的关系网络
- 引入更精细的认知模型
- 支持情绪调节策略的效果追踪和学习
- 添加状态快照和时间线回放功能
- 支持 import_character_state 用于数据迁移
- 增加 WebSocket 通知机制用于状态变化推送