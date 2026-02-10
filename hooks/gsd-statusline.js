#!/usr/bin/env node
// Claude Code Statusline - GSD Team Edition
// Line 1: model | agent/task | directory | context bar
// Line 2: team agents status (when team is active)

const fs = require('fs');
const path = require('path');
const os = require('os');

const homeDir = os.homedir();

// ── Colors ──
const C = {
  dim: '\x1b[2m',
  bold: '\x1b[1m',
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  orange: '\x1b[38;5;208m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
  magenta: '\x1b[35m',
  blink: '\x1b[5m',
  gray: '\x1b[90m',
};

// ── Read stdin JSON ──
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const lines = [];

    // ═══════════════════════════════════════════
    // LINE 1: Model │ Task │ Dir │ Context Bar
    // ═══════════════════════════════════════════

    const model = data.model?.display_name || 'Claude';
    const dir = path.basename(data.workspace?.current_dir || process.cwd());
    const session = data.session_id || '';

    // Context window bar
    const remaining = data.context_window?.remaining_percentage;
    let ctxBar = '';
    if (remaining != null) {
      const rawUsed = Math.max(0, Math.min(100, 100 - Math.round(remaining)));
      const used = Math.min(100, Math.round((rawUsed / 80) * 100));
      const filled = Math.floor(used / 10);
      const bar = '█'.repeat(filled) + '░'.repeat(10 - filled);

      // Color by GSD Quality Degradation Curve: 0-30% PEAK, 30-50% GOOD, 50-70% DEGRADING, 70%+ POOR
      let color;
      if (used < 38) color = C.green;        // PEAK (0-30% raw)
      else if (used < 63) color = C.yellow;  // GOOD (30-50% raw)
      else if (used < 88) color = C.orange;  // DEGRADING (50-70% raw)
      else color = C.blink + C.red;          // POOR (70%+ raw)

      // Token count
      const windowSize = data.context_window?.context_window_size;
      let tokenInfo = '';
      if (windowSize) {
        const usedTokens = Math.round(windowSize * rawUsed / 100);
        tokenInfo = ` ${formatTokens(usedTokens)}/${formatTokens(windowSize)}`;
      }

      ctxBar = ` ${color}${bar} ${used}%${tokenInfo}${C.reset}`;
    }

    // Current task from todos
    let taskInfo = '';
    const todosDir = path.join(homeDir, '.claude', 'todos');
    if (session && fs.existsSync(todosDir)) {
      try {
        const files = fs.readdirSync(todosDir)
          .filter(f => f.startsWith(session) && f.includes('-agent-') && f.endsWith('.json'))
          .map(f => ({ name: f, mtime: fs.statSync(path.join(todosDir, f)).mtime }))
          .sort((a, b) => b.mtime - a.mtime);

        if (files.length > 0) {
          const todos = JSON.parse(fs.readFileSync(path.join(todosDir, files[0].name), 'utf8'));
          if (Array.isArray(todos) && todos.length > 0) {
            const inProgress = todos.find(t => t.status === 'in_progress');
            const completed = todos.filter(t => t.status === 'completed').length;
            const total = todos.length;
            const pct = total > 0 ? Math.round((completed / total) * 100) : 0;

            if (inProgress) {
              const label = inProgress.activeForm || inProgress.content || '';
              const short = label.length > 30 ? label.slice(0, 28) + '..' : label;
              taskInfo = ` ${C.bold}${short}${C.reset} ${C.dim}[${completed}/${total} ${pct}%]${C.reset}`;
            } else if (completed > 0) {
              taskInfo = ` ${C.green}${completed}/${total} done${C.reset}`;
            }
          }
        }
      } catch (e) {}
    }

    // GSD update indicator
    let gsdUpdate = '';
    const cacheFile = path.join(homeDir, '.claude', 'cache', 'gsd-update-check.json');
    if (fs.existsSync(cacheFile)) {
      try {
        const cache = JSON.parse(fs.readFileSync(cacheFile, 'utf8'));
        if (cache.update_available) gsdUpdate = `${C.yellow}⬆${C.reset} `;
      } catch (e) {}
    }

    // Token usage (cumulative session totals)
    let usage = '';
    const totalIn = data.context_window?.total_input_tokens;
    const totalOut = data.context_window?.total_output_tokens;
    if (totalIn || totalOut) {
      const inStr = formatTokens(totalIn || 0);
      const outStr = formatTokens(totalOut || 0);
      usage = ` ${C.dim}in:${inStr} out:${outStr}${C.reset}`;
    }

    // Cost & duration
    let cost = '';
    if (data.cost?.total_cost_usd) {
      const usd = data.cost.total_cost_usd.toFixed(2);
      const dur = data.cost.total_duration_ms;
      const durStr = dur ? ` ${formatDuration(dur)}` : '';
      cost = ` ${C.dim}$${usd}${durStr}${C.reset}`;
    }

    lines.push(`${gsdUpdate}${C.dim}${model}${C.reset} │${taskInfo} ${C.dim}${dir}${C.reset}${ctxBar}${usage}${cost}`);

    // ═══════════════════════════════════════════
    // LINE 2: Team agents (when team is active)
    // ═══════════════════════════════════════════

    const teamLine = getTeamStatus(session);
    if (teamLine) lines.push(teamLine);

    process.stdout.write(lines.join('\n'));
  } catch (e) {
    // Silent fail
  }
});

// ── Helpers ──

function formatTokens(n) {
  if (n >= 1000000) return (n / 1000000).toFixed(1) + 'M';
  if (n >= 1000) return Math.round(n / 1000) + 'k';
  return String(n);
}

function formatDuration(ms) {
  const s = Math.floor(ms / 1000);
  if (s < 60) return `${s}s`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m${s % 60}s`;
  const h = Math.floor(m / 60);
  return `${h}h${m % 60}m`;
}

function getTeamStatus(session) {
  if (!session) return null;

  // Check for active team by looking for task files in any team directory
  const tasksBase = path.join(homeDir, '.claude', 'tasks');
  const teamsBase = path.join(homeDir, '.claude', 'teams');

  if (!fs.existsSync(teamsBase)) return null;

  // Find active teams with config.json containing members
  try {
    const teamDirs = fs.readdirSync(teamsBase).filter(d => {
      const configPath = path.join(teamsBase, d, 'config.json');
      return fs.existsSync(configPath);
    });

    if (teamDirs.length === 0) return null;

    const agents = [];
    for (const teamDir of teamDirs) {
      const configPath = path.join(teamsBase, teamDir, 'config.json');
      try {
        const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        if (!config.members || !Array.isArray(config.members)) continue;

        for (const member of config.members) {
          if (member.name === 'team-lead') continue; // skip leader
          agents.push({
            name: member.name || '?',
            type: member.agentType || '',
            team: teamDir,
          });
        }
      } catch (e) {}
    }

    if (agents.length === 0) return null;

    // Look for task progress per team
    let taskInfo = '';
    for (const teamDir of teamDirs) {
      const taskDir = path.join(tasksBase, teamDir);
      if (!fs.existsSync(taskDir)) continue;
      try {
        const taskFiles = fs.readdirSync(taskDir).filter(f => f.endsWith('.json') && !f.startsWith('.'));
        for (const tf of taskFiles) {
          const tasks = JSON.parse(fs.readFileSync(path.join(taskDir, tf), 'utf8'));
          if (Array.isArray(tasks) && tasks.length > 0) {
            const completed = tasks.filter(t => t.status === 'completed').length;
            const inProg = tasks.filter(t => t.status === 'in_progress').length;
            const total = tasks.length;
            if (total > 0) {
              const pct = Math.round((completed / total) * 100);
              taskInfo = ` ${C.dim}tasks: ${completed}/${total} (${pct}%)${C.reset}`;
            }
          }
        }
      } catch (e) {}
    }

    // Format agents
    const agentParts = agents.map(a => {
      const icon = getAgentIcon(a.name);
      return `${icon}${C.cyan}${a.name}${C.reset}`;
    });

    return `${C.dim}team:${C.reset} ${agentParts.join(` ${C.dim}│${C.reset} `)}${taskInfo}`;
  } catch (e) {
    return null;
  }
}

function getAgentIcon(name) {
  if (name.includes('executor')) return '⚡';
  if (name.includes('planner')) return '📋';
  if (name.includes('verifier')) return '✓ ';
  if (name.includes('debugger')) return '🔍';
  if (name.includes('researcher')) return '🔬';
  if (name.includes('checker')) return '☑ ';
  if (name.includes('mapper')) return '🗺 ';
  return '● ';
}
