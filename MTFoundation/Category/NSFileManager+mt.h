//
//  NSFileManager+mt.h
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/21.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (mt)

+(NSString*) pathInDocuments:(NSString*)path;

+(NSString*) pathInLibrary:(NSString*)path;

+(NSString*) pathInLibraryCaches:(NSString*)path;

-(NSArray*) subpathsInDocuments:(NSString*)directory;

-(NSArray*) subpathsInLibrary:(NSString*)directory;

-(BOOL) deleteFileAtPath:(NSString*)path;

-(BOOL) isDirectoryAtPath:(NSString*)path;

@end
