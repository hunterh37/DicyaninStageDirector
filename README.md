# DicyaninStageDirector

Launch-argument control surface for recording visionOS demo footage from a headless simulator. Apps register named routes that jump straight to any scene, phase or nested animation. A recorder script launches one route per take and films between the app's `ready` and `done` markers, so no one clicks through the Simulator.

Requirements: visionOS 2+, Swift 6 toolchain (Swift 5 language mode). Also builds on macOS 14 and iOS 17 for tests.

## Install

```swift
.package(url: "https://github.com/hunterh37/DicyaninStageDirector.git", from: "0.1.0")
```

XcodeGen:

```yaml
packages:
  DicyaninStageDirector:
    url: https://github.com/hunterh37/DicyaninStageDirector.git
    from: 0.1.0
```

## Usage

```swift
import DicyaninStageDirector

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
            #if DEBUG
                .director(DemoRoutes.register)
            #endif
        }
        ImmersiveSpace(id: "kitchen") { KitchenView() }
    }
}

#if DEBUG
enum DemoRoutes {
    @MainActor static func register(_ b: RouteBook) {
        b.group("kitchen") { b in
            b.route("stove/flambe", "Pan flambe burst", duration: 10, tags: ["fx"]) { take in
                AppModel.shared.phase = .cooking
                await take.openImmersive("kitchen")
                await take.ready()          // recorder starts
                take.cue("ignite")
                AppModel.shared.root?.entity(at: "Kitchen/Stove/Pan")?.playAllAnimations()
                await take.wait(6)
                take.done()                 // recorder stops after tail
            }
        }
    }
}
#endif
```

Run a take by hand:

```bash
xcrun simctl launch --terminate-running-process booted com.x.app \
  -Route kitchen/stove/flambe -Take 01-flambe -Seed 7 -P.yaw -30
```

## Launch arguments

| Argument | Effect |
|---|---|
| `-Route <path>` | Run a route. Exact path or unique suffix (`flambe`). |
| `-Take <id>` | Marker file name. Defaults to the path with `/` replaced by `-`. |
| `-Seed <n>` | Seed for `take.rng` (SplitMix64). |
| `-P.<key> <value>` | Route parameter, read with `take.param("key")`. |
| `-DirectorList YES` | Write `routes.json` and idle. |
| `-DirectorInbox YES` | Poll `inbox.json` for `{"route": "...", "take": "..."}` without relaunching. |

The director stays inactive unless one of these is present.

## Marker files

Written to `<app data>/Library/Caches/director/`:

| File | Written when |
|---|---|
| `routes.json` | On start. Path, summary, duration, tags for every route. |
| `<take>.ready` | `take.ready()`, 30 frames after the call. |
| `<take>.done` | `take.done()`, or after the route returns. |
| `<take>.cues.json` | Each `take.cue(name)`, as `[{name, t}]`. |
| `<take>.error` | Unknown route or thrown error. |
| `scene-tree.txt` | `Director.shared.dumpTree(root)`. |

## API

| Symbol | Purpose |
|---|---|
| `View.director(_:)` | Wires `openImmersiveSpace`, `dismissImmersiveSpace`, `openWindow`, `dismissWindow`, registers routes, starts. |
| `RouteBook.route / group / resolve / manifest` | Register and look up routes. |
| `Take.ready / cue / done / wait / waitFrames / freeze` | Take lifecycle. |
| `Take.openImmersive / dismissImmersive / openWindow / dismissWindow` | Scene actions. |
| `Director.shared.isDirecting` | True under director args. Hide debug chrome and onboarding. |
| `Director.shared.isFrozen` | True after `take.freeze()`. Systems skip simulation updates. |
| `Entity.entity(at:)` | Slash-path lookup by entity name. |
| `Entity.nameTree(depth:)` / `playAllAnimations(loop:)` | Inspect the tree, play baked animations. |

Guide: [Docs/GUIDE.md](Docs/GUIDE.md).

## License

MIT
