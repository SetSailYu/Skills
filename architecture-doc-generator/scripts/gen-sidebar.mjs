#!/usr/bin/env node
import fs from 'node:fs'
import path from 'node:path'

const root = process.cwd()
const docsDir = path.join(root, 'docs')
const outFile = path.join(docsDir, '.vitepress', 'sidebar.generated.ts')

function listMd(dir) {
  if (!fs.existsSync(dir)) return []
  const files = fs.readdirSync(dir, { withFileTypes: true })
  const out = []
  for (const f of files) {
    if (f.isDirectory()) continue
    if (!f.name.endsWith('.md')) continue
    out.push(f.name)
  }
  out.sort((a, b) => {
    const score = (x) => x.toLowerCase() === 'readme.md' ? -1000 : (parseInt(x, 10) || 0)
    return score(a) - score(b) || a.localeCompare(b, 'zh-Hans-CN')
  })
  return out
}

function mkItem(base, filename) {
  const name = filename.replace(/\.md$/, '')
  return { text: name, link: `/${base}/${name}` }
}

function listGroup(sub, label) {
  const dir = path.join(docsDir, 'kb', sub)
  const files = listMd(dir)
  if (!files.length) return null
  return {
    text: label,
    items: files.map(f => ({ text: f.replace(/\.md$/, ''), link: `/kb/${sub}/${f.replace(/\.md$/, '')}` }))
  }
}

const archDir = path.join(docsDir, 'architecture')
const kbDir = path.join(docsDir, 'kb')

const archItems = listMd(archDir).map(f => mkItem('architecture', f))
const kbGroups = [
  listGroup('memory', '记忆'),
  listGroup('tasks', '任务'),
  listGroup('plan', '总纲')
].filter(Boolean)
const fallbackKbItems = listMd(kbDir).map(f => mkItem('kb', f))

const sidebar = {
  '/architecture/': [
    { text: '系统架构', items: archItems }
  ],
  '/kb/': kbGroups.length
    ? kbGroups
    : [{ text: '项目知识库', items: fallbackKbItems }]
}

const content = `// 此文件由 skills/architecture-doc-generator/scripts/gen-sidebar.mjs 自动生成。请勿手写。
export const sidebar = ${JSON.stringify(sidebar, null, 2)} as const
`
fs.mkdirSync(path.dirname(outFile), { recursive: true })
fs.writeFileSync(outFile, content, 'utf-8')
console.log('Generated:', path.relative(root, outFile))
