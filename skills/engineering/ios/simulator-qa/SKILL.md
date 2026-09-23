---
name: simulator-qa
description: QA what was just implemented by driving the app in iOS simulators and Android emulators through cheap sub-agents, then fix and retest. Invoked explicitly as /simulator-qa.
argument-hint: "<what to test, if not obvious from the session>"
disable-model-invocation: true
---

QA what we just implemented, in the simulators of every platform it ships on.

1. Work out what to test from the session and the diff: the happy path, then the edge
   cases and error states worth checking.
2. Spawn sub-agents on the cheapest model tier the harness offers to click through the
   checks and report back pass/fail with screenshots. Give each one everything it needs;
   it sees nothing of this session. Drive iOS with `xcrun simctl` + `axe`, Android with
   `adb`, reading the screen from the accessibility tree rather than screenshots.
3. Run them in parallel, one simulator per sub-agent, unless the checks would interfere
   through the backend (shared account or data one changes and another reads). Keep those
   in one agent. Boot and install the simulators yourself before spawning, and shut down
   the ones you started afterwards.
4. Verify each reported failure yourself before believing it, fix the real ones, and
   retest until it passes.
5. Report what passed, what you fixed, and what you didn't cover.
