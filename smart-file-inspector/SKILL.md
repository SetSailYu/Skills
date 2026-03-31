---
name: smart-file-inspector
description: 低 Token 文件读取与分析（Win11 / PowerShell）。当需要读取/解析/对比日志、抓包、Markdown、代码或未知文件时使用；优先“先搜后读”，必要时用 fullscan 输出结构化摘要。
---

# smart-file-inspector（PowerShell 版，省 Token）

本 Skill 的目标是：**在 Codex CLI 中高频读取/分析文件，但尽量不把大段原文塞进上下文**。核心方法是：
- **inspect → autoquery → find → read_window（少量窗口）→ 总结**
- 需要“全文解析/统计/对比”时：**在本地脚本里 fullscan 全量扫描，输出结构化摘要 + 少量证据点**（而不是全文输出）。

---

## 约束与预算（Hard rules）
1. **禁止整文件 dump**（不要输出全文，不要输出超长 hex）。
2. 单步输出预算默认：**≤ 200 行 或 ≤ 20k 字符**（先到者为准）。
3. **先搜索再读取窗口**：优先定位命中，再读取命中附近窗口。
4. 对未知/无扩展名文件：先 `cdx_inspect.ps1` 判断 text/binary：
   - binary：只允许 **hash + head hex(256B) + strings(≤200行)**（在 `cdx_inspect` / `binary` 策略里做）。
5. 需要“全文分析”：必须用 `cdx_fullscan.ps1` / `cdx_httptrace_scan.ps1` / `cdx_code_scan.ps1` 输出**结构化**结果；如需证据，再用 `cdx_read_window.ps1` 取小窗补证。

---

## Profiles（策略化，自适应）
Profiles 不靠“绝对关键词表”，而是：
- `seed` 仅作弱提示（兜底）
- 主要依赖 `cdx_autoquery.ps1` 从文件内容中抽取高信息 token，再驱动 `cdx_find.ps1`

配置文件：`config/profiles.json`

---

## 推荐工作流

### A. 快速排查（单文件）
1) `scripts/cdx_inspect.ps1 <file>`（自动判 profile）
2) `scripts/cdx_autoquery.ps1 <file>`（抽 TopK tokens）
3) `scripts/cdx_find.ps1 <path-or-file> -Query "<t1|t2|...>" -MaxMatches 30`
4) 对“最相关的 3 条命中”分别：
   - `scripts/cdx_read_window.ps1 <file> <line>`
5) 输出必须包含三段：
   - Findings（结论/归纳）
   - Evidence（行号 + 片段）
   - Next actions（下一步要补的窗口/token/对比项）

### B. 全文解析/统计（文本文件）
1) `scripts/cdx_fullscan.ps1 <file> [-Query <pattern>]`
2) 若需要进一步证据：对 fullscan 返回的 `evidence[].line` 用 `cdx_read_window.ps1` 小窗读取
3) 输出：统计/分布/Top tokens/证据点 + 解释

### C. HTTP 抓包（全文结构化解析）
1) `scripts/cdx_httptrace_scan.ps1 <file>`
2) 只在必要时对关键行号用 `cdx_read_window.ps1`

### D. 代码文件（结构化摘要）
1) `scripts/cdx_code_scan.ps1 <file>`
2) 必要时用 `cdx_read_window.ps1` 读取定义/调用附近

### E. 两文件对比（省 Token）
1) `scripts/cdx_compare_meta.ps1 <A> <B>`（hash/大小/时间）
2) 两边各跑 fullscan/trace_scan/code_scan
3) 仅输出差异点清单；证据只引用少量窗口

---

## Scripts 一览
- `cdx_inspect.ps1`：判定 text/binary + 自动 profile + sha256
- `cdx_autoquery.ps1`：抽取高信息 token（自适应搜索）
- `cdx_find.ps1`：搜索命中（rg 优先，回退 Select-String）
- `cdx_read_window.ps1`：按行号读取窗口（硬预算）
- `cdx_sample.ps1`：头尾抽样
- `cdx_extract.ps1`：轻量 key/value 抽取（用于对比/聚合）
- `cdx_compare_meta.ps1`：文件元信息对比
- `cdx_fullscan.ps1`：通用全文扫描（统计 + 分布 + 证据）
- `cdx_httptrace_scan.ps1`：抓包全文解析（请求/状态码/Host/Set-Cookie）
- `cdx_code_scan.ps1`：代码结构扫描（class/method/usings/urls）

---
## 使用建议（对开发者）
- 遇到“大文件/频繁迭代”：优先 `fullscan/trace_scan/code_scan`，让脚本做全量遍历，Codex 只负责解释结果。
- 遇到“未知文件”：先 `inspect` 决策路径，避免 token 炸裂。
