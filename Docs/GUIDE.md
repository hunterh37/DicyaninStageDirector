# How to record a demo video with DicyaninStageDirector

## 1. Add the package and one route

Add the package (see README) and attach `.director(DemoRoutes.register)` to the first window's root view inside `#if DEBUG`. Write one route that reaches the moment you want to film.

A route sets state directly. It does not tap through menus. A typical route:

1. Sets the app model (phase, level, step index, selected item).
2. Opens the immersive space or window with `take.openImmersive(id)` / `take.openWindow(id)`.
3. Builds or finds entities and frames them (`take.param("yaw", default: 0)` on the content root).
4. Calls `await take.ready()`. The recorder starts here.
5. Plays the moment, marking beats with `take.cue("name")`.
6. Calls `take.done()`. The recorder stops after the tail.

## 2. Organize routes for deep scenes

Group by app area so nested content has a readable path:

```swift
b.group("campaign") { b in
    b.group("mission3") { b in
        b.route("ufo-landing", "UFO lands in the yard", duration: 12, tags: ["cinematic"]) { t in ... }
        b.route("boss-intro", "Boss reveal", duration: 8, tags: ["cinematic"]) { t in ... }
    }
}
```

`-Route ufo-landing` resolves by suffix when the name is unique.

Wrap existing per-app directors (ShotDirector, DemoDirector, autoplay drivers) in a route instead of rewriting them.

## 3. Make takes repeatable

- Draw random values from `take.rng` (`Float.random(in: 0...1, using: &take.rng)`).
- Systems check `Director.shared.isFrozen` and skip `update` after `take.freeze()`.
- Views check `Director.shared.isDirecting` to hide FPS counters, onboarding, permission prompts.
- Stub hand and head tracking with scripted poses where the scene depends on them.

## 4. Find entity paths without reading code

```swift
Director.shared.dumpTree(root, depth: 6)
```

Read `Caches/director/scene-tree.txt`. Nodes with baked animations show `[anims:N]`. Use the names with `root.entity(at: "Kitchen/Stove/Pan")`.

## 5. RealityHD scenes

One route per `RealScene.Spot` and per articulation state:

```swift
for state in saw.articulationStates {
    b.route("woodshop/table-saw/\(state)") { t in
        await t.openImmersive("shop"); await t.ready()
        saw.setArticulation(state, animated: true)
        await t.wait(4); t.done()
    }
}
```

## 6. Record

With the Claude Code skill `vision-record-demo`:

```bash
bash ~/.claude/skills/vision-record-demo/scripts/record.sh demo/takes.json
```

`demo/takes.json`:

```json
{ "bundleId": "com.x.app", "scheme": "App", "tailSeconds": 1, "timeoutSeconds": 60,
  "takes": [ { "id": "01-flambe", "route": "kitchen/stove/flambe", "duration": 10, "seed": 7 } ] }
```

The script uses a dedicated simulator named `Director-AVP`, boots it headless, builds Debug, installs, launches each take, records H.264 between `ready` and `done`, and writes `demo/raw/<id>.mp4` plus `<id>.cues.json`. `ONLY=<id>` re-records one take; `SKIP_BUILD=1` skips the build; `LIST=1` prints `routes.json`.

Without the skill, the same loop by hand:

```bash
xcrun simctl launch --terminate-running-process $UDID $BID -Route kitchen/stove/flambe -Take t1
# wait for $DATA/Library/Caches/director/t1.ready
xcrun simctl io $UDID recordVideo --codec=h264 --force "$PWD/t1.mp4" & REC=$!
# wait for t1.done
kill -INT $REC
```

Use absolute output paths with `recordVideo` and stop it with SIGINT so the file is finalized.

## 7. Simulator camera

The simulator camera sits at the immersive-space origin at standing eye height, facing -Z. Frame shots by moving the content root through route params. Do not move the simulator camera.
