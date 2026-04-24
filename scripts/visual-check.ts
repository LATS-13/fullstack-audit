#!/usr/bin/env node
/**
 * visual-check.ts — Playwright: capturas + console errors + overflow detection
 *
 * Uso:
 *   npx tsx visual-check.ts \
 *     --base http://localhost:3000 \
 *     --routes routes.json \
 *     --output ./out/
 *
 * routes.json:
 * [
 *   { "name": "dashboard", "url": "/", "auth": "admin" },
 *   { "name": "ventas-mes", "url": "/ventas?periodo=mes", "auth": "admin" }
 * ]
 *
 * Auth: si es "admin" o "portal", busca scripts/auth-<name>.ts y lo ejecuta antes.
 *       Si null/undefined, no autentica.
 *
 * Breakpoints: mobile (375x812), tablet (768x1024), desktop (1280x800).
 */
import { chromium, Browser, Page, BrowserContext } from 'playwright'
import * as fs from 'fs'
import * as path from 'path'

interface Route {
  name: string
  url: string
  auth?: 'admin' | 'portal' | null
  waitFor?: string  // selector opcional
}

interface RouteResult {
  name: string
  url: string
  breakpoint: string
  screenshot: string
  consoleErrors: string[]
  networkFailures: { url: string, status: number }[]
  overflowHorizontal: boolean
  smallTouchTargets: number
}

const BREAKPOINTS = [
  { name: 'mobile', width: 375, height: 812 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1280, height: 800 },
]

function parseArgs(): { base: string, routes: string, output: string } {
  const args = process.argv.slice(2)
  const out: any = {}
  for (let i = 0; i < args.length; i += 2) {
    const k = args[i].replace(/^--/, '')
    out[k] = args[i + 1]
  }
  if (!out.base || !out.routes || !out.output) {
    console.error('Uso: visual-check --base URL --routes JSON --output DIR')
    process.exit(1)
  }
  return out
}

async function authenticate(context: BrowserContext, kind: string, base: string) {
  // Stub. Cada proyecto sobreescribe esto creando scripts/auth-<kind>.ts
  // que exporte default async (context, base) => { ... }
  const authFile = path.join(__dirname, `auth-${kind}.ts`)
  if (fs.existsSync(authFile)) {
    const mod = await import(authFile)
    await mod.default(context, base)
  } else {
    console.warn(`[warn] auth-${kind}.ts no encontrado — sin autenticar`)
  }
}

async function captureRoute(
  browser: Browser,
  base: string,
  route: Route,
  bp: typeof BREAKPOINTS[number],
  outDir: string,
): Promise<RouteResult> {
  const context = await browser.newContext({ viewport: { width: bp.width, height: bp.height } })
  const consoleErrors: string[] = []
  const networkFailures: { url: string, status: number }[] = []

  if (route.auth) await authenticate(context, route.auth, base)

  const page = await context.newPage()
  page.on('console', msg => {
    if (msg.type() === 'error') consoleErrors.push(msg.text())
  })
  page.on('response', resp => {
    if (resp.status() >= 400) networkFailures.push({ url: resp.url(), status: resp.status() })
  })
  page.on('pageerror', err => consoleErrors.push(`PAGE_ERROR: ${err.message}`))

  try {
    await page.goto(`${base}${route.url}`, { waitUntil: 'networkidle', timeout: 30000 })
    if (route.waitFor) await page.waitForSelector(route.waitFor, { timeout: 10000 })
    await page.waitForTimeout(1000)  // animaciones
  } catch (err: any) {
    consoleErrors.push(`NAV_ERROR: ${err.message}`)
  }

  const screenshot = path.join(outDir, `${route.name}-${bp.name}.png`)
  try {
    await page.screenshot({ path: screenshot, fullPage: true })
  } catch (err: any) {
    consoleErrors.push(`SCREENSHOT_ERROR: ${err.message}`)
  }

  const overflowHorizontal = await page.evaluate(() =>
    document.documentElement.scrollWidth > window.innerWidth + 1
  ).catch(() => false)

  const smallTouchTargets = bp.width <= 480 ? await page.evaluate(() => {
    const els = Array.from(document.querySelectorAll('button, a, [role="button"], input[type="submit"]'))
    return els.filter(el => {
      const r = el.getBoundingClientRect()
      return r.width > 0 && r.height > 0 && (r.width < 44 || r.height < 44)
    }).length
  }).catch(() => 0) : 0

  await context.close()
  return {
    name: route.name,
    url: route.url,
    breakpoint: bp.name,
    screenshot,
    consoleErrors,
    networkFailures,
    overflowHorizontal,
    smallTouchTargets,
  }
}

async function main() {
  const { base, routes: routesFile, output } = parseArgs()
  fs.mkdirSync(output, { recursive: true })

  const routes: Route[] = JSON.parse(fs.readFileSync(routesFile, 'utf-8'))
  const browser = await chromium.launch()
  const results: RouteResult[] = []

  for (const route of routes) {
    for (const bp of BREAKPOINTS) {
      console.log(`→ ${route.name} (${bp.name})`)
      const r = await captureRoute(browser, base, route, bp, output)
      results.push(r)
    }
  }

  await browser.close()

  // Markdown report
  const md: string[] = []
  md.push(`# Visual check — ${new Date().toISOString()}`)
  md.push('')
  md.push(`Base: \`${base}\``)
  md.push('')
  md.push('| Ruta | Breakpoint | Console errors | Network 4xx/5xx | Overflow X | Touch <44px |')
  md.push('|------|------------|----------------|-----------------|------------|-------------|')
  for (const r of results) {
    md.push(`| ${r.name} | ${r.breakpoint} | ${r.consoleErrors.length} | ${r.networkFailures.length} | ${r.overflowHorizontal ? '❌' : '✅'} | ${r.smallTouchTargets} |`)
  }
  md.push('')
  for (const r of results) {
    if (r.consoleErrors.length || r.networkFailures.length || r.overflowHorizontal || r.smallTouchTargets > 0) {
      md.push(`## ${r.name} — ${r.breakpoint}`)
      md.push(`![](${path.basename(r.screenshot)})`)
      if (r.consoleErrors.length) {
        md.push('### Console errors')
        for (const e of r.consoleErrors) md.push(`- ${e}`)
      }
      if (r.networkFailures.length) {
        md.push('### Network failures')
        for (const f of r.networkFailures) md.push(`- ${f.status} ${f.url}`)
      }
      if (r.overflowHorizontal) md.push('### ❌ Overflow horizontal detectado')
      if (r.smallTouchTargets > 0) md.push(`### ⚠️ ${r.smallTouchTargets} elementos clickables <44px`)
      md.push('')
    }
  }

  fs.writeFileSync(path.join(output, '07-visual.md'), md.join('\n'))
  console.log(`OK → ${output}`)
}

main().catch(err => { console.error(err); process.exit(1) })
