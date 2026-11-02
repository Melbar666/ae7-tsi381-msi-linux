# Measurements — one Tsi381 AE-7 system

| Trial | Outcome |
|---|---|
| Stock Ubuntu HDA + default PipeWire | Initially audible; repeated silence after seconds |
| V75 + scoped PipeWire IRQ scheduling | `no_period_wakeup=0` and three IOC descriptors, but stream completions stopped after 8 |
| V76 + IRQ4 / BDL64 + alias-safe LPIB sampling | **170 seconds fully audible**; 34 consecutive five-second windows with stream IRQ activity |
| V77 installed | **40-second test passed**; several hours of music thereafter without audible dropouts |

**V76 170s test:** 48 kHz, stereo, 32-bit PCM; 49,152-byte ring, 16,384 bytes/period; three IOC-enabled BDL descriptors; `no_period_wakeup=0`. 34 windows had **+4,025 MSI4 interrupt counts** in aggregate. HDA `sd_complete` rose **98 → 3,986** with no observed DMA errors or interrupt starvation. Double-read DMA movement across 2.5–3 ms was **1,128–1,160 bytes**, consistent with 384,000 B/s. All tones audible throughout (owner confirmation).

**Why simple LPIB reads were deceptive:** the 49,152-byte DMA ring wraps every 128 ms at 384,000 B/s. A 2.048 s diagnostic interval spans **16 complete wraps**. An unchanged sample position at those intervals does *not* prove stalled DMA. V76 used two reads 2.5–3ms apart to avoid that alias.

**V77 permanent install:** signed module loaded on Ubuntu `7.3.0-10-generic`, bridge allocated eight MSIs (94–101 in observed run), and HDA stream used **MSI4 / IRQ98** (not base 94). Eight 5-second test windows each produced period interrupts; HDA completions rose **114 → 930**. WirePlumber's exact-node `disable-tsched=true` was verified live. The owner later reported *hours* of ordinary music playback without the prior dropout.

**Not yet proven:** independent contribution of MSI4 vs BDL64 vs PipeWire; new kernel versions, power transitions, other cards, other bridge revisions, multi-channel, post-reboot test, and physical signal waveform measurement. Raw unfiltered logs are intentionally not public.
