import { defineConfig } from 'vitepress'
import { sidebar } from './sidebar.generated'

export default defineConfig({
  title: '项目技术文档',
  description: '架构知识库 + 项目知识库（本地部署）',
  themeConfig: {
    nav: [
      { text: '架构文档', link: '/architecture/' },
      { text: '项目知识库', link: '/kb/' }
    ],
    sidebar,
    search: {
      provider: 'local'
    }
  }
})
