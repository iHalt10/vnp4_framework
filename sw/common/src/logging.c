#include "common/include/logging.h"

#include <stdio.h>
#include <stdarg.h>

#define ANSI_COLOR_CYAN    "\x1b[36m"
#define ANSI_COLOR_GREEN   "\x1b[32m"
#define ANSI_COLOR_YELLOW  "\x1b[33m"
#define ANSI_COLOR_RED     "\x1b[31m"
#define ANSI_COLOR_RESET   "\x1b[0m"

void logDebug(const char* format, ...) {
    va_list args;
    va_start(args, format);

    printf(ANSI_COLOR_CYAN "[DBG]" ANSI_COLOR_RESET " ");
    vprintf(format, args);
    printf("\n");

    va_end(args);
}

void logInfo(const char* format, ...) {
    va_list args;
    va_start(args, format);

    printf(ANSI_COLOR_GREEN "[INF]" ANSI_COLOR_RESET " ");
    vprintf(format, args);
    printf("\n");

    va_end(args);
}

void logWarning(const char* format, ...) {
    va_list args;
    va_start(args, format);

    fprintf(stderr, ANSI_COLOR_YELLOW "[WRN]" ANSI_COLOR_RESET " ");
    vfprintf(stderr, format, args);
    fprintf(stderr, "\n");

    va_end(args);
}

void logError(const char* format, ...) {
    va_list args;
    va_start(args, format);

    fprintf(stderr, ANSI_COLOR_RED "[ERR]" ANSI_COLOR_RESET " ");
    vfprintf(stderr, format, args);
    fprintf(stderr, "\n");

    va_end(args);
}
