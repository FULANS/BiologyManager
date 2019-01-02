//
//  NSData+AES256.m
//  AESDemo
//
//  Created by zyx on 2018/1/24.
//  Copyright © 2018年 zyx. All rights reserved.
//

#import "NSData+AES256.h"



@implementation NSData (AES256)
//  加密
-(NSData *) aes256_encrypt:(NSString *)key
{
    // 定义一个字符数组keyPtr，元素个数是kCCKeySizeAES256+1
    // AES256加密，密钥应该是32位的
    char keyPtr[kCCKeySizeAES256+1];
    // [sizeof](keyPtr) 数组keyPtr所占空间的大小，即多少个个字节
    // bzero的作用是字符数组keyPtr的前sizeof(keyPtr)个字节为零且包括‘\0’。就是前32位为0，最后一位是\0
    bzero(keyPtr,sizeof(keyPtr));
    // NSString转换成C风格字符串
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [self length];
    // buffer缓冲，缓冲区
    //  对于块加密算法：输出的大小<= 输入的大小 +  一个块的大小
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    //  *malloc()*函数其实就在内存中找一片指定大小的空间
    void *buffer = malloc(bufferSize);
    // size_t的全称应该是size type，就是说“一种用来记录大小的数据类型”。通常我们用sizeof(XXX)操作，这个操作所得到的结果就是size_t类型。
    // 英文翻译：num 数量 Byte字节  encrypt解密
    size_t numBytesEncrypted = 0;
    // **<CommonCrypto/CommonCryptor.h>框架下的类与方法**p苹果提供的
    CCCryptorStatus cryptStatus = CCCrypt(
                                          kCCEncrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr,
                                          kCCBlockSizeAES128,
                                          NULL,
                                          [self bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    } 
    free(buffer);
    return nil;
}

- (NSData *)aes256_decrypt:(NSString *)key
{
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength: sizeof(keyPtr) encoding:NSUTF8StringEncoding];
     NSUInteger dataLength = [self length];
     size_t bufferSize = dataLength + kCCBlockSizeAES128;
     void *buffer = malloc(bufferSize);
     size_t numBytesDecrypted = 0;
     CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding | kCCOptionECBMode,keyPtr, kCCBlockSizeAES128, NULL,[self bytes], dataLength, buffer, bufferSize,  &numBytesDecrypted);
     if (cryptStatus == kCCSuccess) {
         return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
     }
     free(buffer);
     return nil;
     }

@end
