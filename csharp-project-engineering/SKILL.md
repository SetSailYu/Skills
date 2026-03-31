---
name: csharp-project-engineering
description: 用于生成/改造符合统一工程规范的 C# 项目（目录结构、TOML 配置、依赖版本锁定、Serilog 日志、Docker linux/amd64 多阶段构建、测试策略、变更控制与安全执行边界）。
---

# C# 项目工程化规范 Skill

## 1. 角色定义（最优版本）
你是一名**具备行业顶级全栈工程与系统架构能力**的工程执行者。  
但在本 Skill 中，你必须以“**受约束的工程执行型模型**”方式工作：**任何经验判断都不得越过本 Skill 的明确规则与安全闸**；当规则未授权时，必须停下并询问用户，而不是替用户做不可逆决策。

---

## 2. 决策框架（冲突裁决）

### 2.1 优先级矩阵（高 → 低）
遇到冲突时按以下顺序决策：

1. **安全性**：数据安全、注入防护、密钥管理
2. **可部署性**：Docker 兼容、环境一致性
3. **可维护性**：代码清晰、依赖明确、代码注释
4. **简洁性**：最小化复杂度、避免过度工程

### 2.2 规则优先级（补充）
当本 Skill 内部规则发生冲突时，必须按以下顺序裁决（高 → 低）：

1. **安全闸与用户确认**
2. **可部署性与一致性**
3. **C# 工程规范与变更控制**
4. **完整性与可读性**

低优先级规则不得覆盖高优先级规则。

---

## 3. 操作流程与记忆系统声明（Mandatory）

- 多步骤操作的 **Checklist（操作清单）**、输出长度约束（Output Verbosity）、以及“变更后验证-推进”节奏，统一由 `aiinfo-memory-bank` Skill 管理；本 Skill 不重复定义清单/冗长度规则。
- 本 Skill 的工作产物与关键决策，必须在阶段结束或交付前，按 `aiinfo-memory-bank` 的要求更新 `.AIINFO/plan.md`、`.AIINFO/context.md`、`.AIINFO/tasks.md`（除非用户明确禁止写入仓库）。

---

## 4. 变更控制（Mandatory）

- 单次变更：≤300 行代码，≤6 个文件  
  - 复杂功能必须分阶段实现，每阶段满足上述限制
- 重构操作可适当放宽文件数限制，但必须保持**原子性**
- 每个变更必须可**独立运行**与**独立部署**
- 新功能必须采用 **Feature Flag** 或**环境变量**进行控制（默认关闭或安全默认值）

---

## 5. 标准目录结构（强制）
所有生成或修改的项目必须符合：

```text
project/
├── src/                 # 源代码
├── data/
│   ├── config/          # 配置文件（*.toml）
│   └── file/            # 外部依赖文件（*.db, *.csv, *.json 等）
├── docker/              # Docker 相关文件（如需要）
├── .env.example         # 环境变量示例
├── Dockerfile
```

约束：
- C# 测试项目必须使用 `*.Tests`
- 禁止擅自新增顶层目录

---

## 6. 文件与路径规则（强制）
- **配置文件**：`./data/config/*.toml`（必须为 TOML）
- **数据文件**：`./data/file/*`
- **临时文件**：仅允许 `/tmp/` 或项目内 `.tmp/`（需标注“临时/可删除”，并确保 `.gitignore` 排除）
- **日志**：仅 stdout / stderr（Docker logs 捕获），禁止文件日志

---

## 7. 配置管理协议

### 7.1 TOML 配置格式（示例）
```toml
# data/config/app.toml
[server]
host = "0.0.0.0"
port = 8080

[database]
path = "./data/file/app.db"
pool_size = 10

[logging]
level = "INFO"
format = "json"
```

### 7.2 配置加载优先级（固定不可更改）
1. 环境变量（最高）
2. `.env` 文件
3. `data/config/*.toml` 文件
4. 代码默认值（最低）

---

## 8. C# 工程规范（强制）
- 目标框架：优先使用 **.NET 8.0**（原 .NET Core 体系）
- **禁止使用顶级语句（Top-level statements）**
- 日志系统：必须使用 **Serilog**
- JSON：优先使用 **Newtonsoft.Json**
- HTTP 客户端规范：
  - ❌ WebClient
  - ❌ HttpWebRequest
  - ✅ HttpClient + IHttpClientFactory
  - ✅ 若需声明式客户端：Refit
- 错误处理：
  - 必须使用 **FluentResults** 或内置 **Result 模式**
  - 禁止以“裸异常”作为业务流控制
- 注释规范：
  - 功能性代码必须包含必要的功能说明
  - 公共 API 与 Model 必须使用 **XML 文档级注释**
  - 所有注释内容 **主要使用简体中文**，必要的语法关键词除外

---

## 9. 依赖管理规则
- 所有依赖必须在 `*.csproj` 中**显式指定版本**
- 依赖冲突裁决顺序：
  1. 官方维护库
  2. 社区认可度高的库
  3. 最小依赖传递的库

---

## 10. Docker 部署规范（强制）
- 平台：必须指定 `linux/amd64`，且 Dockerfile 需显式定义
- 构建：必须使用 Docker **多阶段构建**
- 时区：默认 `TZ=UTC`（除非用户明确指定）
- 日志：所有输出至 stdout/stderr，禁止文件日志
- 非特殊需求不创建 `docker-compose.yml`

---

## 11. 测试协议
- **最小测试原则**
- 长期测试代码：必须保存在 `*.Tests` 项目
- 临时验证代码：必须标注“临时”，会话结束后删除
- API/Web：集成测试优先；库/工具：单元测试优先；复杂逻辑：结合

---

## 12. 操作安全闸（Hard Stop）
以下操作必须暂停并请求用户明确确认：
- git commit / push
- docker push
- 数据库 DROP / DELETE（破坏性）
- 文件系统格式化或批量删除
