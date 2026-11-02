# Sound Blaster AE-7 on Linux: Tsi381 MSI4 playback experiment

**Status: working on one machine; experimental and NOT an upstream-ready or universal driver.**

On Kubuntu 26.10 (kernel `7.3.0-10-generic`), a Creative Sound Blaster AE-7 detected successfully with stock `snd_hda_intel` but analog stereo fell silent after a few seconds (~10–30 s), often recovering temporarily after codec reconfiguration. A custom HDA driver using bridge-generated **MSI vector 4**, an AE-7-specific **BDL position adjustment of 64** and an AE-7-only **PipeWire IRQ-scheduling rule** passed a 170-second audible test and then a separate installed 40-second test. The owner subsequently reported **several hours of normal music with no dropouts**.

**This is the older Tsi381 bridge (`10e3:8111`), not the ASM1083/1085 bridge in other AE-7 projects.** It is a distinct symptom and likely distinct mechanism.

## Hardware and software (only one tested host)

| Component | Observed |
|---|---|
| Creative PCI ID | `1102:0010`, subsystem `1102:0081` |
| Tsi381 bridge | `10e3:8111`, PCI `0000:07:00.0` |
| Creative audio device | PCI `0000:08:00.0` |
| OS / kernel | Kubuntu 26.10, Ubuntu `7.3.0-10-generic` |
| Audio stack | PipeWire 1.6.8, WirePlumber 0.5.17 |
| Playback exercised | S32_LE stereo, 48 kHz, analog line out |
| Stock driver srcversion | `8F8DDE9A080683D506B4FD2` |
| Installed V77 srcversion | `5BA4F589F7B557BEBCCCDA3` |

## Technical summary

The experiment changes `snd_hda_intel` to prepare eight MSI vectors on the Tsi381 **after** Creative codec registration, redirecting INTA to **MSI4 (the fifth allocated vector)**. One observed allocation had base IRQ 94 but audio IRQ **98**; using the bridge's `/sys/.../irq` value alone is misleading. For the exact card with an auto-selected 32-frame BDL offset, the driver sets `bdl_pos_adj=64`. Userspace PipeWire is configured to request period interrupts on only the Creative analog stereo node using `api.alsa.disable-tsched=true`.

The patch currently has a **host-specific PCI bus-number guard** and extensive debug instrumentation, and contains opt-in experimental fallback diagnostics (not enabled during the successful runs). It must be cleaned and reviewed before mainstream inclusion. **Do not install it unmodified on another host, distribution, or kernel.**

## Reproducible sources

- [Experimental V77 patch from *the exact Ubuntu source package*](patches/experimental-v77-from-ubuntu-7.3.0-10.patch). Baseline: Ubuntu `linux-source-7.3.0_7.3.0-10.10_all.deb`, `sound/hda/controllers/intel.c` SHA256 `ebc82a65f64864a88527e23604e0f3685e8bd646871698b5d78277655e2733f9`.
- Patched V77 `intel.c` SHA256 `7ce243c4c80d855f3523fa526a146ff6a280f81cd03f9ef9afcde9222c23aa8e`. V77 unsigned test module SHA256 `75fd255a8cc27558957c5a519e5a8882840e7d8d1bcf81a94f5e`; no binary is distributed.
- [Exact-node WirePlumber configuration](wireplumber/81-ae7-msi4-irq-scheduling.conf).
- [Measurements](docs/measurements.md), [engineering analysis](docs/engineering.md), [safety limits](docs/limitations.md), and [ALSA upstream report draft](docs/upstream-handoff.md).

This is a **historical reproduction patch**, not a minimal upstream proposal. It reproduces the locally installed driver source but the minimal viable code path has not been separated or retested.

## Reproduction / safety

Verify the patch without touching hardware: `scripts/verify-patch.sh /path/to/linux-source-7.3.0`. It refuses unexpected base source SHA and confirms the patched SHA. No automatic install script, kernel module, firmware, Secure Boot key, or personal diagnostic archive is published.

Experimental bridge-level interrupt programming can cause system hangs or disrupt other PCI devices. The working V77 install is per-kernel, Secure Boot signed locally with an enrolled MOK, and has **not** been reboot-tested or tested for suspend/resume, another PCI topology, another AE-7 revision, or surround output. No "Creative Direct Mode" parity claim is made.

## Upstream and other projects

- [craciunoiuc/sound-blaster-ae7-linux](https://github.com/craciunoiuc/sound-blaster-ae7-linux) primarily covers the **ASMedia bridge boot-hang** problem; its README says stock drivers work with Tsi381, but this single machine shows reproducible Tsi381 playback dropouts with stock HDA.
- [robshort2000/sound-blaster-ae7-linux](https://github.com/robshort2000/sound-blaster-ae7-linux) covers related AE-7 initialization issues on another setup.
- ALSA upstream submissions are handled through **linux-sound@vger.kernel.org**, not via a PR to the Linux GitHub mirror. Our evidence should be discussed before submitting a general kernel patch; see [upstream handoff](docs/upstream-handoff.md).

**Licensing:** the patch retains the original Linux source's GPL-2.0-or-later license. Original material here is GPL-2.0-or-later. **AI assistance:** developed and analyzed using ChatGPT (GPT-6). The human contributor must review code and provide their own DCO sign-off; no `Signed-off-by` is invented.
