const std = @import("std");
const builtin = @import("builtin");

const fmt = std.fmt;
const fs = std.fs;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const os_tag = target.os_tag orelse builtin.target.os.tag;

    switch (os_tag) {
        .macos => {},
        else => @panic("unsupported platform"),
    }

    const libhidapi = b.addStaticLibrary(.{
        .name = "hidapi",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    libhidapi.addIncludePath(.{ .path = "libusb/libusb" });
    libhidapi.addIncludePath(.{ .path = "hidapi/hidapi/os" });

    switch (os_tag) {
        .macos => {
            libhidapi.addIncludePath(.{ .path = "hidapi/hidapi" });
            libhidapi.addCSourceFiles(&.{
                "hidapi/mac/hid.c",
            }, &.{
                "-Wall",
            });
        },
        else => unreachable,
    }

    const libusb = b.addStaticLibrary(.{
        .name = "usb",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    libusb.addIncludePath(.{ .path = "libusb/libusb" });

    libusb.addCSourceFiles(&.{
        "libusb/libusb/os/events_posix.c",
        "libusb/libusb/os/threads_posix.c",
        "libusb/libusb/core.c",
        "libusb/libusb/descriptor.c",
        "libusb/libusb/hotplug.c",
        "libusb/libusb/io.c",
        "libusb/libusb/strerror.c",
        "libusb/libusb/sync.c",
    }, &.{
        "-Wall",
    });

    switch (os_tag) {
        .macos => {
            libusb.addIncludePath(.{ .path = "libusb/Xcode" });
            libusb.addCSourceFiles(&.{
                "libusb/libusb/os/darwin_usb.c",
            }, &.{
                "-Wall",
            });
        },
        else => unreachable,
    }

    const libjimtcl = b.addStaticLibrary(.{
        .name = "jimtcl",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const jimconfig_h = b.addConfigHeader(.{
        .style = .blank,
        .include_path = "jim-config.h",
    }, .{
        .HAVE_LONG_LONG = 1,
        .JIM_VERSION = 81,
        .SIZEOF_INT = 4,
        .jim_ext_aio = 1,
        .jim_ext_namespace = 1,
        .jim_ext_package = 1,
    });

    const jimautoconf_h = b.addConfigHeader(.{
        .style = .blank,
        .include_path = "jimautoconf.h",
    }, .{
        .HAVE_DIRENT_H = 1,
        .HAVE_SYS_TIME_H = 1,
        .HAVE_UNISTD_H = 1,
    });

    libjimtcl.addConfigHeader(jimconfig_h);
    libjimtcl.addConfigHeader(jimautoconf_h);

    libjimtcl.addIncludePath(.{ .path = "openocd/jimtcl" });
    libjimtcl.addCSourceFiles(&.{
        "ext/macos/_glob.c",
        "ext/macos/_initjimsh.c",
        "ext/macos/_load-static-exts.c",
        "ext/macos/_nshelper.c",
        "ext/macos/_oo.c",
        "ext/macos/_stdlib.c",
        "ext/macos/_tclcompat.c",
        "ext/macos/_tree.c",
        "openocd/jimtcl/jim-aio.c",
        "openocd/jimtcl/jim-array.c",
        "openocd/jimtcl/jim-clock.c",
        "openocd/jimtcl/jim-eventloop.c",
        "openocd/jimtcl/jim-exec.c",
        "openocd/jimtcl/jim-file.c",
        "openocd/jimtcl/jim-format.c",
        "openocd/jimtcl/jim-history.c",
        "openocd/jimtcl/jim-interactive.c",
        "openocd/jimtcl/jim-interp.c",
        "openocd/jimtcl/jim-json.c",
        "openocd/jimtcl/jim-load.c",
        "openocd/jimtcl/jim-namespace.c",
        "openocd/jimtcl/jim-pack.c",
        "openocd/jimtcl/jim-package.c",
        "openocd/jimtcl/jim-posix.c",
        "openocd/jimtcl/jim-readdir.c",
        "openocd/jimtcl/jim-readline.c",
        "openocd/jimtcl/jim-regexp.c",
        "openocd/jimtcl/jim-signal.c",
        "openocd/jimtcl/jim-sqlite3.c",
        "openocd/jimtcl/jim-subcmd.c",
        "openocd/jimtcl/jim-syslog.c",
        "openocd/jimtcl/jim-tclprefix.c",
        "openocd/jimtcl/jim-tty.c",
        "openocd/jimtcl/jim-zlib.c",
        "openocd/jimtcl/jim.c",
        "openocd/jimtcl/jimiocompat.c",
        "openocd/jimtcl/jimregexp.c",
        "openocd/jimtcl/jimsh.c",
        "openocd/jimtcl/linenoise.c",
        "openocd/jimtcl/utf8.c",
    }, &.{});

    const openocd = b.addExecutable(.{
        .name = "openocd",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    openocd.addIncludePath(.{ .path = "openocd/src" });
    openocd.addCSourceFiles(&.{
        "openocd/src/flash/common.c",
        "openocd/src/flash/nand/arm_io.c",
        "openocd/src/flash/nand/at91sam9.c",
        "openocd/src/flash/nand/core.c",
        "openocd/src/flash/nand/davinci.c",
        "openocd/src/flash/nand/driver.c",
        "openocd/src/flash/nand/ecc.c",
        "openocd/src/flash/nand/ecc_kw.c",
        "openocd/src/flash/nand/fileio.c",
        "openocd/src/flash/nand/lpc3180.c",
        "openocd/src/flash/nand/lpc32xx.c",
        "openocd/src/flash/nand/mx3.c",
        "openocd/src/flash/nand/mxc.c",
        "openocd/src/flash/nand/nonce.c",
        "openocd/src/flash/nand/nuc910.c",
        "openocd/src/flash/nand/orion.c",
        "openocd/src/flash/nand/s3c2410.c",
        "openocd/src/flash/nand/s3c2412.c",
        "openocd/src/flash/nand/s3c2440.c",
        "openocd/src/flash/nand/s3c2443.c",
        "openocd/src/flash/nand/s3c24xx.c",
        "openocd/src/flash/nand/s3c6400.c",
        "openocd/src/flash/nand/tcl.c",
        "openocd/src/flash/nor/aduc702x.c",
        "openocd/src/flash/nor/aducm360.c",
        "openocd/src/flash/nor/ambiqmicro.c",
        "openocd/src/flash/nor/at91sam3.c",
        "openocd/src/flash/nor/at91sam4.c",
        "openocd/src/flash/nor/at91sam4l.c",
        "openocd/src/flash/nor/at91sam7.c",
        "openocd/src/flash/nor/at91samd.c",
        "openocd/src/flash/nor/ath79.c",
        "openocd/src/flash/nor/atsame5.c",
        "openocd/src/flash/nor/atsamv.c",
        "openocd/src/flash/nor/avrf.c",
        "openocd/src/flash/nor/bluenrg-x.c",
        "openocd/src/flash/nor/cc26xx.c",
        "openocd/src/flash/nor/cc3220sf.c",
        "openocd/src/flash/nor/cfi.c",
        "openocd/src/flash/nor/core.c",
        "openocd/src/flash/nor/drivers.c",
        "openocd/src/flash/nor/dsp5680xx_flash.c",
        "openocd/src/flash/nor/efm32.c",
        "openocd/src/flash/nor/em357.c",
        "openocd/src/flash/nor/esirisc_flash.c",
        "openocd/src/flash/nor/faux.c",
        "openocd/src/flash/nor/fespi.c",
        "openocd/src/flash/nor/fm3.c",
        "openocd/src/flash/nor/fm4.c",
        "openocd/src/flash/nor/jtagspi.c",
        "openocd/src/flash/nor/kinetis.c",
        "openocd/src/flash/nor/kinetis_ke.c",
        "openocd/src/flash/nor/lpc2000.c",
        "openocd/src/flash/nor/lpc288x.c",
        "openocd/src/flash/nor/lpc2900.c",
        "openocd/src/flash/nor/lpcspifi.c",
        "openocd/src/flash/nor/max32xxx.c",
        "openocd/src/flash/nor/mdr.c",
        "openocd/src/flash/nor/mrvlqspi.c",
        "openocd/src/flash/nor/msp432.c",
        "openocd/src/flash/nor/niietcm4.c",
        "openocd/src/flash/nor/non_cfi.c",
        "openocd/src/flash/nor/npcx.c",
        "openocd/src/flash/nor/nrf5.c",
        "openocd/src/flash/nor/numicro.c",
        "openocd/src/flash/nor/ocl.c",
        "openocd/src/flash/nor/pic32mx.c",
        "openocd/src/flash/nor/psoc4.c",
        "openocd/src/flash/nor/psoc5lp.c",
        "openocd/src/flash/nor/psoc6.c",
        "openocd/src/flash/nor/renesas_rpchf.c",
        "openocd/src/flash/nor/rp2040.c",
        "openocd/src/flash/nor/rsl10.c",
        "openocd/src/flash/nor/sfdp.c",
        "openocd/src/flash/nor/sh_qspi.c",
        "openocd/src/flash/nor/sim3x.c",
        "openocd/src/flash/nor/spi.c",
        "openocd/src/flash/nor/stellaris.c",
        "openocd/src/flash/nor/stm32f1x.c",
        "openocd/src/flash/nor/stm32f2x.c",
        "openocd/src/flash/nor/stm32h7x.c",
        "openocd/src/flash/nor/stm32l4x.c",
        "openocd/src/flash/nor/stm32lx.c",
        "openocd/src/flash/nor/stmqspi.c",
        "openocd/src/flash/nor/stmsmi.c",
        "openocd/src/flash/nor/str7x.c",
        "openocd/src/flash/nor/str9x.c",
        "openocd/src/flash/nor/str9xpec.c",
        "openocd/src/flash/nor/swm050.c",
        "openocd/src/flash/nor/tcl.c",
        "openocd/src/flash/nor/tms470.c",
        "openocd/src/flash/nor/virtual.c",
        "openocd/src/flash/nor/w600.c",
        "openocd/src/flash/nor/xcf.c",
        "openocd/src/flash/nor/xmc1xxx.c",
        "openocd/src/flash/nor/xmc4xxx.c",
        "openocd/src/hello.c",
        "openocd/src/helper/binarybuffer.c",
        "openocd/src/helper/command.c",
        "openocd/src/helper/configuration.c",
        "openocd/src/helper/fileio.c",
        "openocd/src/helper/jep106.c",
        "openocd/src/helper/jim-nvp.c",
        "openocd/src/helper/log.c",
        "openocd/src/helper/options.c",
        "openocd/src/helper/replacements.c",
        "openocd/src/helper/time_support.c",
        "openocd/src/helper/time_support_common.c",
        "openocd/src/helper/util.c",
        "openocd/src/jtag/adapter.c",
        "openocd/src/jtag/aice/aice_interface.c",
        "openocd/src/jtag/aice/aice_pipe.c",
        "openocd/src/jtag/aice/aice_port.c",
        "openocd/src/jtag/aice/aice_transport.c",
        "openocd/src/jtag/aice/aice_usb.c",
        "openocd/src/jtag/commands.c",
        "openocd/src/jtag/core.c",
        //"openocd/src/jtag/drivers/OpenULINK/src/delay.c",
        //"openocd/src/jtag/drivers/OpenULINK/src/jtag.c",
        //"openocd/src/jtag/drivers/OpenULINK/src/main.c",
        //"openocd/src/jtag/drivers/OpenULINK/src/protocol.c",
        //"openocd/src/jtag/drivers/OpenULINK/src/usb.c",
        "openocd/src/jtag/drivers/am335xgpio.c",
        //"openocd/src/jtag/drivers/amt_jtagaccel.c",
        "openocd/src/jtag/drivers/arm-jtag-ew.c",
        "openocd/src/jtag/drivers/at91rm9200.c",
        "openocd/src/jtag/drivers/bcm2835gpio.c",
        "openocd/src/jtag/drivers/bitbang.c",
        "openocd/src/jtag/drivers/bitq.c",
        "openocd/src/jtag/drivers/buspirate.c",
        "openocd/src/jtag/drivers/cmsis_dap.c",
        "openocd/src/jtag/drivers/cmsis_dap_usb_bulk.c",
        "openocd/src/jtag/drivers/cmsis_dap_usb_hid.c",
        "openocd/src/jtag/drivers/driver.c",
        "openocd/src/jtag/drivers/dummy.c",
        "openocd/src/jtag/drivers/ep93xx.c",
        "openocd/src/jtag/drivers/esp_usb_jtag.c",
        "openocd/src/jtag/drivers/ft232r.c",
        "openocd/src/jtag/drivers/ftdi.c",
        //"openocd/src/jtag/drivers/gw16012.c",
        "openocd/src/jtag/drivers/imx_gpio.c",
        //"openocd/src/jtag/drivers/jlink.c",
        "openocd/src/jtag/drivers/jtag_dpi.c",
        "openocd/src/jtag/drivers/jtag_vpi.c",
        "openocd/src/jtag/drivers/kitprog.c",
        "openocd/src/jtag/drivers/libusb_helper.c",
        //"openocd/src/jtag/drivers/linuxgpiod.c",
        "openocd/src/jtag/drivers/mpsse.c",
        "openocd/src/jtag/drivers/nulink_usb.c",
        "openocd/src/jtag/drivers/opendous.c",
        //"openocd/src/jtag/drivers/openjtag.c",
        "openocd/src/jtag/drivers/osbdm.c",
        //"openocd/src/jtag/drivers/parport.c",
        //"openocd/src/jtag/drivers/presto.c",
        "openocd/src/jtag/drivers/remote_bitbang.c",
        "openocd/src/jtag/drivers/rlink.c",
        "openocd/src/jtag/drivers/rlink_speed_table.c",
        "openocd/src/jtag/drivers/rshim.c",
        "openocd/src/jtag/drivers/stlink_usb.c",
        "openocd/src/jtag/drivers/sysfsgpio.c",
        "openocd/src/jtag/drivers/ti_icdi_usb.c",
        //"openocd/src/jtag/drivers/ulink.c",
        //"openocd/src/jtag/drivers/usb_blaster/ublast2_access_libusb.c",
        //"openocd/src/jtag/drivers/usb_blaster/ublast_access_ftdi.c",
        //"openocd/src/jtag/drivers/usb_blaster/usb_blaster.c",
        "openocd/src/jtag/drivers/usbprog.c",
        "openocd/src/jtag/drivers/vdebug.c",
        "openocd/src/jtag/drivers/versaloon/usbtoxxx/usbtogpio.c",
        "openocd/src/jtag/drivers/versaloon/usbtoxxx/usbtojtagraw.c",
        "openocd/src/jtag/drivers/versaloon/usbtoxxx/usbtopwr.c",
        "openocd/src/jtag/drivers/versaloon/usbtoxxx/usbtoswd.c",
        "openocd/src/jtag/drivers/versaloon/usbtoxxx/usbtoxxx.c",
        "openocd/src/jtag/drivers/versaloon/versaloon.c",
        "openocd/src/jtag/drivers/vsllink.c",
        "openocd/src/jtag/drivers/xds110.c",
        //"openocd/src/jtag/drivers/xlnx-pcie-xvc.c",
        "openocd/src/jtag/hla/hla_interface.c",
        "openocd/src/jtag/hla/hla_layout.c",
        "openocd/src/jtag/hla/hla_tcl.c",
        "openocd/src/jtag/hla/hla_transport.c",
        "openocd/src/jtag/interface.c",
        "openocd/src/jtag/interfaces.c",
        "openocd/src/jtag/swim.c",
        "openocd/src/jtag/tcl.c",
        "openocd/src/main.c",
        "openocd/src/openocd.c",
        "openocd/src/pld/pld.c",
        "openocd/src/pld/virtex2.c",
        "openocd/src/pld/xilinx_bit.c",
        "openocd/src/rtos/FreeRTOS.c",
        "openocd/src/rtos/ThreadX.c",
        "openocd/src/rtos/chibios.c",
        "openocd/src/rtos/chromium-ec.c",
        "openocd/src/rtos/eCos.c",
        "openocd/src/rtos/embKernel.c",
        "openocd/src/rtos/hwthread.c",
        "openocd/src/rtos/linux.c",
        "openocd/src/rtos/mqx.c",
        "openocd/src/rtos/nuttx.c",
        "openocd/src/rtos/riot.c",
        "openocd/src/rtos/rtos.c",
        "openocd/src/rtos/rtos_chibios_stackings.c",
        "openocd/src/rtos/rtos_ecos_stackings.c",
        "openocd/src/rtos/rtos_embkernel_stackings.c",
        "openocd/src/rtos/rtos_mqx_stackings.c",
        "openocd/src/rtos/rtos_riot_stackings.c",
        "openocd/src/rtos/rtos_standard_stackings.c",
        "openocd/src/rtos/rtos_ucos_iii_stackings.c",
        "openocd/src/rtos/uCOS-III.c",
        "openocd/src/rtos/zephyr.c",
        "openocd/src/rtt/rtt.c",
        "openocd/src/rtt/tcl.c",
        "openocd/src/server/gdb_server.c",
        "openocd/src/server/ipdbg.c",
        "openocd/src/server/rtt_server.c",
        "openocd/src/server/server.c",
        "openocd/src/server/tcl_server.c",
        "openocd/src/server/telnet_server.c",
        "openocd/src/svf/svf.c",
        "openocd/src/target/a64_disassembler.c",
        "openocd/src/target/aarch64.c",
        "openocd/src/target/adi_v5_dapdirect.c",
        "openocd/src/target/adi_v5_jtag.c",
        "openocd/src/target/adi_v5_swd.c",
        "openocd/src/target/algorithm.c",
        "openocd/src/target/arc.c",
        "openocd/src/target/arc_cmd.c",
        "openocd/src/target/arc_jtag.c",
        "openocd/src/target/arc_mem.c",
        "openocd/src/target/arm11.c",
        "openocd/src/target/arm11_dbgtap.c",
        "openocd/src/target/arm720t.c",
        "openocd/src/target/arm7_9_common.c",
        "openocd/src/target/arm7tdmi.c",
        "openocd/src/target/arm920t.c",
        "openocd/src/target/arm926ejs.c",
        "openocd/src/target/arm946e.c",
        "openocd/src/target/arm966e.c",
        "openocd/src/target/arm9tdmi.c",
        "openocd/src/target/arm_adi_v5.c",
        "openocd/src/target/arm_cti.c",
        "openocd/src/target/arm_dap.c",
        "openocd/src/target/arm_disassembler.c",
        "openocd/src/target/arm_dpm.c",
        "openocd/src/target/arm_jtag.c",
        "openocd/src/target/arm_semihosting.c",
        "openocd/src/target/arm_simulator.c",
        "openocd/src/target/arm_tpiu_swo.c",
        "openocd/src/target/armv4_5.c",
        "openocd/src/target/armv4_5_cache.c",
        "openocd/src/target/armv4_5_mmu.c",
        "openocd/src/target/armv7a.c",
        "openocd/src/target/armv7a_cache.c",
        "openocd/src/target/armv7a_cache_l2x.c",
        "openocd/src/target/armv7a_mmu.c",
        "openocd/src/target/armv7m.c",
        "openocd/src/target/armv7m_trace.c",
        "openocd/src/target/armv8.c",
        "openocd/src/target/armv8_cache.c",
        "openocd/src/target/armv8_dpm.c",
        "openocd/src/target/armv8_opcodes.c",
        "openocd/src/target/avr32_ap7k.c",
        "openocd/src/target/avr32_jtag.c",
        "openocd/src/target/avr32_mem.c",
        "openocd/src/target/avr32_regs.c",
        "openocd/src/target/avrt.c",
        "openocd/src/target/breakpoints.c",
        "openocd/src/target/cortex_a.c",
        "openocd/src/target/cortex_m.c",
        "openocd/src/target/dsp563xx.c",
        "openocd/src/target/dsp563xx_once.c",
        "openocd/src/target/dsp5680xx.c",
        "openocd/src/target/embeddedice.c",
        "openocd/src/target/esirisc.c",
        "openocd/src/target/esirisc_jtag.c",
        "openocd/src/target/esirisc_trace.c",
        "openocd/src/target/espressif/esp32.c",
        "openocd/src/target/espressif/esp32s2.c",
        "openocd/src/target/espressif/esp32s3.c",
        "openocd/src/target/espressif/esp_semihosting.c",
        "openocd/src/target/espressif/esp_xtensa.c",
        "openocd/src/target/espressif/esp_xtensa_semihosting.c",
        "openocd/src/target/espressif/esp_xtensa_smp.c",
        "openocd/src/target/etb.c",
        "openocd/src/target/etm.c",
        "openocd/src/target/etm_dummy.c",
        "openocd/src/target/fa526.c",
        "openocd/src/target/feroceon.c",
        "openocd/src/target/hla_target.c",
        "openocd/src/target/image.c",
        "openocd/src/target/lakemont.c",
        "openocd/src/target/ls1_sap.c",
        "openocd/src/target/mem_ap.c",
        "openocd/src/target/mips32.c",
        "openocd/src/target/mips32_dmaacc.c",
        "openocd/src/target/mips32_pracc.c",
        "openocd/src/target/mips64.c",
        "openocd/src/target/mips64_pracc.c",
        "openocd/src/target/mips_ejtag.c",
        "openocd/src/target/mips_m4k.c",
        "openocd/src/target/mips_mips64.c",
        "openocd/src/target/nds32.c",
        "openocd/src/target/nds32_aice.c",
        "openocd/src/target/nds32_cmd.c",
        "openocd/src/target/nds32_disassembler.c",
        "openocd/src/target/nds32_reg.c",
        "openocd/src/target/nds32_tlb.c",
        "openocd/src/target/nds32_v2.c",
        "openocd/src/target/nds32_v3.c",
        "openocd/src/target/nds32_v3_common.c",
        "openocd/src/target/nds32_v3m.c",
        "openocd/src/target/openrisc/jsp_server.c",
        "openocd/src/target/openrisc/or1k.c",
        "openocd/src/target/openrisc/or1k_du_adv.c",
        "openocd/src/target/openrisc/or1k_tap_mohor.c",
        "openocd/src/target/openrisc/or1k_tap_vjtag.c",
        "openocd/src/target/openrisc/or1k_tap_xilinx_bscan.c",
        "openocd/src/target/quark_d20xx.c",
        "openocd/src/target/quark_x10xx.c",
        "openocd/src/target/register.c",
        "openocd/src/target/riscv/batch.c",
        "openocd/src/target/riscv/program.c",
        "openocd/src/target/riscv/riscv-011.c",
        "openocd/src/target/riscv/riscv-013.c",
        "openocd/src/target/riscv/riscv.c",
        "openocd/src/target/riscv/riscv_semihosting.c",
        "openocd/src/target/rtt.c",
        "openocd/src/target/semihosting_common.c",
        "openocd/src/target/smp.c",
        "openocd/src/target/stm8.c",
        "openocd/src/target/target.c",
        "openocd/src/target/target_request.c",
        "openocd/src/target/testee.c",
        "openocd/src/target/trace.c",
        "openocd/src/target/x86_32_common.c",
        "openocd/src/target/xscale.c",
        "openocd/src/target/xtensa/xtensa.c",
        "openocd/src/target/xtensa/xtensa_chip.c",
        "openocd/src/target/xtensa/xtensa_debug_module.c",
        "openocd/src/transport/transport.c",
        "openocd/src/xsvf/xsvf.c",
    }, &.{});

    openocd.addConfigHeader(jimconfig_h);

    const bindir = try fmt.allocPrint(
        b.allocator,
        "\"{s}\"",
        .{b.getInstallPath(.bin, "")},
    );
    defer b.allocator.free(bindir);

    const pkgdatadir = try fmt.allocPrint(
        b.allocator,
        "\"{s}\"",
        .{b.getInstallPath(.prefix, "share")},
    );
    defer b.allocator.free(pkgdatadir);

    switch (os_tag) {
        .macos => {
            openocd.defineCMacro("BINDIR", bindir);
            openocd.defineCMacro("PKGDATADIR", pkgdatadir);

            openocd.defineCMacro("VERSION", "\"0.12.0\"");
            openocd.defineCMacro("RELSTR", "\"\"");
            openocd.defineCMacro("GITVERSION", "\"9ea7f3d\"");

            openocd.defineCMacro("BUILD_HLADAPTER", null);
            openocd.defineCMacro("HAVE_ARPA_INET_H", null);
            openocd.defineCMacro("HAVE_GETTIMEOFDAY", null);
            openocd.defineCMacro("HAVE_FCNTL_H", null);
            openocd.defineCMacro("HAVE_INTTYPES_H", null);
            openocd.defineCMacro("HAVE_NETDB_H", null);
            openocd.defineCMacro("HAVE_NETINET_IN_H", null);
            openocd.defineCMacro("HAVE_NETINET_TCP_H", null);
            openocd.defineCMacro("HAVE_STDBOOL_H", null);
            openocd.defineCMacro("HAVE_STDINT_H", null);
            openocd.defineCMacro("HAVE_SYS_SOCKET_H", null);
            openocd.defineCMacro("HAVE_SYS_TIME_H", null);
            openocd.defineCMacro("HAVE_UNISTD_H", null);
            openocd.defineCMacro("HAVE_USLEEP", null);

            openocd.linkFramework("AppKit");
            openocd.linkFramework("IOKit");
            openocd.linkFramework("Security");
        },
        else => unreachable,
    }

    openocd.addIncludePath(.{ .path = "hidapi/hidapi" });
    openocd.linkLibrary(libhidapi);

    openocd.addIncludePath(.{ .path = "libusb/libusb" });
    openocd.linkLibrary(libusb);

    openocd.addIncludePath(.{ .path = "openocd/jimtcl" });
    openocd.addIncludePath(.{ .path = "cfg" });
    openocd.linkLibrary(libjimtcl);

    openocd.linkLibC();

    const startup_tcl = try bin2char(b.allocator);
    defer startup_tcl.deinit();

    const startup_tcl_dir = b.makeTempPath();

    const startup_tcl_path = try fs.path.join(
        b.allocator,
        &.{ startup_tcl_dir, "startup_tcl.inc" },
    );
    defer b.allocator.free(startup_tcl_path);

    openocd.addIncludePath(.{ .path = startup_tcl_dir });

    var startup_tcl_file = try fs.createFileAbsolute(startup_tcl_path, .{});
    try startup_tcl_file.writeAll(startup_tcl.items);

    b.installArtifact(openocd);
}

fn bin2char(allocator: Allocator) !ArrayList(u8) {
    var buf = ArrayList(u8).init(allocator);
    defer buf.deinit();

    var out = ArrayList(u8).init(allocator);

    const flash = try fs.cwd().readFileAlloc(
        allocator,
        "openocd/src/flash/startup.tcl",
        1024 * 1024,
    );
    defer allocator.free(flash);

    const helper = try fs.cwd().readFileAlloc(
        allocator,
        "openocd/src/helper/startup.tcl",
        1024 * 1024,
    );
    defer allocator.free(helper);

    const jtag = try fs.cwd().readFileAlloc(
        allocator,
        "openocd/src/jtag/startup.tcl",
        1024 * 1024,
    );
    defer allocator.free(jtag);

    const server = try fs.cwd().readFileAlloc(
        allocator,
        "openocd/src/server/startup.tcl",
        1024 * 1024,
    );
    defer allocator.free(server);

    const target = try fs.cwd().readFileAlloc(
        allocator,
        "openocd/src/target/startup.tcl",
        1024 * 1024,
    );
    defer allocator.free(target);

    try buf.appendSlice(flash);
    try buf.appendSlice(helper);
    try buf.appendSlice(jtag);
    try buf.appendSlice(server);
    try buf.appendSlice(target);

    try out.appendSlice("    ");

    for (0.., buf.items) |i, byte| {
        if (i != 0 and i % 10 == 0) {
            try out.appendSlice(",\n    ");
        } else if (i > 0) {
            try out.appendSlice(", ");
        }

        const arr = [1]u8{byte};

        const hex = try fmt.allocPrint(
            allocator,
            "0x{s}",
            .{fmt.bytesToHex(&arr, .lower)},
        );
        defer allocator.free(hex);

        try out.appendSlice(hex);
    }

    try out.appendSlice(",\n");

    return out;
}
