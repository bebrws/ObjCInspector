//
//  ObjCInspector.m
//  ObjCInspector
//
//  Created by Bradley Barrows on 7/28/20.
//  Copyright © 2020 Bradley Barrows. All rights reserved.
//

#import "ObjCInspector.h"

#import "MachO.h"

#include <mach-o/loader.h>
#include <mach-o/dyld_images.h>
#include <mach/task_info.h>
#include <mach/task.h>
#include <mach/mach_init.h>
#include <mach/mach_traps.h>
#include <mach/task_info.h>

@implementation ObjCInspector

- (void)searchAllDylib {
}

@end

void install(void) __attribute__ ((constructor))
{
    task_dyld_info_data_t task_dyld_info;
    mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
    if (task_info(mach_task_self(), TASK_DYLD_INFO, (task_info_t)&task_dyld_info,
                  &count) != KERN_SUCCESS) {
        printf("Unable to get task info\n");
        return;
    }

    size_t infoCount = 0;

    struct dyld_all_image_infos *aii = (struct dyld_all_image_infos *)task_dyld_info.all_image_info_addr;
    infoCount = aii->infoArrayCount;

    NSMutableDictionary *moduleToSymbols = [[NSMutableDictionary alloc] init];

    // Iterate through all dyld images (loaded libraries) to get their names
    // and offests.
    for (size_t i = 0; i < infoCount; ++i) {
        const struct dyld_image_info *info = &aii->infoArray[i];

        // If the magic number doesn't match then go no further
        // since we're not pointing to where we think we are.
        if (info->imageLoadAddress->magic != MH_MAGIC_64) {
            continue;
        }

        struct mach_header_64 *header = (struct mach_header_64 *)info->imageLoadAddress;

        NSString *filePathString = [NSString stringWithUTF8String:info->imageFilePath];
        NSURL *furl = [[NSURL alloc] initWithString:filePathString];
        NSString *moduleNameString = [furl lastPathComponent];

        MachO *mo = [[MachO alloc] initWithHeader:header sharedCacheBaseAddress:aii->sharedCacheBaseAddress filePathString:filePathString];
        if ([mo.symbols count] > 0) {
            [moduleToSymbols setValue:mo.symbols forKey:moduleNameString];
        }
    }
}

// In case I use injector to inject
// I am injecting this dylib using either:
// https://github.com/bebrws/injector
// or
// https://github.com/bebrws/osxinj
//
void payload_entry(int argc, char **argv, FILE *in, FILE *out, FILE *err)
{
    install();
}
