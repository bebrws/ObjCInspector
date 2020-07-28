//
//  MachO.h
//  ObjCInspector
//
//  Created by Bradley Barrows on 7/28/20.
//  Copyright © 2020 Bradley Barrows. All rights reserved.
//

#import <Foundation/Foundation.h>


#include <mach-o/loader.h>
#include <mach-o/dyld_images.h>
#include <mach/task_info.h>
#include <mach/task.h>
#include <mach/mach_init.h>
#include <mach/mach_traps.h>
#include <mach/task_info.h>

NS_ASSUME_NONNULL_BEGIN



@interface MachO : NSObject {
    uint32_t              imageOffset;  // absolute physical offset of binary image in binar
    uint32_t              imageSize;    // size of the image
    uint64_t              entryPoint;   // where the instruction pointer is set for this binary
    char const *          strtab;
    struct symtab_command const *_symtab_command;
    struct mach_header_64* header;
}

@property (nonatomic, strong) NSMutableArray *symbols;
@property (nonatomic, strong) NSMutableArray *dlopenFilepaths;

- (id)initWithHeader:(struct mach_header_64 *)header filePathString:(NSString *)filePathString;
@end

NS_ASSUME_NONNULL_END
