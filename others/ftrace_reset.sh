#!/bin/bash

#reset
adb shell su -c "echo 0 > /sys/kernel/tracing/tracing_on"
adb shell su -c "echo > /sys/kernel/tracing/set_ftrace_pid"
adb shell su -c "echo > /sys/kernel/tracing/set_ftrace_filter"