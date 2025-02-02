#ifndef LOGGING_H
#define LOGGING_H

void logDebug(const char* format, ...);
void logInfo(const char* format, ...);
void logWarning(const char* format, ...);
void logError(const char* format, ...);

typedef struct Logging {
    void (*debug)(const char* format, ...);
    void (*info)(const char* format, ...);
    void (*warning)(const char* format, ...);
    void (*error)(const char* format, ...);
} Logging;

#endif // LOGGING_H
