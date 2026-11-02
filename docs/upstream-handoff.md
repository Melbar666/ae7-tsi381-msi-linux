# ALSA upstream report — draft, not sent

**Proposed topic:** ALSA hda: Creative AE-7 behind Tsi381 bridge drops analog stereo after seconds; experimental late MSI4 routing works on one host

**Hardware:** Creative CA0132 `1102:0010`, subsystem `1102:0081`; Tsi381 PCIe-to-PCI bridge `10e3:8111`. Kubuntu 26.10 with stock kernel `7.3.0-10-generic`, PipeWire 1.6.8, WirePlumber 0.5.17.

**Problem:** The stock HDA driver recognizes the device and initially plays normal analog stereo audio, then output repeatedly goes silent (often after ~10–30 s). Codec reset or output changes can temporarily restore playback.

**Experimental workaround:** After codec registration, allocate eight bridge MSI vectors and map HDA INTA to MSI4; use card-specific `bdl_pos_adj=64`; set `api.alsa.disable-tsched=true` on the exact PipeWire AE-7 analog stereo node. The driver reports `no_period_wakeup=0` and three IOC descriptors. In one 170s test all tones were heard, with +4,025 bridge MSI interrupts and HDA `sd_complete` 98→3,986. After V77 installation a 40s test completed with stream completions 114→930; several hours of normal music have been heard without the original dropouts.

**What is and isn't proven:** The combination is successful on this one host. We have NOT proved which component alone fixes the issue. The full experimental patch includes timing-sensitive diagnostic instrumentation and a hard-coded bus guard; it is NOT a proposed upstream-ready final implementation.

**Request for maintainers:** Is the Tsi381 interrupt translation known to be problematic for this CA0132 controller? What layer should own bridge MSI interrupt mapping? What safe PCI matching, IRQ lifecycle, probe failure and PM handling would be acceptable? Does an existing kernel quirk make this approach unnecessary?

**Submission workflow:** Discuss at `linux-sound@vger.kernel.org` and use `scripts/get_maintainer.pl` on a real upstream-base patch. Review the latest kernel contribution guidance. A human contributor must review code and provide their own DCO `Signed-off-by`. AI-assisted work should be disclosed, e.g. `Assisted-by: ChatGPT:GPT-6`. No message/patch has been mailed by this project at this stage.
