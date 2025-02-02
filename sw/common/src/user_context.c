#include "common/include/user_context.h"
#include "common/include/logging.h"
#include "driver/include/vitisnetp4_common.h"

#include <stdint.h>
#include <stdlib.h>

XilVitisNetP4ReturnType userLog(XilVitisNetP4EnvIf* interface, const char* message) {
    if (interface == NULL) return XIL_VITIS_NET_P4_GENERAL_ERR_NULL_PARAM;
    if (message == NULL) return XIL_VITIS_NET_P4_GENERAL_ERR_NULL_PARAM;
    return XIL_VITIS_NET_P4_SUCCESS;
}

XilVitisNetP4ReturnType userWordWrite32(XilVitisNetP4EnvIf* interface, XilVitisNetP4AddressType address, uint32_t data) {
    UserContext* userCtx;

    if (interface == NULL) return XIL_VITIS_NET_P4_GENERAL_ERR_NULL_PARAM;
    else if (interface->UserCtx == NULL) return XIL_VITIS_NET_P4_GENERAL_ERR_INTERNAL_ASSERTION;

    userCtx = (UserContext*)interface->UserCtx;

    logDebug("[%s:%s] 0x%x => 0x%x", __FILE__, __func__, address, data);
    if (userCtx->pciResource->write32(userCtx->pciResource, address, data) == EXIT_FAILURE) {
        return XIL_VITIS_NET_P4_GENERAL_ERR_INTERNAL_ASSERTION;
    }

    return XIL_VITIS_NET_P4_SUCCESS;
}

XilVitisNetP4ReturnType userWordRead32(XilVitisNetP4EnvIf* interface, XilVitisNetP4AddressType address, uint32_t* data) {
    UserContext* userCtx;

    if (interface == NULL || data == NULL) return XIL_VITIS_NET_P4_GENERAL_ERR_NULL_PARAM;
    else if (interface->UserCtx == NULL) return XIL_VITIS_NET_P4_GENERAL_ERR_INTERNAL_ASSERTION;

    userCtx = (UserContext *) interface->UserCtx;

    if (userCtx->pciResource->read32(userCtx->pciResource, address, data) == EXIT_FAILURE) {
        return XIL_VITIS_NET_P4_GENERAL_ERR_INTERNAL_ASSERTION;
    }
    logDebug("[%s:%s] 0x%x => 0x%x", __FILE__, __func__, address, *data);

    return XIL_VITIS_NET_P4_SUCCESS;
}
