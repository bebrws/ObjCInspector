//
//  ObjCInspector.m
//  ObjCInspector
//
//  Created by Bradley Barrows on 7/28/20.
//  Copyright © 2020 Bradley Barrows. All rights reserved.
//
#import <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <mach-o/nlist.h>

#include <stdio.h>
#import "ObjCInspector.h"

#import "MachO.h"

#include <mach-o/loader.h>
#include <mach-o/dyld_images.h>
#include <mach/task_info.h>
#include <mach/task.h>
#include <mach/mach_init.h>
#include <mach/mach_traps.h>
#include <mach/task_info.h>
#include <objc/message.h>
#include <objc/runtime.h>

#include "KZRMethodSwizzlingWithBlock.h"



void install(void) __attribute__ ((constructor));
void install_mouse_down_hooks(NSDictionary *modsToClasses, NSArray *modulesToHook);
void payload_entry(int argc, char **argv, FILE *in, FILE *out, FILE *err);

@implementation ObjCInspector

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    return self;
}

- (void)searchAndHookAllDylib {
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
        printf("Original header: %s\n", [filePathString UTF8String]);
        NSURL *furl = [[NSURL alloc] initWithString:filePathString];
        NSString *moduleNameString = [furl lastPathComponent];

        MachO *mo = [[MachO alloc] initWithHeader:header filePathString:filePathString];
        printf("mo symbols: %s\n", [[mo.symbols description] UTF8String]);
        if ([mo.symbols count] > 0) {
            [moduleToSymbols setValue:mo.symbols forKey:moduleNameString];
            printf("moduleToSumbols: %s - %s\n", [[moduleNameString description] UTF8String], [[mo.symbols description] UTF8String]);
        }
        
        
//        if ([mo.dlopenFilepaths count] > 0) {
//            for (NSString *dlopenFilepath in mo.dlopenFilepaths) {
//
//                void *dlHeader = dlopen([dlopenFilepath UTF8String], RTLD_NOLOAD);
//                MachO *dlMo = [[MachO alloc] initWithHeader:dlHeader filePathString:dlopenFilepath];
//
//                printf("dlMo symbols: %s\n", [[dlMo.symbols description] UTF8String]);
//
//                NSURL *dlFurl = [[NSURL alloc] initWithString:dlopenFilepath];
//                NSString *dlModuleNameString = [dlFurl lastPathComponent];
//
//                if ([dlMo.symbols count] > 0) {
//                    [moduleToSymbols setValue:dlMo.symbols forKey:dlModuleNameString];
//                    printf("moduleToSumbolsDYLIB: %s - %s\n", [[dlModuleNameString description] UTF8String], [[dlMo.symbols description] UTF8String]);
//                }
//            }
//        }
        
        unsigned int imageCount=0;
        const char **imageNames=objc_copyImageNames(&imageCount);
        for (int i=0; i<imageCount; i++){
            const char *imageName=imageNames[i];
            const char **names = objc_copyClassNamesForImage((const char *)imageName,&count);
            for (int i=0; i<count; i++){
                const char *clsname=names[i];
                
                printf("%s - %s\n", imageName, clsname);
            }
        }
        
    }

    printf("\nmoduleToSymbols: %s\n", [[moduleToSymbols description] UTF8String]);
    
    // Check the file insp.json for a file in form:
    // {
    //    modules: ["Terminal"]
    //}
    // This will only hook classes in the Terminal Module
    // If no file is found NULL will be passed to the hook function meaning hook all.
    NSDictionary* fromTmpInspJson = NULL;
    NSError *error;
    NSString *jsonStringPath = @"insp.json";
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *pathForFile;

    if ([fileManager fileExistsAtPath:jsonStringPath]){
        fromTmpInspJson = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:jsonStringPath] options:kNilOptions error:&error];
    }
    

    [self install_mouse_down_hooks:moduleToSymbols modulesToHook:(fromTmpInspJson == NULL ? NULL : fromTmpInspJson[@"modules"])];
}


- (void) newMouseDown:(NSEvent *)event {
    printf("HEYYY FROM NEW MOUSE DOWN\n\n");
}

- (void)install_mouse_down_hooks:(NSDictionary *)modsToClasses modulesToHook:(NSArray *)modulesToHook {
    NSMutableArray *classesStringsToHook = [[NSMutableArray alloc] init];
    for (NSString *module in modsToClasses) {
        if (!modulesToHook || [modulesToHook containsObject:module]) {
            NSArray *classesStrings = modsToClasses[module];
            for (NSString *curClassString in classesStrings) {
                Class curClass = NSClassFromString(curClassString);
                NSMutableArray *curList = [[NSMutableArray alloc] init];
                BOOL isNSObjOrResponder = NO;
                BOOL wasResponderChain = NO;

                for(Class candidate = curClass; candidate != Nil && !isNSObjOrResponder; candidate = class_getSuperclass(candidate))
                {
                    if(candidate == objc_getClass("NSObject") || candidate == objc_getClass("NSResponder")) {
                        isNSObjOrResponder = YES;
                        wasResponderChain = (candidate == objc_getClass("NSResponder"));
               
                    }
                }

                if (wasResponderChain) {
                    [classesStringsToHook addObjectsFromArray:curClassString];
                }

            }
        }
    }
    
    printf("classesStringsToHook: %s\n", [[classesStringsToHook description] UTF8String]);
    // Next hook all those classes in classesStringsToHook
    for (NSString *curClassString in classesStringsToHook) {
         Class curClass = NSClassFromString(curClassString);
        if (curClass) {
            const char *curClassCString = [curClassString UTF8String];
            
            printf("Hooking class %s\n", curClassCString);

    //        [KZRMETHOD_SWIZZLING_(curClassCString, "mouseDown:",
    //            void, originalMethod, originalSelector)
    //            ^ (id slf, NSEvent *event){  // SEL is not brought (id self, arg1, arg2...)
    //                printf("\n\n Reg Ccick HOOK METHOD!!!n\n\n");
    //                originalMethod(slf, originalSelector, event);
    //        }_WITHBLOCK;
            
    //         KZRMETHOD_SWIZZLING_("BBView", "mouseDown:",
    //             void, originalMethod, originalSelector)
    //             ^ (id slf, NSEvent *event){  // SEL is not brought (id self, arg1, arg2...)
    //                 printf("\n\n Reg Ccick HOOK METHOD!!!n\n\n");
    //                 originalMethod(slf, originalSelector, event);
    //         }_WITHBLOCK;
            
            SEL originalSelector = @selector(mouseDown:);
            SEL newSelector = @selector(newMouseDown:);
            Method originalMethod = class_getInstanceMethod(curClass, originalSelector);
            Method newMethod = class_getInstanceMethod(curClass, newSelector);
            method_exchangeImplementations(originalMethod, newMethod);
        }
        
    }
}

@end

void install(void) __attribute__ ((constructor))
{
    ObjCInspector *insp = [[ObjCInspector alloc] init];
    [insp searchAndHookAllDylib];

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
