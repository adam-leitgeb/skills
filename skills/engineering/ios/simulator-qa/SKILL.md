---
name: simulator-qa
description: QA a built feature by driving the real app in iOS simulators and Android emulators, fanning the clicking-through out to cheap sub-agents while the main agent plans the checks and verifies every failure. Invoked explicitly as /simulator-qa <what to test>. For KMP, iOS and Android apps. Not a replacement for unit or UI tests; it's the manual pass before calling a feature done.
argument-hint: "<ticket, flow, PR or plain description of what was built>"
disable-model-invocation: true
---

QA the feature the way a tester would, on every platform it ships on. You plan the checks
and judge the results; cheap sub-agents do the tapping, where almost all the tokens go.

Run sub-agents on the **cheapest model tier the harness offers**. Without model choice,
use sub-agents anyway to keep screenshots and dumps out of your context. Without
sub-agents, run the checks yourself. Cheap models follow instructions literally and
improvise badly, so give them nothing to decide.

Never fix code during the run. Report, and let the person decide.

## Setup

Read `docs/qa-setup.md` in the project (outside this skill, so the sync keeps it). If
it's missing or incomplete, fill what the build files answer, ask for the rest, and write
it. It holds:

- build commands and artifact paths per platform, bundle id and application id
- the base simulator and AVD, the clones kept for parallel runs, and a device count that
  runs cleanly
- test accounts, ideally one per agent (where the credentials live, never the credentials
  themselves), and the deep links to each flow
- the backend environment, and how to seed or reset data
- known noise: things that look like bugs and aren't

## 1. Understand

Read the argument, the ticket or spec it points to, and the diff (`git diff main...HEAD`
or the PR). Collect the screens and entry points, every recorded decision, every API
error the client handles, the states the model allows (empty, error, many, very long),
and the behaviour the ticket says is deliberate.

## 2. Build

Have a cheap sub-agent per platform, in parallel, run the build and report the artifact
path or the first error with ten lines of context. A failed build ends the run.

## 3. Write the checks

Each check is a card a model with no context can run:

```markdown
### C3 — Save with an empty name shows the inline error   [ios, android]
Start: logged in, on Settings > Profile (deep link: app://settings/profile)
Steps:
1. Clear the "Name" field.
2. Tap "Save".
Expect:
- Text "Name can't be empty" is visible below the Name field.
- The "Save" button is still visible.
Evidence: screenshot after step 2.
```

- **Expectations are observable**: exact text, element present or absent, which screen is
  on top. Visual judgment goes in *Evidence*, and you do it in triage.
- **Elements are named as the device shows them**: visible label or accessibility id.
- **Each card sets up its own start state** and never relies on another card.
- **Beyond the happy path**: one card per decision, reachable API errors, empty and
  overflow states, back mid-flow, kill and relaunch, dark mode and the largest text size
  for new UI, offline for network features.

Show the person the card titles first if they're around.

## 4. Prepare devices and dispatch

One sub-agent per device, all in parallel. Split iOS from Android first, then add devices
per platform as the plan needs.

**Split the cards** into three to six per agent. Cards that depend on each other stay in
one agent. Agents sharing an account interfere, so give each its own. With one account,
put every card that changes server data in a single agent.

**You prepare the devices**; sub-agents never create, boot or install anything.

1. Get one device per agent, reusing the clones in `docs/qa-setup.md` first.
   - iOS: `xcrun simctl clone <shut-down base udid> "QA <n>"`, then `xcrun simctl boot <udid>`.
   - Android: `emulator -avd <name> -read-only -no-snapshot-save -port <5554|5556|…> &`,
     then `adb -s emulator-<port> wait-for-device`.
2. Install the same build on each and apply the shared start state (permissions,
   onboarding).
3. Note every device you started. Cleanup touches only those.

If many cards come back BLOCKED or fail on timing, the machine is saturated. Re-run them
on fewer devices before believing them.

### The brief

The sub-agent sees nothing else, so the brief carries everything:

````markdown
You run manual QA checks on a <platform> <simulator|emulator>. You observe and report;
you never change code and never judge what's acceptable.

Device: <udid or serial>, yours alone. Use it in every command.
App: <bundle id / application id>, installed.
Screenshots: <absolute dir>/<card id>-<step>.png

<the matching platform section from "Driving the device">

Rules:
- Read the screen with the UI dump, not screenshots. Screenshot where a card asks, and
  on every failure.
- Find each element in the dump before tapping; dump again after to confirm the change.
- Element not found after two dumps with a scroll between: mark the card BLOCKED. Never
  guess coordinates or try another route.
- App crashed: mark FAIL, save the crash log, relaunch, continue.
- Quote on-screen text verbatim.

Checks:
<the cards, in full>

Reply with one block per card:
C<n>: PASS | FAIL | BLOCKED
Observed: <verbatim, per Expect line>
Evidence: <screenshot paths>
Notes: <only if something unexpected happened>
````

## Driving the device

### iOS: `xcrun simctl` + AXe

```sh
xcrun simctl install <udid> <App.app>
xcrun simctl launch --terminate-running-process <udid> <bundle-id>
xcrun simctl openurl <udid> "<deep link>"
xcrun simctl privacy <udid> grant <service> <bundle-id>
xcrun simctl ui <udid> appearance dark                     # light
xcrun simctl ui <udid> content_size accessibility-extra-extra-extra-large   # large

axe tap --label "Save" --wait-timeout 3 --udid <udid>      # or --id; --element-type Button if ambiguous
axe type 'text' --udid <udid>                              # US keyboard chars only
axe key 42 --udid <udid>                                   # backspace, once per char to clear (40 = return)
axe gesture scroll-down --udid <udid>
axe gesture swipe-from-left-edge --udid <udid>             # back
axe screenshot --output <path.png> --udid <udid>
xcrun simctl spawn <udid> log show --last 2m --predicate 'process == "<AppName>"' --style compact | tail -40   # crash log
```

UI dump, one line per element (center, label, id, type, value). Tap by coordinates only
when an element has no label or id:

```sh
axe describe-ui --udid <udid> | python3 -c '
import sys,json
def w(n):
  l,i,v=n.get("AXLabel"),n.get("AXUniqueId"),n.get("AXValue")
  if l or i or v:
    f=n["frame"]; x,y=f["x"]+f["width"]/2,f["y"]+f["height"]/2
    print(f"{x:.0f},{y:.0f}",repr(l or ""),i or "",n.get("type") or "",repr(v) if v else "","" if n.get("enabled",True) else "disabled")
  for c in n.get("children") or []: w(c)
for r in json.load(sys.stdin): w(r)
'
```

### Android: `adb`

If `adb` isn't on `PATH`: `$ANDROID_HOME/platform-tools/adb` or
`~/Library/Android/sdk/platform-tools/adb`.

```sh
adb -s <serial> install -r <app.apk>
adb -s <serial> shell am start -n <app-id>/<launcher activity>
adb -s <serial> shell am force-stop <app-id>
adb -s <serial> shell am start -a android.intent.action.VIEW -d "<deep link>" <app-id>
adb -s <serial> shell pm clear <app-id>
adb -s <serial> shell cmd uimode night yes                 # no
adb -s <serial> shell settings put system font_scale 2.0   # 1.0
adb -s <serial> shell input tap <x> <y>                    # center from the dump
adb -s <serial> shell input text 'hello%sworld'            # %s = space
adb -s <serial> shell input keyevent 4                     # back (67 backspace, 66 enter)
adb -s <serial> shell input swipe 540 1600 540 600         # scroll down
adb -s <serial> exec-out screencap -p > <path.png>
adb -s <serial> logcat -d -b crash | tail -40              # crash log
```

UI dump, one line per element (center, label, resource id, class, state):

```sh
adb -s <serial> exec-out uiautomator dump /dev/tty 2>/dev/null | python3 -c '
import sys,re,xml.etree.ElementTree as E
x=sys.stdin.read(); x=x[x.find("<"):x.rfind(">")+1]
for n in E.fromstring(x).iter("node"):
  t,d,i=n.get("text"),n.get("content-desc"),n.get("resource-id")
  if not(t or d or i): continue
  a,b,c,e=map(int,re.findall(r"\d+",n.get("bounds")))
  f=[k for k in("clickable","checked","focused","selected") if n.get(k)=="true"]+([] if n.get("enabled")=="true" else ["disabled"])
  print(f"{(a+c)//2},{(b+e)//2}",repr(t or d),i.split("/")[-1] if i else "",n.get("class").split(".")[-1]," ".join(f))
'
```

Compose `testTag`s show up as resource ids only with
`Modifier.semantics { testTagsAsResourceId = true }` on the root.

## 5. Triage

Cheap models report false failures: taps before the screen settled, text read off the
wrong element. Never forward an unverified FAIL; one false bug costs more trust than
three missed ones. For each FAIL and BLOCKED:

1. Look at the screenshot.
2. Still unclear? Reproduce it yourself, or re-run that one card.
3. Find the cause in the code.
4. Classify it as a **bug**, a **wrong card** (fix the card), **noise** (listed in setup),
   or **flaky** (didn't reproduce twice). A BLOCKED card often means an unlabeled
   element, which is an accessibility finding.

Then judge every *Evidence* screenshot: clipped text, broken dark mode or large text, the
two platforms disagreeing.

## 6. Report and clean up

Write `tmp/qa/<yyyy-mm-dd>-<slug>/report.md` next to the screenshots, gitignoring `tmp/`
if needed, and give the person the summary.

```markdown
# QA: <feature> — <date>
Build: <branch @ sha>, <iOS device + OS>, <Android device + API>

## Bugs
### <Declarative title>   [ios | android | both]
Steps / Expected / Actual / Evidence / Cause (file:line)

## Accessibility and visual
## Flaky
## Passed
## Not covered
<what wasn't checked, and why>
```

*Not covered* is mandatory. A report that looks complete when it isn't is worse than a
short honest one.

Shut down only the devices you started (`xcrun simctl shutdown <udid>`,
`adb -s <serial> emu kill`). Keep clones and list them in `docs/qa-setup.md`.
