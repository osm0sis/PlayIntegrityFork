# Play Integrity Fork
*PIF forked to be more futureproof and develop more methodically*

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/osm0sis/PlayIntegrityFork?label=Release&color=blue&style=flat)](https://github.com/osm0sis/PlayIntegrityFork/releases/latest)
[![GitHub Release Date](https://img.shields.io/github/release-date/osm0sis/PlayIntegrityFork?label=Release%20Date&color=brightgreen&style=flat)](https://github.com/osm0sis/PlayIntegrityFork/releases)  
[![Main Releases](https://img.shields.io/github/downloads/osm0sis/PlayIntegrityFork/latest/total?label=Main%20Repo%20Downloads%20%28Latest%20Release%29&color=blue&style=flat)](https://github.com/osm0sis/PlayIntegrityFork/releases/latest)
[![Main All Releases](https://img.shields.io/github/downloads/osm0sis/PlayIntegrityFork/total?label=Main%20Repo%20Total%20Downloads%20%28All%20Releases%29&color=brightgreen&style=flat)](https://github.com/osm0sis/PlayIntegrityFork/releases)  
[![KSU Releases](https://img.shields.io/github/downloads/KernelSU-Modules-Repo/playintegrityfix/latest/total?label=KernelSU%20Modules%20Repo%20Downloads%20%28Latest%20Release%29&color=blue&style=flat)](https://github.com/osm0sis/PlayIntegrityFork/releases/latest)
[![KSU All Releases](https://img.shields.io/github/downloads/KernelSU-Modules-Repo/playintegrityfix/total?label=KernelSU%20Modules%20Repo%20Total%20Downloads%20%28All%20Releases%29&color=brightgreen&style=flat)](https://github.com/osm0sis/PlayIntegrityFork/releases)

[![PIFork Official XDA Thread](https://img.shields.io/badge/XDA_Forums-PIFork_Official_Thread-blue?logo=XDA-Developers&logoColor=white)](https://xdaforums.com/t/module-play-integrity-fork-pifork.4761120/)

A Zygisk module which fixes "MEETS_DEVICE_INTEGRITY" for the Android <13 "deviceRecognitionVerdict" of the Play Integrity API. On Android 13+ ROMs it still helps to pass checks in Google Wallet and Google Messages RCS support.

To use this module you must have one of the following (latest versions):

- [Magisk](https://github.com/topjohnwu/Magisk) with Zygisk enabled (and Enforce DenyList enabled if NOT also using [Shamiko](https://github.com/LSPosed/LSPosed.github.io?tab=readme-ov-file#shamiko) or [Zygisk Assistant](https://github.com/snake-4/Zygisk-Assistant) or [NoHello](https://github.com/MhmRdd/NoHello), for best results)
- [KernelSU](https://github.com/tiann/KernelSU) with [Zygisk Next](https://github.com/Dr-TSNG/ZygiskNext) or [ReZygisk](https://github.com/PerformanC/ReZygisk) or [NeoZygisk](https://github.com/JingMatrix/NeoZygisk) module installed
- [KernelSU Next](https://github.com/KernelSU-Next/KernelSU-Next) with [Zygisk Next](https://github.com/Dr-TSNG/ZygiskNext) or [ReZygisk](https://github.com/PerformanC/ReZygisk) or [NeoZygisk](https://github.com/JingMatrix/NeoZygisk) module installed
- [APatch](https://github.com/bmax121/APatch) with [Zygisk Next](https://github.com/Dr-TSNG/ZygiskNext) or [ReZygisk](https://github.com/PerformanC/ReZygisk) or [NeoZygisk](https://github.com/JingMatrix/NeoZygisk) module installed

## About module

It injects a classes.dex file to modify fields in the android.os.Build class. Also, it creates a hook in the native code to modify system properties. These are spoofed only to Google Play Services' DroidGuard (Play Integrity) service.

Note: Unless otherwise stated, verdicts here are all referring to the Android <13 Play Integrity "deviceRecognitionVerdict" (or "<A13 PI") which was formerly SafetyNet "ctsProfileMatch", not the Android 13+ Play Integrity "deviceRecognitionVerdict" (or "A13+ PI") which relies on locked bootloader checks to pass even DEVICE integrity.

## Configuration

The module is configured by editing prop or txt (text) files in the module directory (/data/adb/modules/playintegrityfix), by running one of the included scripts there, or by creating a file there to enable some advanced features. These are most easily done using the root file explorer app of your choice, as all should include a file editor and support script execution. The scripts also support command line arguments, which may be added when run from a root file explorer app, or when run in a root (su) shell from adb or a terminal emulator app. Unless otherwise stated, configuration changes will take effect after running the killpi.sh script to restart the Play Integrity (PI) processes, or you may also reboot.

### About 'custom.pif.prop' file

You can fill out the included template [example.pif.prop](https://raw.githubusercontent.com/osm0sis/PlayIntegrityFork/refs/heads/main/module/example.pif.prop) then rename it to custom.pif.prop to spoof your own custom values. It will be used instead of any included pif.prop (none included currently).

Note this is just a template with the current suggested default entries, but with this fork you can include as few or as many android.os.Build class fields and Android system properties as needed to pass DEVICE integrity now and in the future if the checks enforced by Play Integrity change.

As a general rule you can't use values from recent devices due to them only being allowed with full hardware backed attestation, but sets of these values can still be found which pass DEVICE integrity, and still others can also pass STRONG integrity when setup correctly (see the spoofing Advanced Settings section below). These are known as "private fingerprints" since widely publicly shared ones will get banned by Google. A script to extract a random latest Pixel Beta fingerprint is included with the module; see the autopif2 section below for usage and caveats, and expand the Resources below for information and scripts to help find a working private fingerprint.

The previous custom.pif.json format is still supported but no longer the default since prop is easier to use, and will not be force migrated to prop but may be migrated manually (see below). Older formatted custom.pif.json files from cross-forks and previous releases will be automatically migrated to the latest json format; simply ensure the filename is custom.pif.json and place it in the module directory before upgrading.

A migration may also be performed manually in the module directory with a custom.pif.prop or custom.pif.json present by running migrate.sh with the `-a` or `--advanced` argument (to add Advanced Settings) in a file explorer app or with `sh migrate.sh --advanced` in a root shell, `-f` or `--force` if desired, and `-p` or `--prop`, or `-j` or `--json` to force migration between formats.

<details>
<summary><strong>Resources</strong></summary>

- Official Threads:
  - [PIFork](https://xdaforums.com/t/module-play-integrity-fork-pifork.4761120/) - More info, working setups, resources and support (READ FIRST!)
  - [PIF & TS FAQ](https://xdaforums.com/t/pif-faq.4653307/) - Frequently Asked Questions

- Guides:
  - [How-To Guide](https://xdaforums.com/t/module-play-integrity-fix-safetynet-fix.4607985/post-89189572) - Info to help find build.prop files, then create and use a private custom.pif.prop
  - [UI Workflow Guide](https://xdaforums.com/t/pixelflasher-a-gui-tool-for-flashing-updating-rooting-managing-pixel-phones.4415453/post-87412305) - Build/find, edit, and test custom.pif.prop/.json using PixelFlasher on PC

- Scripts:
  - [gen_pif_custom.sh](https://xdaforums.com/t/tools-zips-scripts-osm0sis-odds-and-ends-multiple-devices-platforms.2239421/post-89173470) - Script to generate a custom.pif.prop/.json from device dump build.prop files
  - [pif-test-json-file.sh](https://xdaforums.com/t/module-play-integrity-fix-safetynet-fix.4607985/post-89561228) - Script to automate generating and testing json files to attempt to find working fingerprints
  - [settings.sh](https://github.com/Vagelis1608/The-Pot/blob/main/pifork/settings.sh) - Script to change the PIFork Advanced Settings from the command line

- Apps:
  - [FP BETA Checker](https://xdaforums.com/t/tricky-store-bootloader-keybox-spoofing.4683446/post-89754890) - Tasker App to check the estimated expiry of the Pixel Beta fingerprint and trigger autopif2.sh to update
  - [spoofVendingSdk QSTile](https://xdaforums.com/t/tricky-store-bootloader-keybox-spoofing.4683446/post-90118016) - Tasker App to quickly toggle spoofVendingSdk on and off temporarily for PI verdict testing purposes

</details>

### About 'custom.app_replace_list.txt' file

You can customize the included default [app_replace_list.txt](https://raw.githubusercontent.com/osm0sis/PlayIntegrityFork/refs/heads/main/module/app_replace_list.txt) then rename it to custom.app_replace_list.txt to systemlessly replace any additional conflicting custom ROM spoof injection app paths to disable them. Changes take effect after a reboot.

### About 'autopif2.sh' and 'killpi.sh' script files

There's intentionally no pif.prop in the module because the goal remains to be futureproof, and including something that may be banned/expired within days of release would be contrary to that goal. If you don't care to have your own private fingerprint to use or don't have time to look for one currently (since very few remain) then simply run the generation script from a root manager app that supports the module Action button, or by running autopif2.sh with the `-s` or `--strong` arguments in a file explorer app or with `sh autopif2.sh --strong` in a root shell. For arm/x86 devices wget2 is required but may be installed via [addon module](https://xdaforums.com/t/tools-zips-scripts-osm0sis-odds-and-ends-multiple-devices-platforms.2239421/post-89991315).

The autopif2 script generates a random device fingerprint from the latest Pixel Beta, ideally only to test an initial setup, since they expire roughly every 6 weeks from the Pixel Beta release date (dates included in the generated fingerprint), and the public mass-used ones from other modules or custom ROMs may also get banned, or may be banned for RCS use while otherwise passing Play Integrity in that time. In addition, unfortunately Pixel Beta fingerprints have changed and can no longer pass DEVICE integrity, so can now only be used for STRONG integrity setups (see the spoofing Advanced Settings section below). Notable advanced command line arguments are: `-m` or `--match` matches the Pixel Beta fingerprint to the device when run on a current Pixel device; `-s` or `--strong` forces the fingerprint to be configured for STRONG integrity (default if no existing file); `-t #` or `--top #` chooses the top level depth to crawl down the Android version list when there are multiple active Betas, e.g. when Android 16 QPR1 is concurrent with Android 15 QPR3 the default value of 1 would get the first listed (A16) and `-t 2` would force it to get the second listed (A15); and `-d #` or `--depth #` chooses the depth to crawl down the QPR Betas list when there are multiple active Betas, e.g. when QPR2 is concurrent with QPR1 within the same Android version, the default value of 1 would get the first listed (QPR2) and `-d 2` would force it to get the second listed (QPR1).

The killpi script forces the Google Play Services DroidGuard (com.google.android.gms.unstable) and Play Store (com.android.vending) processes to end, making them restart with the next attestation attempt; useful for testing out different fingerprints without requiring a reboot in between.

## Troubleshooting

Make sure Google Play Services (com.google.android.gms) is NOT on the Magisk DenyList if Enforce DenyList is enabled since this interferes with the module; the module does prevent this using scripts but it only happens once during each reboot.

Note: To test <A13 PI verdicts on an A13+ ROM the spoofVendingSdk option in the custom.pif.prop Advanced Settings must be temporarily enabled. See the spoofing Advanced Settings section below.

### Failing <A13 PI BASIC integrity

If you are failing MEETS_BASIC_INTEGRITY something is wrong in your setup. Recommended steps in order to find the problem:

- Disable all modules except this one
- Try a different (ideally known working) custom.pif.prop

Note: Some modules which modify system (e.g. Xposed) can trigger DroidGuard detections, as can any which hook Google Play Services (GMS) processes (e.g. custom fonts).

### Failing <A13 PI DEVICE integrity (on KernelSU/KernelSU Next/APatch)

- Disable Zygisk module
- Reboot
- Enable Zygisk module
- Reboot again

### Failing <A13 PI DEVICE integrity (on custom kernel/ROM)

- Check the kernel release string with command `adb shell uname -r` or `uname -r`
- If it's on the [Known Banned Kernel List](https://xdaforums.com/t/module-play-integrity-fix-safetynet-fix.4607985/post-89308909) then inform your kernel developer/ROM maintainer to remove their branding for their next build
- You may also try a different custom kernel, or go back to the default kernel for your ROM, if available/possible

### Failing <A13 PI DEVICE integrity (on custom ROM)

- Check the ROM signing keys with command `adb shell unzip -l /system/etc/security/otacerts.zip` or `unzip -l /system/etc/security/otacerts.zip`
- If the output shows the ROM is signed with the AOSP testkey then inform your ROM maintainer to start signing their builds with a private key for their next build and ideally also provide a ROM signature migration build to allow users to update to it without requiring a data wipe
- Pixel Beta fingerprints and some private fingerprints appear to be exempt from this testkey ROM ban
- There is an experimental advanced feature to attempt to work around this by spoofing the ROM signature in Package Manager, see the spoofing Advanced Settings section below
- You may also try a different custom ROM, or go back to the stock ROM for your device, if available/possible

### Failing A13+ PI DEVICE integrity (especially on custom ROM)

- Check the ROM FINGERPRINT by enabling spoofVendingFinger in Advanced Settings of the config file with the current Pixel Beta fingerprint, run killpi.sh and test again
- If the verdict improves then your ROM FINGERPRINT is likely on the A13+ PI banned fingerprint list; if on a custom ROM then inform your ROM maintainer to change the stock ROM FINGERPRINT they have set globally, or if on a stock ROM or EOL custom ROM then you will need to use spoofVendingFinger permanently or change the ROM FINGERPRINT globally by changing build.prop files, using resetprop or a global property module like MagiskHide Props Config (MHPC)

Note: Please see the spoofing Advanced Settings section below for important caveats to using the spoofVendingFinger feature.

### Failing Play Protect/Store Certification 

- Reflash the module in your root manager app
- Clear Google Play Store (com.android.vending) and, if present, Google Play Protect Service (com.google.android.odad) cache and data
- Reboot

### Failing Google Messages RCS setup or failing to send messages

- Reflash the module in your root manager app
- Try a different (ideally known working) custom.pif.prop
- Clear Google Messages (com.google.android.apps.messaging) cache and data
- Reboot

Note: RCS is most easily checked using Gemini in Messages and usually clearing Messages app data is not required.

### Failing Google Wallet Tap To Pay Setup Security Requirements

- Reflash the module in your root manager app
- Ensure you are passing <A13 PI DEVICE or higher integrity. Wallet uses an internal API that in effect checks this verdict even on A13+ ROMs, in the background.
- Clear Google Wallet (com.google.android.apps.walletnfcrel) and/or Google Pay (com.google.android.apps.nbu.paisa.user) cache, if you have them installed
- Clear Google Play Services (com.google.android.gms) cache and data, or, optionally skip clearing data and wait some time (24-72h) for it to resolve on its own
- Reboot

Note: Clearing Google Play Services app ***data*** will then require you to reset any WearOS devices paired to your device.

### Read module logs

You can read module logs using one of these commands directly after boot:

`adb shell "logcat | grep 'PIF/'"` or `su -c "logcat | grep 'PIF/'"`

Adjust the Advanced Settings "verboseLogs" entry to a value of 0, 1, 2, 3 or 100 in your custom.pif.prop to enable higher logging levels; 100 will dump all Build fields, and show all system properties that DroidGuard is checking.

## Can this module pass MEETS_STRONG_INTEGRITY?

[Kinda...](#about-spoofing-advanced-settings)

## About spoofing Advanced Settings

The advanced spoofing options add granular control over what exactly gets spoofed to Play Integrity (PI), allowing one to disable the parts that may conflict with other kinds of spoofing modules, and provides options to force a device to use <A13 PI verdicts for testing, spoof a fingerprint to A13+ PI, or work around the testkey ROM ban for those needing those features. See more in the Details area below.

<details>
<summary><strong>Details</strong></summary>

- The Advanced Settings entries are present by default from autopif2 or migrate (during installation), but may be added to any fingerprint by running migrate.sh with the `-f -a` or `--force --advanced` arguments in a file explorer app or with `sh migrate.sh --force --advanced` in a root shell. They may also be configured directly for Tricky Store to achieve <A13 PI STRONG or A13+ PI DEVICE/STRONG integrity (see below) by running autopif2.sh with the `-s` or `--strong` arguments in a file explorer app or with `sh autopif2.sh --strong` in a root shell. Other than for the "verboseLogs" entry (see above), they are all 0 (disabled) or 1 (enabled).

- The "spoofBuild" entry (default 1) controls spoofing the Build Fields from the fingerprint; the "spoofProps" entry (default 1) controls spoofing the System Properties from the fingerprint; the "spoofProvider" entry (default 1) controls spoofing the Keystore Provider; the "spoofSignature" entry (default 0) controls spoofing the ROM Signature; the "spoofVendingFinger" entry (default 0) controls spoofing ROM FINGERPRINT to the Play Store (com.android.vending) when set to 1, or may be set to a custom FINGERPRINT value; and the "spoofVendingSdk" entry (default 0) controls spoofing ROM SDK_INT/sdkVersion 32 to the Play Store (com.android.vending) to force Play Integrity to use the <A13 PI verdicts.

- Changing spoofVendingFinger to a value from a device too dissimilar to your device is NOT recommended; potential negative side effects of spoofing a different device's FINGERPRINT to Play Store include different app availability, incorrect app variants being served and/or loss of device exclusive apps/features. If your ROM does not have a working one it would be best to try to find a different working FINGERPRINT from the same (or similar) device's stock ROM to ensure all will continue to work as expected.

- Leaving spoofVendingSdk enabled is NOT recommended, it [will break](https://github.com/osm0sis/PlayIntegrityFork/pull/30) the behavior of the Play Store to some extent (back gesture/navbar button for all, account sign-in and downloads for higher original ROM SDK_INT) and could have other unintended effects like incorrect app variants being served, crashes, etc. Play Store must be fully set up before (and data not cleared during) enabling spoofVendingSdk or it and PI checks will only crash/hang. It may crash multiple times with various errors before returning a verdict. See the Resources section above for a helpful spoofVendingSdk QSTile toggle app.

- For spoofing locked bootloader and attempting to pass <A13 PI STRONG integrity, or A13+ PI DEVICE or STRONG integrity, I only recommend using the latest official [Tricky Store](https://github.com/5ec1cff/TrickyStore), [Tricky Store OSS](https://github.com/beakthoven/TrickyStoreOSS) or [TEESimulator](https://github.com/JingMatrix/TEESimulator) release.

- Note: Using Tricky Store to achieve <A13 PI STRONG integrity (with an unrevoked hardware keybox.xml), requires the Advanced Settings "spoofProvider" disabled and sometimes the "\*.security_patch" entry commented out (often unless spoofing a matching OS Patch Level with system= or all= or Simple date in Tricky Store's security_patch.txt; autopif2 will do this automatically if Tricky Store's directory exists), and a fingerprint with "\*api_level" value >25 (usually 26-32). To achieve <A13 PI DEVICE integrity (with Tricky Store default AOSP software keybox.xml) requires at least "spoofProps" enabled, and some fingerprints may also require "spoofProvider" enabled, and a fingerprint with "\*api_level" value <26 (usually 21-25). More known working private fingerprints can achieve <A13 PI DEVICE/STRONG integrity on more devices using these Advanced Settings in conjunction with Tricky Store than was possible with Tricky Store alone since they require fingerprint props spoofing.

</details>

## About Scripts-only mode

An advanced feature intended for older Android <10 ROMs, mostly stock ROMs or those with stock-like values, (and some other rare special cases), since they generally only need a few prop changes to pass <A13 PI DEVICE integrity. Due to this the majority of the previous information does not apply to or contradicts that of Scripts-only mode, so to avoid confusion it's contained in the Details area below.

<details>
<summary><strong>Details</strong></summary>

- Manually opt-in by creating a file named scripts-only-mode in the module directory, either from a root prompt with `mkdir -p /data/adb/modules/playintegrityfix; touch /data/adb/modules/playintegrityfix/scripts-only-mode` or from a file explorer app, and then re/flashing the module. Scripts-only mode will remain enabled until this file is removed and the module is reflashed again.

- During install all unused default mode files (including custom.pif.json) are removed from the module directory, effectively disabling the Zygisk components of PIF: attestation fallback and device spoofing. You'll see "Scripts-only mode" indicated in the module description in your root manager app.

- For best results, you should still most likely enable Magisk's Enforce DenyList option if NOT also using [Shamiko](https://github.com/LSPosed/LSPosed.github.io/releases) or [Zygisk Assistant](https://github.com/snake-4/Zygisk-Assistant) or [NoHello](https://github.com/MhmRdd/NoHello). The module will automatically add the Google Play Services DroidGuard process (com.google.android.gms.unstable) to the Magisk DenyList, if missing, since for Scripts-only mode it's necessary on some configurations (generally Android 9).

</details>

## About skipping property deletion

An advanced feature (unrelated to Play Integrity) intended for those who also need to use apps which detect prop tampering. To avoid triggering these detections by skipping any `resetprop --delete` commands in the module scripts, manually opt-in by creating a file named skipdelprop in the module directory after installation, either from a root prompt with `touch /data/adb/modules/playintegrityfix/skipdelprop` or from a file explorer app, then reboot.

## About skipping persist property changes

An advanced feature (unrelated to Play Integrity) intended for those who want to bypass the module's finding that their custom ROM may need these properties set to disable the ROM's conflicting integrated PI features; some root checker apps detect these properties even though no known real-world apps/games detect them. To avoid triggering these detections by skipping any persist property modification/creation in the module scripts, manually opt-in by creating a file named skippersistprop in the module directory after installation, either from a root prompt with `touch /data/adb/modules/playintegrityfix/skippersistprop` or from a file explorer app, then reboot.

## About Play Integrity (SafetyNet has been shut down)

[Play Integrity Improved Verdicts](https://developer.android.com/google/play/integrity/improvements) - Information about the more secure verdicts for Android 13+ ROMs (also see the spoofing Advanced Settings section above)

## Credits

Forked from chiteroman's [Play Integrity Fix (PIF)](https://github.com/chiteroman/PlayIntegrityFix) (no longer online).

Original concept and general mechanism of PIF from kdrag0n's [ProtonAOSP](https://protonaosp.org/) and [Universal SafetyNet Fix (USNF)](https://github.com/kdrag0n/safetynet-fix) projects.

Module boot scripts adapted from those of Displax's forked [Universal SafetyNet Fix (USNF MOD)](https://github.com/Displax/safetynet-fix); please see the module files [commit history](https://github.com/Displax/safetynet-fix/commits/dev/magisk) for proper attribution.
