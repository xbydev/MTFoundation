//
//  MTFileManager.h
//  MTFoundation
//
//  Created by xiangbiying on 2018/7/21.
//

#import <Foundation/Foundation.h>

@interface MTFileManager : NSObject
/**
 获取沙盒Document的文件目录
 */
+ (NSString *)getDocumentDirectory;

/**
 获取沙盒Library的文件目录
 */
+ (NSString *)getLibraryDirectory;

/**
 获取沙盒Library/Caches的文件目录
 */
+ (NSString *)getCachesDirectory;

/**
 获取沙盒Preference的文件目录
 */
+ (NSString *)getPreferencePanesDirectory;

/**
 获取沙盒tmp的文件目录
 */
+ (NSString *)getTmpDirectory;

/**
 创建缓存目录
 @param dirName 目录文件夹名称（默认为Document目录下）
 @return 返回文件夹完整路径
 */
+ (NSString *)createCacheFileDir:(NSString *)dirName;

/**
 判断文件是否存在
 @param path 文件路径
 */
+ (BOOL)fileExistsAtPath:(NSString *)path;

/**
 根据路径返回目录或文件的大小,单位MB
 @param path 路径
 */
+ (double)sizeWithFilePath:(NSString *)path;


/**
 得到指定目录下的所有文件
 @param dirPath 指定目录
 */
+ (NSArray *)getAllFileNames:(NSString *)dirPath;


/**
 删除指定目录或文件
 @param path 路径
 */
+ (BOOL)clearCachesWithFilePath:(NSString *)path;

/**
 清空指定目录下文件
 @param dirPath 路径
 */
+ (BOOL)clearCachesFromDirectoryPath:(NSString *)dirPath;
@end
