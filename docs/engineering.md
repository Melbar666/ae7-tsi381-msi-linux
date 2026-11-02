# Engineering findings and upstream work required

## Bridge and IRQ delivery

The original driver initialized CA0132 successfully, but output repeatedly fell silent after seconds. Our experimental HDA modifications allocate eight MSI vectors on the Tsi381 bridge after codec registration and route INTA to the fifth **MSI4** vector. The first allocated vector (e.g. IRQ94) is not the HDA vector (e.g. IRQ98). A successful MSI4 control change alone is insufficient: confirm HDA period completion counters and audible playback.

Auto-detected BDL position offset was 32; the experimental exact AE-7 match changed it to **64** (only when not explicitly overridden).

## PipeWire and ALSA period wakeups

Default PipeWire timer scheduling may program **zero** BDL descriptors with IOC, making a zero period-IRQ delta completely expected. A scoped WirePlumber rule `api.alsa.disable-tsched=true` made ALSA use `no_period_wakeup=0` and program three IOC BDL entries for the tested playback. Our V75 test observed that true IOC-enabled playback could *still* stop after eight HDA completions. V76 and V77 subsequently ran normally. This variability should remain explicit in technical discussion.

## Upstream blockers

1. Replace hard-coded host PCI bus/address guard (`bus == 8`) with correct device-to-bridge relationship matching.
2. Review allocation, ownership and release of **eight MSI vectors on another PCI device**; IRQ sharing, bridge consumers, exception paths and races.
3. Audit suspend/resume, shutdown and hot-unplug, module removal, late probe failure and interrupt transitions.
4. Remove/rework instrumented workqueue and experimental fallback to produce a minimal patch; validate the minimal build on hardware (removing diagnostic timing may change behavior).
5. Isolate MSI4/BDL64/PipeWire changes one at a time to determine the minimal required fix; test additional Tsi381 boards and Linux kernels.
6. Run current Linux `checkpatch.pl` and `get_maintainer.pl`; obtain maintainer review before claiming an upstream-ready patch.

**Causality is not established for a single component.** The stable tested *combination* is the real result.
