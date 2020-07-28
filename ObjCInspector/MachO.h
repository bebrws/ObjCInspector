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


struct dyld_cache_header
{
    char        magic[16];                // e.g. "dyld_v0    i386"
    uint32_t    mappingOffset;            // file offset to first dyld_cache_mapping_info
    uint32_t    mappingCount;            // number of dyld_cache_mapping_info entries
    uint32_t    imagesOffset;            // file offset to first dyld_cache_image_info
    uint32_t    imagesCount;            // number of dyld_cache_image_info entries
    uint64_t    dyldBaseAddress;        // base address of dyld when cache was built
    uint64_t    codeSignatureOffset;    // file offset of code signature blob
    uint64_t    codeSignatureSize;        // size of code signature blob (zero means to end of file)
    uint64_t    slideInfoOffset;        // file offset of kernel slid info
    uint64_t    slideInfoSize;            // size of kernel slid info
    uint64_t    localSymbolsOffset;        // file offset of where local symbols are stored
    uint64_t    localSymbolsSize;        // size of local symbols information
    uint8_t        uuid[16];                // unique value for each shared cache file
    uint64_t    cacheType;                // 1 for development, 0 for optimized
};

struct dyld_cache_mapping_info {
    uint64_t    address;
    uint64_t    size;
    uint64_t    fileOffset;
    uint32_t    maxProt;
    uint32_t    initProt;
};

struct dyld_cache_image_info
{
    uint64_t    address;
    uint64_t    modTime;
    uint64_t    inode;
    uint32_t    pathFileOffset;
    uint32_t    pad;
};

struct dyld_cache_slide_info
{
    uint32_t    version;        // currently 1
    uint32_t    toc_offset;
    uint32_t    toc_count;
    uint32_t    entries_offset;
    uint32_t    entries_count;
    uint32_t    entries_size;  // currently 128
    // uint16_t toc[toc_count];
    // entrybitmap entries[entries_count];
};

struct dyld_cache_local_symbols_info
{
    uint32_t    nlistOffset;        // offset into this chunk of nlist entries
    uint32_t    nlistCount;            // count of nlist entries
    uint32_t    stringsOffset;        // offset into this chunk of string pool
    uint32_t    stringsSize;        // byte count of string pool
    uint32_t    entriesOffset;        // offset into this chunk of array of dyld_cache_local_symbols_entry
    uint32_t    entriesCount;        // number of elements in dyld_cache_local_symbols_entry array
};

struct dyld_cache_local_symbols_entry
{
    uint32_t    dylibOffset;        // offset in cache file of start of dylib
    uint32_t    nlistStartIndex;    // start index of locals for this dylib
    uint32_t    nlistCount;            // number of local symbols for this dylib
};


//
//typedef std::vector<struct load_command const *>          CommandVector;
//typedef std::vector<struct segment_command_64 const *>    Segment64Vector;
//typedef std::vector<struct section_64 const *>            Section64Vector;
//
//typedef std::vector<struct nlist_64 const *>              NList64Vector;
//
//typedef std::map<uint32_t,std::pair<uint64_t,uint64_t> >        SegmentInfoMap;     // fileOffset --> <address,size>
//typedef std::map<uint64_t,std::pair<uint32_t,NSDictionary * __weak> >  SectionInfoMap;  // address    --> <fileOffset,sectionUserInfo>
//typedef std::map<uint64_t,uint64_t>                             ExceptionFrameMap;  // LSDA_addr  -->
//
//    NList64Vector         symbols_64;
//    CommandVector         commands;         // load commands
//    Segment64Vector       segments_64;      // segment entries for 64-bit architectures
//    Section64Vector       sections_64;      // section entries for 64-bit architectures
//    SegmentInfoMap        segmentInfo;      // segment info lookup table by offset
//    SectionInfoMap        sectionInfo;      // section info lookup table by address
//    ExceptionFrameMap     lsdaInfo;         // LSDA info lookup table by address
//

@interface MachO : NSObject {
    uint32_t              imageOffset;  // absolute physical offset of binary image in binar
    uint32_t              imageSize;    // size of the image
    uint64_t              entryPoint;   // where the instruction pointer is set for this binary
    char const *          strtab;
    struct symtab_command const *_symtab_command;
    struct mach_header_64* header;
}

@property (nonatomic, strong) NSMutableArray *symbols;

- (id)initWithHeader:(struct mach_header_64 *)header sharedCacheBaseAddress:(uintptr_t)sharedCacheBaseAddress filePathString:(NSString *)filePathString;
@end

NS_ASSUME_NONNULL_END
