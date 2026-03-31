# reference.md

## 1. 适用场景
该 Skill 适合：
- 单体项目
- 微服务项目
- Monorepo
- 前后端混合仓库
- 有或没有基础设施清单的仓库

## 2. 你当前已安装的 MCP 建议分工

### architecture-analyzer-mcp
最适合：
- 初步识别系统边界
- 推断服务边界与技术层次
- 生成架构草图

### codebase-memory-mcp（codegraph）
最适合：
- 代码图谱
- 模块调用关系
- 入口点与依赖边

### code-index-mcp
最适合：
- 查 Controller / Router / Service / Repository
- 命中 topic / metrics / env var / schema
- 快速、低 token 检索

### repomix
最适合：
- 需要看“多个文件组合起来在做什么”时
- 压缩上下文，避免把源码整段放进上下文

### context7
最适合：
- 补充框架/库/标准的最新官方知识

### doc-generator-mcp
最适合：
- 基于证据包输出结构化初稿

### mcp-mermaid / plantuml
最适合：
- 生成图表
- 优先 Mermaid，备选 PlantUML

## 3. 推荐 package.json scripts
```json
{
  "scripts": {
    "docs:gen-sidebar": "node skills/architecture-doc-generator/scripts/gen-sidebar.mjs",
    "docs:dev": "npm run docs:gen-sidebar && vitepress dev docs",
    "docs:build": "npm run docs:gen-sidebar && vitepress build docs",
    "docs:preview": "vitepress preview docs"
  }
}
```

## 4. Evidence Pack 约束
- `*.json`：结构化、简洁
- `*.md`：可读摘要
- 每个文件最好 <= 200 行
- 必须记录证据来源
