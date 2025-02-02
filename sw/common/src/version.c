#include "common/include/version.h"
#include "common/include/logging.h"

#include "driver/include/vitisnetp4_target.h"
#include "driver/include/vitisnetp4_common.h"
#include "driver/include/vitisnetp4_target_mgmt.h"

void displayVitisNetP4Versions(XilVitisNetP4TargetCtx* targetCtx) {
    XilVitisNetP4ReturnType result;
    XilVitisNetP4Version swVersion;
    XilVitisNetP4Version ipVersion;
    XilVitisNetP4TargetBuildInfoCtx* buildInfoCtx;

    result =  XilVitisNetP4TargetGetSwVersion(targetCtx, &swVersion);
    if (result != XIL_VITIS_NET_P4_SUCCESS) return;

    result = XilVitisNetP4TargetGetBuildInfoDrv(targetCtx, &buildInfoCtx);
    if (result != XIL_VITIS_NET_P4_SUCCESS) return;

    result = XilVitisNetP4TargetBuildInfoGetIpVersion(buildInfoCtx, &ipVersion);
    if (result != XIL_VITIS_NET_P4_SUCCESS) return;

    logInfo("VitisNetP4 SW Version: %d.%d", swVersion.Major, swVersion.Minor);
    logInfo("VitisNetP4 IP Version: %d.%d", ipVersion.Major, ipVersion.Minor);
}
