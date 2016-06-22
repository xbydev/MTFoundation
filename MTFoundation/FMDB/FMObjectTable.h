//
//  FMObjectTable.h
//  MTFoundationDemo
//
//  Created by xiangbiying on 16-6-21.
//  Copyright (c) 2016年 xiangby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "FMObjectProtocol.h"

@interface FMObjectTable : NSObject {

    NSString* _tableName;
    
    FMDatabase* _db;
    
    Class<FMObjectProtocol> _clazz;
    
}

+(id) objectWithModelClass:(Class<FMObjectProtocol>)clazz
                     table:(NSString*)name db:(FMDatabase*)db;

-(id) initWithModelClass:(Class<FMObjectProtocol>)clazz
                   table:(NSString*)name db:(FMDatabase*)db;

-(BOOL) insertObject:(id)object;

-(BOOL) insertObjects:(NSArray*)objects;

-(BOOL) removeObject:(id)object;

-(BOOL) removeObjects:(NSArray*)objects;

-(BOOL) removeAllObjects;

-(BOOL) removeObjectsWithCondition:(NSString*)condition, ...;

-(BOOL) updateObject:(id)object;

-(BOOL) updateObjectWithCondition:(NSString*)condition, ...;

-(NSArray*) allObjects;

-(NSArray*) objectsWithCondition:(NSString*)condition, ...;

-(BOOL) objectsExistWithCondition:(NSString*)condition, ...;

-(NSArray*) objectsWithSQL:(NSString*)sql;

-(void) destroy;

@end
