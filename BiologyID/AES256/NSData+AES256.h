//
//  NSData+AES256.h
//  AESDemo
//
//  Created by zyx on 2018/1/24.
//  Copyright © 2018年 zyx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
@interface NSData (AES256)
-(NSData *) aes256_encrypt:(NSString*)key;//  加密
-(NSData *) aes256_decrypt:(NSString *)key;//  解密


@end
