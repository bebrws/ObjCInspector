//
//  ObjCInspector.h
//  ObjCInspector
//
//  Created by Bradley Barrows on 7/28/20.
//  Copyright © 2020 Bradley Barrows. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjCInspector : NSObject

- (id)init;
- (void)install_mouse_down_hooks:(NSDictionary *)modsToClasses modulesToHook:(NSArray *)modulesToHook;
- (void)searchAndHookAllDylib;

@end

void install(void) __attribute__ ((constructor));
