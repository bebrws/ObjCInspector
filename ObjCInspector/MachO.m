//
//  MachO.m
//  ObjCInspector
//
//  Created by Bradley Barrows on 7/28/20.
//  Copyright © 2020 Bradley Barrows. All rights reserved.
//
// Thanks to rodionovd for:
// https://github.com/rodionovd/rd_get_symbols/blob/master/rd_get_symbols.c
// which ended up cutting out hours and hours probably

#import "MachO.h"

#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <mach-o/dyld.h>
#include <mach-o/nlist.h>
#include <mach/mach_vm.h>
#include <mach-o/loader.h>
#include <mach-o/dyld_images.h>
#include <mach/task_info.h>
#include <mach/task.h>
#include <mach/mach_init.h>
#include <mach/mach_traps.h>
#include <mach/task_info.h>
#include <mach/thread_status.h>

@implementation MachO

- (void const *)pointerToImagePlusOffset:(uint32_t)location {
    return (uint8_t const *)header + location;
}

- (id)initWithHeader:(struct mach_header_64 *)header sharedCacheBaseAddress:(uintptr_t)sharedCacheBaseAddress filePathString:(NSString *)filePathString {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self->header = header;
    self.symbols = [[NSMutableArray alloc] init];

    struct dyld_cache_header *h = (struct dyld_cache_header *)sharedCacheBaseAddress;
    struct shared_file_mapping_np *mapping = (void *)(h + 1);

    char *shared_cache_base = sharedCacheBaseAddress;

    uint64_t *fSlide = NULL;
    uint8_t *fLinkEditBase = NULL;

    struct symtab_command *symtab = NULL;
    struct segment_command_64 *seg_linkedit = NULL;
    struct segment_command_64 *seg_text = NULL;

    size_t imagesz = 0;

    struct load_command *lc = (struct load_command *)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        if (lc->cmd == LC_SEGMENT_64  || lc->cmd == LC_SEGMENT) {
            struct segment_command_64 *seg_text = (struct segment_command_64 *)lc;
//            printf("\n~~~~~segname: %s\n", seg_text->segname);
            if (!strcmp(seg_text->segname, "__TEXT")) {
                imagesz += seg_text->vmsize;
                
                
            } else if (!strcmp(seg_text->segname, "__LINKEDIT")) {
                seg_linkedit = (struct segment_command_64 *)lc;
            }
        } else if (lc->cmd == LC_SYMTAB) {
            symtab = (struct symtab_command *)lc;
        } else if (lc->cmd == LC_LOAD_DYLIB) {
            
            struct dylib_command *mach_dylib_command = (struct dylib_command*)lc;

            const char* name = (char *)mach_dylib_command + mach_dylib_command->dylib.name.offset;
            printf("mach_dylib_command->dylib.name: %s\n\n\n", name);
            
        }

        lc = (struct load_command *)((char *)lc + lc->cmdsize);
    }
    if (!seg_linkedit || !seg_text || !symtab) {
        fprintf(stderr, "The module was missing Load Commands\n");
        return NULL;
    }

    intptr_t file_slide = ((intptr_t)seg_linkedit->vmaddr - (intptr_t)seg_text->vmaddr) - seg_linkedit->fileoff;
    intptr_t strings = (intptr_t)header + (symtab->stroff + file_slide);

    struct nlist_64 *sym = (struct nlist_64 *)((intptr_t)header + (symtab->symoff + file_slide));

    for (uint32_t i = 0; i < symtab->nsyms; i++, sym++) {
        if (!sym->n_value) continue;
        const char *symbolString = (const char *)strings + sym->n_un.n_strx;
        NSString *nsSysmbolString = [NSString stringWithUTF8String:symbolString];
        
        if ([nsSysmbolString containsString:@"_OBJC_CLASS_$__"]) {
//            printf("symbolString: %s\n", symbolString);
            NSString *className = [nsSysmbolString substringFromIndex:15];
            [self.symbols addObject:className];
        } else {
            printf("nsSysmbolString: %s\n", [nsSysmbolString UTF8String]);
        }
    }
    // printf("\nself.symbols: %s\n", [[self.symbols description] UTF8String] );

    return self;
}


@end
