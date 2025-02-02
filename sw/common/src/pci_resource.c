#include "common/include/pci_resource.h"
#include "common/include/logging.h"

#include <stdint.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>

int pciResourceWrite32(PciResource* resource, uint32_t address, uint32_t data) {
    if (resource == NULL || resource->baseRegion == NULL) {
        logError("[%s:%s] Invalid PCI resource or file descriptor", __FILE__, __func__);
        return EXIT_FAILURE;
    }

    if (address >= resource->length) {
        logError("[%s:%s] Address 0x%x is out of range (max: 0x%zx)", __FILE__, __func__, address, resource->length - 1);
        return EXIT_FAILURE;
    }

    if (address % DWORD_SIZE != 0) {
        logError("[%s:%s] Address 0x%x is not aligned to %d bytes", __FILE__, __func__, address, DWORD_SIZE);
        return EXIT_FAILURE;
    }

    volatile uint32_t* addr = (volatile uint32_t*)((uint8_t*)resource->baseRegion + address);
    *addr = data;

    return EXIT_SUCCESS;
}

int pciResourceRead32(PciResource* resource, uint32_t address, uint32_t* data) {
    if (resource == NULL || resource->baseRegion == NULL || data == NULL) {
        logError("[%s:%s] Invalid arguments: PCI resource, file descriptor, or data pointer", __FILE__, __func__);
        return EXIT_FAILURE;
    }

    if (address >= resource->length) {
        logError("[%s:%s] Address 0x%x is out of range (max: 0x%zx)", __FILE__, __func__, address, resource->length - 1);
        return EXIT_FAILURE;
    }

    if (address % DWORD_SIZE != 0) {
        logError("[%s:%s] Address 0x%x is not aligned to %d bytes", __FILE__, __func__, address, DWORD_SIZE);
        return EXIT_FAILURE;
    }

    volatile uint32_t* addr = (volatile uint32_t*)((uint8_t*)resource->baseRegion + address);
    *data = *addr;

    return EXIT_SUCCESS;
}

int pciResourceClose(PciResource* resource) {
    if (resource == NULL || resource->baseRegion == NULL) {
        logError("[%s:%s] Invalid arguments: PCI resource, file descriptor, or data pointer", __FILE__, __func__);
        return EXIT_FAILURE;
    }

    if (munmap(resource->baseRegion, resource->length) < 0) {
        logError("[%s:%s] Unmapping memory with munmap (%s)", __FILE__, __func__, strerror(errno));
        return EXIT_FAILURE;
    }

    resource->baseRegion = NULL;
    return EXIT_SUCCESS;
}

int openPciResource(PciResource* resource, const char* path, size_t length, off_t offset) {
    if (resource == NULL) {
        logError("[%s:%s] Invalid resource", __FILE__, __func__);
        return EXIT_FAILURE;
    }

    if (path == NULL) {
        logError("[%s:%s] Invalid path", __FILE__, __func__);
        return EXIT_FAILURE;
    }

    long systemPageSize = sysconf(_SC_PAGESIZE);
    if (systemPageSize == -1) {
        logError("[%s:%s] Failed to get page size", __FILE__, __func__);
        return EXIT_FAILURE;
    }

    if (length % systemPageSize != 0) {
        logError("[%s:%s] length (%zu) is not aligned with page size (%ld)", __FILE__, __func__, length, systemPageSize);
        return EXIT_FAILURE;
    }

    if (offset % systemPageSize != 0) {
        logError("[%s:%s] offset (%zu) is not aligned with page size (%ld)", __FILE__, __func__, offset, systemPageSize);
        return EXIT_FAILURE;
    }

    int fd = open(path, O_RDWR | O_SYNC);
    if (fd < 0) {
        logError("[%s:%s] opening %s file (%s)", __FILE__, __func__, path, strerror(errno));
        return EXIT_FAILURE;
    }

    void* baseRegion = mmap(NULL, length, PROT_READ | PROT_WRITE, MAP_SHARED, fd, offset);
    if (baseRegion == MAP_FAILED) {
        logError("[%s:%s] Mapping memory with mmap (%s)", __FILE__, __func__, strerror(errno));
        exit(EXIT_FAILURE);
    }

    if (close(fd) < 0) {
        logError("[%s:%s] Closing file descriptor (%s)", __FILE__, __func__, strerror(errno));
        munmap(baseRegion, length);
        return EXIT_FAILURE;
    }

    resource->length = length;
    resource->offset = offset;
    resource->baseRegion = baseRegion;
    resource->write32 = pciResourceWrite32;
    resource->read32 = pciResourceRead32;
    resource->close = pciResourceClose;

    return EXIT_SUCCESS;
}
