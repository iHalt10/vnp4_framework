#include "include/tools.h"
#include "include/tables.h"
#include "common/include/logging.h"
#include "common/include/version.h"
#include "common/include/user_context.h"
#include "common/include/pci_resource.h"
#include "driver/include/vitisnetp4_table.h"
#include "driver/include/vitisnetp4_common.h"
#include "driver/include/vitisnetp4_target.h"
#include "driver/include/vitis_net_p4_core_defs.h"

#include <stdint.h>
#include <stdlib.h>

#define BAR2_BOX0_250 0x100000 // NOTE: open-nic-shell/src/system_config/system_config_address_map.sv

int main(int argc, char *argv[]) {
    PciResource pciResource;
    UserContext userCtx;
    XilVitisNetP4EnvIf interface;
    XilVitisNetP4TargetCtx targetCtx;
    MacAddrsTable macAddrsTable;
    XilVitisNetP4ReturnType result;

    if (argc != 2) {
        print_usage(argv[0]);
        return EXIT_FAILURE;
    }
    const char* sys_file = argv[1];

    if (openPciResource(&pciResource, sys_file, 8192, BAR2_BOX0_250) == EXIT_FAILURE) {
        return EXIT_FAILURE;
    }

    userCtx.pciResource = &pciResource;
    userCtx.offsetAddress = 0;

    interface.WordWrite32 = userWordWrite32;
    interface.WordRead32 = userWordRead32;
    interface.LogError = userLog;
    interface.LogInfo = userLog;
    interface.UserCtx = &userCtx;

    logInfo("Initializing the Target Driver");
    result = XilVitisNetP4TargetInit(&targetCtx, &interface, &XilVitisNetP4TargetConfig_vitis_net_p4_core);
    if (result == XIL_VITIS_NET_P4_TARGET_ERR_INCOMPATIBLE_SW_HW) {
        printf("Found IP and SW version differences:");
        displayVitisNetP4Versions(&targetCtx);
        cleanupPciResource(pciResource);
        return EXIT_FAILURE;
    }
    else if (result != XIL_VITIS_NET_P4_SUCCESS) {
        logError("Code: %s", XilVitisNetP4ReturnTypeToString(result));
        cleanupPciResource(pciResource);
        return EXIT_FAILURE;
    }

    logInfo("Getting MacAddrs Table Handle");
    result = XilVitisNetP4TargetGetTableByName(&targetCtx, TABLE_NAME, &macAddrsTable.tableCtx);
    if (result != XIL_VITIS_NET_P4_SUCCESS) {
        logError("Code: %s", XilVitisNetP4ReturnTypeToString(result));
        cleanupTarget(targetCtx);
        cleanupPciResource(pciResource);
        return EXIT_FAILURE;
    }

    logInfo("Getting MacAddrs Table mode");
    XilVitisNetP4TableMode mode;
    result = XilVitisNetP4TableGetMode(macAddrsTable.tableCtx, &mode);
    if (result != XIL_VITIS_NET_P4_SUCCESS) {
        logError("Code: %s", XilVitisNetP4ReturnTypeToString(result));
        cleanupTarget(targetCtx);
        cleanupPciResource(pciResource);
        return EXIT_FAILURE;
    }
    logInfo("MacAddrs Table mode: %d", mode);

    cleanupTarget(targetCtx);
    cleanupPciResource(pciResource);
    return EXIT_SUCCESS;
}
