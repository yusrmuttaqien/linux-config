#!/usr/bin/env python3
import sys
from pynvml import *
from ctypes import byref

# ==========================================
# GPU UNDERVOLT & OVERCLOCK SETTINGS
# ==========================================
# 1. Power Limit (Watts) - The hard safety net
POWER_LIMIT_WATTS = 100

# 2. Memory Offset (MHz) - Memory overclock
MEMORY_OFFSET_MHZ = 2050

# 3. Core Offset (MHz) - Shifts the V/F curve (The "Efficiency" tweak)
# Start around 100-150. If you go too high, the driver silently ignores it.
CLOCK_OFFSET_MHZ = 170

# 4. Core Clock Ceiling (MHz) - The "Flattening" of the curve
# This forces the GPU to stop drawing voltage once it hits this speed.
MAX_CLOCK_MHZ = 2500
MIN_CLOCK_MHZ = 0

# ==========================================

def main():
    try:
        nvmlInit()
        device = nvmlDeviceGetHandleByIndex(0)
        gpu_name = nvmlDeviceGetName(device)
        print(f"Initialized NVML. Target GPU: {gpu_name}")

        # STEP 1: Power Limit
        # Apply the absolute hardware limit first.
        try:
            target_limit_mw = int(POWER_LIMIT_WATTS * 1000)
            min_limit_mw, max_limit_mw = nvmlDeviceGetPowerManagementLimitConstraints(device)
            
            # Clamp the requested wattage to hardware limits safely
            target_limit_mw = max(min_limit_mw, min(target_limit_mw, max_limit_mw))
            
            nvmlDeviceSetPowerManagementLimit(device, target_limit_mw)
            print(f"[1/4] Power Limit set to: {target_limit_mw / 1000}W")
        except NVMLError as e:
            print(f"[1/4] ERROR - Failed to set power limit: {e}")

        # STEP 2: Memory Offset
        # Memory scaling is independent of the core V/F curve, so apply it early.
        try:
            info_mem = c_nvmlClockOffset_t()
            info_mem.version = nvmlClockOffset_v1
            info_mem.type = NVML_CLOCK_MEM
            info_mem.pstate = NVML_PSTATE_0
            info_mem.clockOffsetMHz = MEMORY_OFFSET_MHZ

            nvmlDeviceSetClockOffsets(device, byref(info_mem))
            print(f"[2/4] Memory Offset applied: +{MEMORY_OFFSET_MHZ} MHz")
        except NVMLError as e:
            print(f"[2/4] ERROR - Failed to set Memory offset: {e}")

        # STEP 3: Core Clock Offset (The V/F Shift)
        # MUST be done BEFORE locking the clocks. This shifts the curve up so 
        # lower voltages yield higher frequencies.
        try:
            info_core = c_nvmlClockOffset_t()
            info_core.version = nvmlClockOffset_v1
            info_core.type = NVML_CLOCK_GRAPHICS
            info_core.pstate = NVML_PSTATE_0
            info_core.clockOffsetMHz = CLOCK_OFFSET_MHZ

            nvmlDeviceSetClockOffsets(device, byref(info_core))
            print(f"[3/4] Core Offset applied: +{CLOCK_OFFSET_MHZ} MHz")
        except NVMLError as e:
            print(f"[3/4] ERROR - Failed to set Core offset: {e}")

        # STEP 4: Core Clock Lock (The Undervolt)
        # Finally, enforce the ceiling. The GPU climbs the newly shifted curve 
        # and stops at MAX_CLOCK_MHZ, resulting in a lower total voltage draw.
        try:
            nvmlDeviceSetGpuLockedClocks(device, MIN_CLOCK_MHZ, MAX_CLOCK_MHZ)
            print(f"[4/4] Core Clocks locked: {MIN_CLOCK_MHZ} MHz to {MAX_CLOCK_MHZ} MHz")
        except NVMLError as e:
            print(f"[4/4] ERROR - Failed to lock GPU clocks: {e}")

        print("\nSuccess: GPU tuning profile applied.")

    except NVMLError as e:
        print(f"FATAL: Failed to initialize NVML or find GPU. Ensure NVIDIA drivers are loaded. Error: {e}")
        sys.exit(1)

    finally:
        try:
            nvmlShutdown()
        except:
            pass

if __name__ == "__main__":
    main()
