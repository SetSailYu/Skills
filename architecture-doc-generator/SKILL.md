---
name: architecture-doc-generator
description: 面向 Codex CLI 的“工具优先”架构文档生成 Skill。优先调用 MCP（architecture-analyzer / codegraph / code-index / repomix / doc-generator / context7 / Mermaid / PlantUML）抽取证据，最小化 token 消耗，并生成可交付研发团队的架构知识库与本地 VitePress 文档站。
---

# architecture-doc-generator（Optimal / Codex CLI + MCP）

## 目标
把任意项目仓库转换为一套 **可交付研发团队** 的技术文档系统：

- `docs/architecture/`：架构知识库（Markdown + Mermaid + 代码路径可追溯）
- `docs/architecture/.evidence/`：证据包（低 token 摘要）
- `docs/.vitepress/`：本地文档站配置
- `docs/index.md`：文档站首页

## 核心原则
1. **工具优先，模型后置**
   - 先用 MCP 抽取事实，再让模型写文档。
2. **证据优先，推断受限**
   - 文档中的结论必须能追溯到：代码路径、命中行、工具输出、配置文件、契约文件。
3. **少读源码，多读索引**
   - 优先 `architecture-analyzer` / `codegraph` / `code-index`
   - 再用 `repomix`
   - 最后才读取原文件必要片段
4. **外部知识只用于解释，不用于定义仓库事实**
   - `context7` 只负责框架/库/标准的外部知识
5. **图表自动化**
   - 优先 Mermaid
   - Mermaid 不适合时再使用 PlantUML

## MCP 使用优先级（固定顺序）
### 第一层：结构与图谱（最省 token）
1. `architecture-analyzer`
2. `codegraph`
3. `code-index`

用途：
- 服务边界
- 模块/目录关系
- 入口点
- 依赖边
- 分层结构推断
- API / topic / migration / metrics 命中定位

### 第二层：上下文压缩
4. `repomix`

用途：
- 需要跨多个文件理解同一能力时，生成压缩上下文
- 仅作为“辅助理解”，不能替代代码证据

### 第三层：外部文档与初稿
5. `context7`
6. `doc-generator`

用途：
- 查最新官方文档
- 根据证据包生成结构化文档初稿

### 第四层：图表生成
7. `mcp-mermaid`
8. `plantuml`

用途：
- C4 / ER / sequence / deployment 图
- 默认先 Mermaid

## 证据包（必须先生成）
先写入：`docs/architecture/.evidence/`

最少包含：
- `repo-map.md`
- `stack.json`
- `services.json`
- `entrypoints.json`
- `api-surface.md`
- `data-surface.md`
- `events-surface.md`
- `infra-surface.md`
- `obs-surface.md`
- `open-questions.md`

规则：
- 每个文件建议 <= 200 行
- 带“路径 + 命中行/片段”
- 标注状态：`confirmed` / `assumption` / `needs-validation`

## 工作流（严格按顺序）
### Step 0：补齐本地文档站骨架
如果缺失，则从 `resources/templates/vitepress/` 创建：
- `docs/index.md`
- `docs/.vitepress/config.ts`
- `docs/.vitepress/sidebar.generated.ts`

### Step 1：生成结构证据
按顺序调用：
1. `architecture-analyzer`
2. `codegraph`
3. `code-index`

产出：
- `repo-map.md`
- `services.json`
- `entrypoints.json`
- `stack.json`

### Step 2：生成契约与数据面证据
按顺序调用：
1. `code-index`
2. `repomix`（仅跨文件理解需要时）
3. 必要时读取少量原文件片段

产出：
- `api-surface.md`
- `data-surface.md`
- `events-surface.md`

### Step 3：生成基础设施与可观测性证据
按顺序调用：
1. `architecture-analyzer`
2. `code-index`
3. `repomix`

产出：
- `infra-surface.md`
- `obs-surface.md`

### Step 4：生成架构知识库
按 `resources/templates/architecture/` 输出：
- `README.md`
- `00~12`
- `modules/<模块>.md`
- `09-ADR/*`

要求：
- 每个主章节都有“证据来源”段落
- 每个模块页都有：
  - 职责与边界
  - 代码位置
  - Inbound / Outbound
  - 时序图
  - 一致性 / 可靠性
  - 可观测性
  - 变更影响与回滚

### Step 5：生成图表
- 用 `mcp-mermaid` 生成 Mermaid 图
- Mermaid 不适用时再用 `plantuml`

### Step 6：更新文档站导航
执行：
- `node scripts/gen-sidebar.mjs`
或
- `npm run docs:gen-sidebar`

### Step 7：自检（必须）
输出至少 10 条：
- 遗漏
- 风险
- 假设
- 需验证点

然后修订为 v1。

## Token 控制规则（严格）
- 禁止读取整仓库全文
- 禁止长段粘贴大文件
- 优先：索引 / 图谱 / 命中行 / 摘要
- `repomix` 只在跨文件上下文过大时使用
- 单文件引用只截取必要片段

## 适合 Codex CLI 的使用方式
- 先让 Codex 加载本 Skill
- 再读仓库中的 `AGENTS.md`（若存在）
- 按 MCP 优先级逐层抽取证据
- 最后生成文档
