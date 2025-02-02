#ifndef TOOLS_H
#define TOOLS_H

#include "driver/include/vitisnetp4_target.h"
#include "driver/include/vitisnetp4_common.h"
#include "common/include/pci_resource.h"
#include "common/include/logging.h"

#include <stdio.h>

static inline void print_usage(const char* program_name) {
    printf("Usage: %s <pci-resource-path>\n", program_name);
    printf("Example: %s /sys/bus/pci/devices/xxxx:xx:xx.x/resource2\n", program_name);
}

static inline void cleanupTarget(XilVitisNetP4TargetCtx targetCtx) {
    logInfo("Cleanup Target");
    XilVitisNetP4ReturnType result;
    result = XilVitisNetP4TargetExit(&targetCtx);
    if (result != XIL_VITIS_NET_P4_SUCCESS) {
        logError("Code: %s\n", XilVitisNetP4ReturnTypeToString(result));
    }
}

static inline void cleanupPciResource(PciResource pciResource) {
    logInfo("Cleanup PciResource");
    pciResource.close(&pciResource);
}

#endif // TOOLS_H
