#ifndef PCI_RESOURCE_H
#define PCI_RESOURCE_H

#include <stddef.h>
#include <stdint.h>
#include <sys/types.h>

#define BYTE_SIZE 1
#define WORD_SIZE 2
#define DWORD_SIZE 4
#define QWORD_SIZE 8

typedef struct PciResource {
    size_t length;
    off_t offset;
    void* baseRegion;
    int (*write32)(struct PciResource*, uint32_t, uint32_t);
    int (*read32)(struct PciResource*, uint32_t, uint32_t*);
    int (*close)(struct PciResource*);
} PciResource;

int pciResourceWrite32(PciResource* resource, uint32_t address, uint32_t data);
int pciResourceRead32(PciResource* resource, uint32_t address, uint32_t* data);
int pciResourceClose(PciResource* resource);
int openPciResource(PciResource* resource, const char* path, size_t length, off_t offset);

#endif // PCI_RESOURCE_H
