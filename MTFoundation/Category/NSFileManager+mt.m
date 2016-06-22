//
//  NSFileManager+mt.m
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/21.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import "NSFileManager+mt.h"

@implementation NSFileManager (mt)

+(NSString*) pathInDocuments:(NSString*)path {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* path0 = [paths objectAtIndex:0];
    return path ? [path0 stringByAppendingPathComponent:path] : path0;
}

+(NSString *)pathInLibrary:(NSString *)path {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString* path0 = [paths objectAtIndex:0];
    return path ? [path0 stringByAppendingPathComponent:path] : path0;
}

+(NSString *)pathInLibraryCaches:(NSString *)path {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* path0 = [paths objectAtIndex:0];
    return path ? [path0 stringByAppendingPathComponent:path] : path0;
}

-(NSArray *)subpathsInDocuments:(NSString *)directory {
    NSArray* subfiles = [self subpathsAtPath:[NSFileManager pathInDocuments:directory]];
    NSMutableArray* subpaths = [NSMutableArray array];
    for (NSString* file in subfiles) {
        if (directory) {
            [subpaths addObject:[NSFileManager pathInDocuments:
                                 [NSString stringWithFormat:@"%@/%@", directory, file]]];
        } else {
            [subpaths addObject:[NSFileManager pathInDocuments:file]];
        }
        
    }
    return subpaths;
}

-(NSArray *)subpathsInLibrary:(NSString *)directory {
    NSArray* subfiles = [self subpathsAtPath:[NSFileManager pathInLibrary:directory]];
    NSMutableArray* subpaths = [NSMutableArray array];
    for (NSString* file in subfiles) {
        if (directory) {
            [subpaths addObject:[NSFileManager pathInLibrary:
                                 [NSString stringWithFormat:@"%@/%@", directory, file]]];
        } else {
            [subpaths addObject:[NSFileManager pathInLibrary:file]];
        }
    }
    return subpaths;
}

//-(NSArray*) subpathsInDir:(NSString*)dirPath {
//    NSArray* subfiles = [self subpathsAtPath:dirPath];
//    return [subfiles arrayGenWithBlock:^id(NSString* subfile) {
//        return [dirPath stringByAppendingPathComponent:subfile];
//    }];
//}

-(BOOL) deleteFileAtPath:(NSString*)path {
    return [self removeItemAtPath:path error:nil];
}

-(BOOL) isDirectoryAtPath:(NSString*)path {
    BOOL isdir;
    BOOL exist = [self fileExistsAtPath:path isDirectory:&isdir];
    return exist && isdir;
}

@end
