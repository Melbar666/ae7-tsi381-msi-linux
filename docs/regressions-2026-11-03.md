# 2026-11-03: S3 and independent stream-completion regression

**Update to the original experimental report:** The owner reported uninterrupted music for several hours with the signed V77 driver on 2026-11-02. That **did not** establish stability after deep sleep or on subsequent short playback starts.

## Failure A — converter no longer programmed after S3

- The system entered deep S3 suspend 2026-11-02 20:41 CET and resumed 2026-11-03 07:52 CET.
- When silence was investigated later, the signed V77 HDA module and its eight bridge MSI vectors remained loaded, but interrupt vector 4 had no new events while PipeWire playback was running.
- A locally authorized **read-only** PCI examination found the Tsi381 vendor register `0x220 = 0` (INTA→MSI converter disabled), despite V77 having set it to `1` at initial probe. The MSI mask at `0x090` was `0xEF`; the pending status at `0x094` was zero.
- The immediate post-resume value was not sampled. Thus S3 resetting the converter is **strongly suspected**, but exact causality/timing remain unproved.
- A standalone userspace register-write attempt was correctly denied by Secure Boot kernel lockdown. No lockdown bypass was performed.

The V78 *candidate* extends V77 with a guarded restore of the vendor register in the system-resume callback. V78 **has not been successfully installed or tested across a real S3 cycle**.

## Failure B — stall with converter still enabled

On 2026-11-03 09:58 CET a signed V78 module loaded successfully, and `0x220=1` with eight MSI bridge vectors correctly registered. A scheduled 60-second PipeWire playback test failed: IRQs advanced +14 in its first five-second window, then +0 in the second.

Unlike Failure A, **the converter remained at `0x220=1` during six kernel samples**, with mask `0xEF`, pending `0`.

Observed while the HDA stream was running:

| Signal | Observed |
|---|---|
| `INTCTL` | `c0000010` (controller interrupt and stream 4 enabled) |
| Stream 4 `SD_CTL` | `0054001e` (RUN, interrupt-related controls enabled) |
| `SD_STS` | `00` in successive diagnostic reads |
| Stream 4 BDL | 15 entries, **3 IOC** |
| `no_period_wakeup` | `0` |
| `buffer_bytes / period_bytes` | `49152 / 16384` |
| 2.5–3ms LPIB advancement | 1128–1152 bytes across five samples |
| HDA `sd_complete` | **3 → 6 → 6 → 6 → 6 → 6** |

The DMA-position and WALLCLK movement proves the HDA engine was still advancing for those snapshots, but **period-completion interrupt evidence ceased**. This was previously observed in V75 too, before the S3 regression. These observations do not establish whether the missing interrupt originates in HDA status generation, a bridge edge-level transition, a lost acknowledgement or a race.

The V78-only addition is called from the **system resume path**, which was not invoked during the smoke test. This short-playback failure therefore does not directly test V78's new resume hook.

## Upgrade outcome

- The V78 installer reported `FAIL phase=smoke` and safely unloaded V78.
- The **previous signed V77 module** was restored and independently verified by source version `5BA4F589F7B557BEBCCCDA3`, original installed file SHA256 `95bb91cafc7a52d7cb89578d5ad5b3256b901fe37f6fd172efda136bbce5dea0`, and original current-kernel override selection.
- PipeWire/WirePlumber remained active with the AE-7 analog-stereo sink as default. **Audible playback after rollback has not been reconfirmed.** The later MSI4 IRQ counter increased irregularly (+57 over 5s, later +7 over 6s); these may include controller response IRQs and do not by themselves prove stream 4 period completion.
- The installer failed **before** rebuilding initramfs, so the V78 module was **not persisted**.
- No additional automatic driver swap, reboot or kernel-lockdown workaround was performed.

## Next investigation

Prioritize evidence for this sequence at the instant the audio stalls:
`BDL IOC → HDA SD_STS.BCIS → HDA INTSTS.S4 → physical PCI INTA → Tsi381 MSI pending/vector4 → HDA ISR → ALSA period_elapsed`.

Especially useful would be correlating **stream-4 BCIS, HDA INTSTS and PCI MSI4 deliveries** at the precise moment the timer-driven stream keeps moving but periods stop. Any later changes should keep the already proven S3-converter-loss condition separate from the shorter-lived IRQ-completion failure. Do not make a watchdog or force MSI reprogramming as a speculative fix.

### Reference

Tsi381 manufacturer's manual: [Renesas Tsi381 User Manual, §8 Interrupt Handling / §14 registers](https://www.renesas.com/document/man/tsi381-user-manual?language=en), including interrupt-to-MSI conversion at vendor register offset `0x220`.
