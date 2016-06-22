//
//  FMObjectTable.m
//  MTFoundationDemo
//
//  Created by xiangbiying on 16-6-21.
//  Copyright (c) 2016年 xiangby. All rights reserved.
//

#import "FMObjectTable.h"
#import "FMDatabaseAdditions.h"

@implementation FMObjectTable

+(id) objectWithModelClass:(Class<FMObjectProtocol>)clazz
                     table:(NSString*)name db:(FMDatabase*)db {
    return [[self alloc] initWithModelClass:clazz table:name db:db];
}

-(id) initWithModelClass:(Class<FMObjectProtocol>)clazz
                   table:(NSString*)name db:(FMDatabase*)db {
    if (self = [super init]) {
        _db = db;
        _tableName = name;
        _clazz = clazz;

        NSDictionary* format = [_clazz SQLFormat];
        
        FMResultSet* rs = [db getTableSchema:name];
        
        NSMutableArray* properties = [[NSMutableArray alloc] init];
        while ([rs next]) {
            NSString* p = [rs stringForColumnIndex:1];
            [properties addObject:p];
        }
        
        if (properties.count > 0) {
            
            for (NSString* key in [format allKeys]) {
                if (![properties containsObject:key]) {
                    NSString* type = format[key];
                    NSString* sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@",
                                     name, key, type];
                    BOOL ret = [db executeUpdate:sql];
                    NSLog(@"add column %@ ret: %d", name, ret);
                }
            }
            
        } else {
        
            NSMutableString* sql_body = [[NSMutableString alloc] init];
            NSArray* names = format.allKeys;
            NSUInteger count = names.count;
            
            for (int i = 0; i < count; i++) {
                NSString* name = names[i];
                NSString* type = format[name];
                
                [sql_body appendFormat:@"%@ %@", name, type];
                
                if (i != count - 1) {
                    [sql_body appendString:@","];
                }
            }
            
            NSString* sql_tmp = @"create table if not exists %@(id INTEGER PRIMARY KEY AUTOINCREMENT, %@)";
            NSString* sql = [NSString stringWithFormat:sql_tmp, name, sql_body];
            [db executeUpdate:sql];
            
            
        }
        
        
    }
    return self;
}

-(BOOL) insertObject:(id)object {
    NSMutableArray* names = [[NSMutableArray alloc] init];
    NSMutableString* sql_names = [[NSMutableString alloc] init];
    NSMutableString* sql_values = [[NSMutableString alloc] init];
    NSMutableArray* args = [[NSMutableArray alloc] init];
    
    NSDictionary* format = [_clazz SQLFormat];
    
    for (NSString* name in format.allKeys) {
        
        NSString* type = format[name];
        id value = [object valueForKey:name];
        if (value) {
            
            //if ([type isEqual:@"object"] || [type isEqual:@"collection"]) {
            if ([type isEqual:@"blob"]) {
            
//                NSMutableData* data = [NSMutableData data];
//                NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
//                [archiver encodeObject:value forKey:name];
//                [archiver finishEncoding];
                
                NSData* data = [NSKeyedArchiver archivedDataWithRootObject:value];
                
                [args addObject:data];
                
            } else {
                
                [args addObject:value];
                
            }
            
            [names addObject:name];
        }
        
    }

    NSUInteger count = names.count;
    
    for(int i = 0; i < count; i++) {
        NSString* name = names[i];
        [sql_names appendString:name];
        [sql_values appendString:@"?"];
        if (i != count - 1) {
            [sql_names appendString:@","];
            [sql_values appendString:@","];
        }
    }

    NSString* sql = [NSString stringWithFormat:@"insert into %@ (%@) values (%@)",
                     _tableName, sql_names, sql_values];
    BOOL ret = [_db executeUpdate:sql withArgumentsInArray:args];
    
    long rowid = (long)[_db lastInsertRowId];
    [object setPrimaryId:rowid];

    return ret;
}

-(BOOL) insertObjects:(NSArray*)objects {
    [_db beginTransaction];
    
    for (id obj in objects) {
        [self insertObject:obj];
    }
    
    return [_db commit];
}

-(BOOL) objectsExistWithCondition:(NSString*)condition, ... {
    NSString* sql = nil;
    if (condition) {
        NSString* format = [NSString stringWithFormat:@"select * from %@ %@", _tableName, condition];
        va_list args;
        va_start(args, condition);
        sql = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        
    } else {
        sql = [NSString stringWithFormat:@"select * from %@", _tableName];
    }
    
    FMResultSet* rs = [_db executeQuery:sql];
    BOOL exist = [rs next];
    
    [rs close];
    
    return exist;
}

-(NSArray*) objectsWithSQL:(NSString*)sql {
    NSMutableArray* array = [[NSMutableArray alloc] init];
    NSDictionary* format = [_clazz SQLFormat];
    
    FMResultSet* rs = [_db executeQuery:sql];
    
    while ([rs next]) {
        id object = [[(Class)_clazz alloc] init];
        for (NSString* name in format.allKeys) {
            NSString* type = format[name];
            id value = [rs objectForColumnName:name];
            if (value == [NSNull null]) {

                //[object setValue:nil forKey:name];
                
            } else {
                //if ([type isEqual:@"object"] || [type isEqual:@"collection"]) {
                if ([type isEqual:@"blob"]) {
                    
                    NSData* data = (NSData*)value;
                    //                    NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
                    //                    id value2 = [unarchiver decodeObjectForKey:name];
                    id value2 = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                    
                    [object setValue:value2 forKey:name];
                    
                } else {
                    
                    [object setValue:value forKey:name];
                }
                
            }
        }
        
        [object setValue:[rs objectForColumnName:@"id"] forKey:@"primaryId"];
        
        [array addObject:object];
    }
    
    [rs close];
    
    return array;
}

-(NSArray*) objectsWithCondition:(NSString*)condition, ... {

    NSString* sql = nil;
    if (condition) {
        NSString* format = [NSString stringWithFormat:@"select * from %@ %@", _tableName, condition];
        va_list args;
        va_start(args, condition);
        sql = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        
    } else {
        sql = [NSString stringWithFormat:@"select * from %@", _tableName];
    }

    return [self objectsWithSQL:sql];
}

-(NSArray*) allObjects {
    return [self objectsWithCondition:nil];
}

-(BOOL) removeObjectsWithCondition:(NSString*)condition, ... {
    NSString* sql = nil;
    
    if (condition) {
        NSString* format = [NSString stringWithFormat:@"delete from %@ %@", _tableName, condition];
        
        va_list args;
        va_start(args, condition);
        sql = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        
    } else {
        sql = [NSString stringWithFormat:@"delete from %@", _tableName];
    }
    
    BOOL ret = [_db executeUpdate:sql];
    
    return ret;
}

-(BOOL) removeAllObjects {
    return [self removeObjectsWithCondition:nil];
}

-(BOOL) removeObjects:(NSArray*)objects {
    [_db beginTransaction];
    
    for (id obj in objects) {
        [self removeObject:obj];
    }
    
    return [_db commit];
}

-(BOOL) removeObject:(id)object {
    //NSString* primary_key = [_clazz SQLPrimaryKey];
    //if (primary_key) {
        id pid = @([object primaryId]); //[object valueForKey:primary_key];
        NSString* sql = [NSString stringWithFormat:@"delete from %@ where id = ?", _tableName];
        return [_db executeUpdate:sql, pid];
    //}
    //return NO;
}

-(BOOL) updateObject:(id)object {
    //NSString* primary_key = [_clazz SQLPrimaryKey];
    //if (primary_key) {
        NSMutableString* sql_body = [[NSMutableString alloc] init];
        NSMutableArray* args = [[NSMutableArray alloc] init];
        
        NSDictionary* format = [_clazz SQLFormat];
        NSArray* names = format.allKeys;
        NSInteger count = names.count;
        for(int i = 0; i < count; i++) {
            NSString* name = names[i];
            [sql_body appendFormat:@"%@ = ?", name];
            if (i != count - 1) {
                [sql_body appendString:@","];
            }
            
            NSString* type = format[name];
            id value = [object valueForKey:name];
            if (value) {
                
                //if ([type isEqual:@"object"] || [type isEqual:@"collection"]) {
                if ([type isEqual:@"blob"]) {
                
//                    NSMutableData* data = [NSMutableData data];
//                    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
//                    [archiver encodeObject:value forKey:name];
//                    [archiver finishEncoding];
                    
                    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:value];
                    
                    [args addObject:data];
                    
                } else {
                    
                    [args addObject:value];
                    
                }
            
            } else {
            
                [args addObject:[NSNull null]];
                
            }
        }
    
        //[args addObject:[object valueForKey:primary_key]];
        [args addObject:@([object primaryId])];
    
        NSString* sql = [NSString stringWithFormat:@"update %@ set %@ where id = ?",
                         _tableName, sql_body];
        //NSLog(@"update sql: %@", sql);
    
        return [_db executeUpdate:sql withArgumentsInArray:args];
    
    //}
    //return NO;
}

-(BOOL) updateObjectWithCondition:(NSString*)condition, ... {
    va_list args;
    va_start(args, condition);
    
    NSString* format = [NSString stringWithFormat:@"update %@ set %@", _tableName, condition];
    NSString* sql = [[NSString alloc] initWithFormat:format arguments:args];
    
    va_end(args);
    
    return [_db executeUpdate:sql];
}

-(void) destroy {
    NSString* sql = [NSString stringWithFormat:@"drop table %@", _tableName];
    [_db executeUpdate:sql];
}

@end









