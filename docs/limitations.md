# Safety and known limitations

**Do not install this historical patch unchanged on other machines.**

The working V77 module targets one exact host PCI bus and kernel `7.3.0-10-generic`. Raw bridge register changes / MSI reallocation may hard-lock a machine or disturb other devices. There is no portable installer, DKMS package, kernel-ABI auto-update or regression-tested alternative yet.

The full diff intentionally preserves experimental diagnostics and an opt-in fallback that was **OFF** for successful playback. It is not a clean production patch. The original Ubuntu module remains in the owner's machine as a local rollback file, but no signed module, signing credentials, firmware or raw private logs are distributed here.

Tests covered analog stereo only. No evidence yet for multi-channel, Direct Mode DSP bypass, other revisions, USB/SATA safety under bridge errors, cold-boot persistence, or suspend/resume. Obtain a validated rollback procedure and independent review before any kernel patch installation.
