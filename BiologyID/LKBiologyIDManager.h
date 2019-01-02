//
//  LKBiologyIDManager.h
//  LiemsMobileEnterprise
//
//  Created by wangzheng on 17/7/4.
//  Copyright © 2017年 Jasper. All rights reserved.
//
/*
 1.将TouchID 升级 为 BiologyID , 支持生物和面容
 2.两者功能对应的API基本相同，只要在TouchID的基础上调整一些描述即可
 3.FaceID需要在info.plist中增加NSFaceIDUsageDescription权限申请说明
 */
#import <LocalAuthentication/LocalAuthentication.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, LKBiologyIDState) {
    
    LKBiologyIDStateNotSupport = 0, // 当前设备不支持BiologyID
    LKBiologyIDStateSuccess = 1,  // BiologyID 验证成功
    LKBiologyIDStateFail = 2,  // BiologyID 验证失败
    LKBiologyIDStateUserCancel = 3, // BiologyID 被用户手动取消
    LKBiologyIDStateInputPassword = 4, // 用户不使用BiologyID,选择手动输入密码
    LKBiologyIDStateSystemCancel = 5,  // BiologyID 被系统取消 (如遇到来电,锁屏,按了Home键等)
    LKBiologyIDStatePasswordNotSet = 6, // BiologyID 无法启动,因为用户没有设置密码
    LKBiologyIDStateBiologyIDNotSet = 7, // BiologyID 无法启动,因为用户没有设置BiologyID
    LKBiologyIDStateBiologyIDNotAvailable = 8, // BiologyID 无效
    LKBiologyIDStateBiologyIDLockout = 9, // BiologyID 被锁定(连续3次验证BiologyID失败,系统需要用户手动输入密码)
    LKBiologyIDStateAppCancel = 10, // 当前软件被挂起并取消了授权 (如App进入了后台等)
    LKBiologyIDStateInvalidContext = 11, // 当前软件被挂起并取消了授权 (LAContext对象无效)
    LKBiologyIDStateVersionNotSupport = 12, // 系统版本不支持BiologyID (必须高于iOS 8.0才能使用)
    LKBiologyIDStateCantEvaluate = 13, // 3次之后再点击,再点击直接,直接无法响应 生物
};

typedef NS_ENUM(NSUInteger, LKChangeState) {
    
    LKChangeStateClose = 0, // 关闭
    LKChangeStateOpen = 1,  // 开启
};

typedef NS_ENUM(NSUInteger, LKBiometryType) {
    
    LKBiometryTypeNone = 0,    // 硬件不支持
    LKBiometryTypeTouchID = 1, // 指纹
    LKBiometryTypeFaceID = 2,  // 面容
};


typedef void (^LKBiologyIDStateBlock)(LKBiologyIDState state,NSError *error);

@interface LKBiologyIDManager : LAContext

+ (instancetype)sharedTheSingletion;

/**
 判断设备是否支持生物解锁 (硬件)
 
 @return YES / NO
 */
- (BOOL)lk_canDeviceSupport;

/**
 设备生物验证类型
 
 @return 0:无  1:指纹  2:面容
 */
- (LKBiometryType)lk_getDeviceBiometryType;



/**
 启动BiologyID进行验证
 @param desc Touch显示的描述
 @param block 回调状态的block
 */
- (void)lk_showBiologyIDWithInfo:(NSString *)desc State:(LKBiologyIDStateBlock)block;



#pragma mark --- 公司具体业务!!!
/**
 判断 用户 在App中是否设置了 使用 指纹 / 面容ID 的权限 
 
 @param userid 当前登陆用户Id
 @return YES / NO
 */
- (BOOL)lk_IsOpenBiologyFunctionWithUserID:(NSString *)userid;

/**
 开关生物功能
 
 @param state 开 / 关
 @param userid 当前登陆用户Id
 @param pwd 当前登陆用户密码
 */
- (void)lk_changeBiologyFunctionState:(LKChangeState)state
                               UserID:(NSString *)userid
                                  Pwd:(NSString *)pwd;



/**
 根据 userid 获取 本地缓存的密码
 
 @param userId userid
 @return 解密之后的密码
 */
- (NSString *)lk_getPwdWithUserId:(NSString *)userId;


/**
 公司层:工作流封装的一个统一方法
 
 @param userid 当前登陆用户Id
 @param callback 回调
 */
- (void)lk_needBiologyIDWithUserID:(NSString *)userid
                            Action:(LKBiologyIDStateBlock)callback;




@end
