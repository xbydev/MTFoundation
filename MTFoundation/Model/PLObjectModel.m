//
//  PLObjectModel.m
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/21.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import "PLObjectModel.h"
#import <objc/runtime.h>

@implementation PLObjectModel

+(NSDictionary *)definedPropertyTypes {
    return nil;
}

+(NSDictionary *)definedSqlProperties {
    return nil;
}

+(id) objectWithProps:(NSDictionary*)props {
    return [[self alloc] initWithProperties:props];
}

-(id) initWithProperties:(NSDictionary*)props {
    if (self = [super init]) {
        NSDictionary* types = [[self class] definedPropertyTypes];
        NSNull* null = [NSNull null];
        
        for (NSString* key in props.allKeys) {
            id value = props[key];
            if (value != null) {
                if ([value isKindOfClass:[NSDictionary class]]) {
                    Class clazz = types[key];
                    if (clazz) {
                        id obj = [[clazz alloc] initWithProperties:value];
                        [self setValue:obj forKey:key];
                        continue;
                    }
                } else if ([value isKindOfClass:[NSArray class]]) {
                    Class clazz = types[key];
                    if (clazz) {
                        NSArray* array = (NSArray*)value;
                        NSMutableArray* array2 = [NSMutableArray arrayWithCapacity:array.count];
                        for (id value in array) {
                            id obj = [[clazz alloc] initWithProperties:value];
                            [array2 addObject:obj];
                        }
                        [self setValue:array2 forKeyPath:key];
                        continue;
                    }
                }
                [self setValue:value forKey:key];
            }
        }
        
    }
    
    return self;
}

-(void)setValue:(id)value forUndefinedKey:(NSString *)key {
    NSLog(@"meet undefined key: %@", key);
}

-(void)setNilValueForKey:(NSString *)key {
    NSLog(@"set nil value for key: %@", key);
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    Class cls = [self class];
    while (cls != [NSObject class]) {
        unsigned int numberOfIvars = 0;
        Ivar* ivars = class_copyIvarList(cls, &numberOfIvars);
        for(const Ivar* p = ivars; p < ivars+numberOfIvars; p++)
        {
            Ivar const ivar = *p;
            const char *type = ivar_getTypeEncoding(ivar);
            NSString *key = [NSString stringWithUTF8String:ivar_getName(ivar)];
            if (key == nil){
                continue;
            }
            if ([key length] == 0){
                continue;
            }
            id value = [self valueForKey:key];
            if (value) {
                switch (type[0]) {
                    case _C_STRUCT_B: {
                        NSUInteger ivarSize = 0;
                        NSUInteger ivarAlignment = 0;
                        NSGetSizeAndAlignment(type, &ivarSize, &ivarAlignment);
                        NSData *data = [NSData dataWithBytes:
                                        (const char *)(__bridge void*)self +
                                        ivar_getOffset(ivar)
                                                      length:ivarSize];
                        [encoder encodeObject:data forKey:key];
                    }
                        break;
                    default:
                        [encoder encodeObject:value forKey:key];
                        break;
                }
            }
        }
        if (ivars) {
            free(ivars);
        }
        
        cls = class_getSuperclass(cls);
    }
}

- (id)initWithCoder:(NSCoder *)decoder {
    
    self = [super init];
    
    if (self) {
        Class cls = [self class];
        while (cls != [NSObject class]) {
            unsigned int numberOfIvars = 0;
            Ivar* ivars = class_copyIvarList(cls, &numberOfIvars);
            
            for(const Ivar* p = ivars; p < ivars+numberOfIvars; p++)
            {
                Ivar const ivar = *p;
                const char *type = ivar_getTypeEncoding(ivar);
                NSString *key = [NSString stringWithUTF8String:ivar_getName(ivar)];
                if (key == nil){
                    continue;
                }
                if ([key length] == 0){
                    continue;
                }
                id value = [decoder decodeObjectForKey:key];
                if (value) {
                    switch (type[0]) {
                        case _C_STRUCT_B: {
                            NSUInteger ivarSize = 0;
                            NSUInteger ivarAlignment = 0;
                            NSGetSizeAndAlignment(type, &ivarSize, &ivarAlignment);
                            NSData *data = [decoder decodeObjectForKey:key];
                            char *sourceIvarLocation = (char*)(__bridge void*)self+ ivar_getOffset(ivar);
                            [data getBytes:sourceIvarLocation length:ivarSize];
                            memcpy((char *)(__bridge void*)self + ivar_getOffset(ivar), sourceIvarLocation, ivarSize);
                        }
                            break;
                        default:
                            [self setValue:value forKey:key];
                            break;
                    }
                }
            }
            
            if (ivars) {
                free(ivars);
            }
            cls = class_getSuperclass(cls);
        }
    }
    
    return self;
}

@end
