#ifndef USER_CONTEXT_H
#define USER_CONTEXT_H

#include "common/include/pci_resource.h"
#include "driver/include/vitisnetp4_common.h"

#include <stdint.h>

typedef struct UserContext {
    PciResource *pciResource;
    uint32_t offsetAddress;
} UserContext;

XilVitisNetP4ReturnType userLog(XilVitisNetP4EnvIf* interface, const char* message);

XilVitisNetP4ReturnType userWordWrite32(XilVitisNetP4EnvIf* interface, XilVitisNetP4AddressType address, uint32_t data);

XilVitisNetP4ReturnType userWordRead32(XilVitisNetP4EnvIf* interface, XilVitisNetP4AddressType address, uint32_t* data);

#endif // USER_CONTEXT_H
