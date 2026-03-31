#!/usr/bin/env node
import fs from 'node:fs'
import path from 'node:path'

const root = process.cwd()
const dir = path.join(root, 'docs', 'architecture', '.evidence')
fs.mkdirSync(dir, { recursive: true })

const files = {
  'repo-map.md': '# Repo Map\n\n',
  'stack.json': '{\n  "languages": [],\n  "frontend": [],\n  "backend": [],\n  "datastores": [],\n  "messaging": [],\n  "deployment": []\n}\n',
  'services.json': '[]\n',
  'entrypoints.json': '[]\n',
  'api-surface.md': '# API Surface\n\n',
  'data-surface.md': '# Data Surface\n\n',
  'events-surface.md': '# Events Surface\n\n',
  'infra-surface.md': '# Infra Surface\n\n',
  'obs-surface.md': '# Observability Surface\n\n',
  'open-questions.md': '# Open Questions\n\n'
}

for (const [name, content] of Object.entries(files)) {
  const file = path.join(dir, name)
  if (!fs.existsSync(file)) fs.writeFileSync(file, content, 'utf-8')
}
console.log('Initialized evidence pack:', dir)
