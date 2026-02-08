---
name: tgsd:shutdown
description: Gracefully shut down all active team agents and clean up
allowed-tools:
  - Read
  - Bash
  - Task
  - TeamDelete
  - TaskList
  - SendMessage
---

<objective>
Gracefully terminate all active TGSD team agents and clean up team resources.

Use when:
- You're done with a team session
- You want to switch from team mode back to solo GSD
- Something went wrong and you need a clean slate
</objective>

<process>

## 1. Find active teams

```bash
ls ~/.claude/teams/ 2>/dev/null | grep "tgsd-"
```

## 2. For each active TGSD team:

**2a. Check TaskList for incomplete tasks**

```
TaskList()
```

If tasks are still in_progress, warn the user:
```
Warning: {N} tasks still in progress. Shutting down will abandon them.
Continue? (y/n)
```

**2b. Send shutdown requests to all teammates**

Read team config to discover members:

```bash
cat ~/.claude/teams/tgsd-*/config.json 2>/dev/null
```

For each member:
```
SendMessage(type="shutdown_request", recipient="{member_name}", content="Session ending. Shutting down.")
```

Wait for shutdown responses.

**2c. Clean up team**

```
TeamDelete()
```

## 3. Report

```
---

TGSD > SHUTDOWN COMPLETE

Teams terminated: {N}
Agents shut down: {M}

Ready for solo mode: /gsd:progress
Ready for team mode: /tgsd:progress

---
```

</process>

<success_criteria>
- [ ] All active TGSD teams found
- [ ] User warned about in-progress tasks
- [ ] Shutdown requests sent to all teammates
- [ ] Teams deleted and resources cleaned up
</success_criteria>
