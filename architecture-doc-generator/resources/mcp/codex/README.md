# Codex CLI 使用建议

## 推荐调用顺序
1. architecture-analyzer
2. codegraph
3. code-index
4. repomix（仅在需要跨文件摘要时）
5. context7（仅查外部官方文档）
6. doc-generator（基于证据包生成初稿）
7. mcp-mermaid / plantuml（画图）

## 不建议
- 一上来就把 repomix 全量输出塞进上下文
- 直接把整仓库文件长段贴给模型
