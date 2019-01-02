//
//  LKBiologyIDManager.m
//  LiemsMobileEnterprise
//
//  Created by wangzheng on 17/7/4.
//  Copyright © 2017年 Jasper. All rights reserved.
//


#import "LKBiologyIDManager.h"
#import "NSString+AES256.h"

#define LKTouchOpenUserCache [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"LKTouchOpenUserCache.plist"]

#define AES256_KEY @"WZheng"

static CGFloat const kMinimumDismissTimeInterval = 1.0f;

@interface LKBiologyIDManager ()

@property (nonatomic, retain) LAContext *context;
@property (nonatomic, strong) NSMutableArray <NSMutableDictionary *>*openCacheArr;
/*@"userid":@"SYS",@"pwd":@"1234",@"state":@"NO"*/

@end

@implementation LKBiologyIDManager

+ (instancetype)sharedTheSingletion {
    static LKBiologyIDManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[LKBiologyIDManager alloc] init];
        manager.context = [[LAContext alloc] init];
        NSMutableArray *cache = [NSMutableArray arrayWithContentsOfFile:LKTouchOpenUserCache];
        manager.openCacheArr = cache ? : [NSMutableArray array];
    });
    return manager;
}

- (BOOL)lk_canDeviceSupport {
    LKBiometryType type = [self lk_getDeviceBiometryType];
    if(type == LKBiometryTypeNone){
        return NO;
    }else{
        return YES;
    }
}

- (LKBiometryType)lk_getDeviceBiometryType{
    
    if (NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_8_0) {
        return LKBiometryTypeNone;
    }
    
    NSError *error = nil;
    
    if ([self.context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]){
        if (@available(iOS 11.0, *)){ // 面容识别在X开始才有, 系统只会是11.0以后
            if (self.context.biometryType == LABiometryTypeTouchID) {
                return LKBiometryTypeTouchID;
            }else if(self.context.biometryType == LABiometryTypeFaceID){
                return LKBiometryTypeFaceID;
            }else{
                return LKBiometryTypeNone;
            }
        }else{
            return LKBiometryTypeTouchID;
        }
    }else{
        // 说明不具备: // NSLocalizedDescription
        switch (error.code) {
            case -6:
                NSLog(@"当前设备不支持BiologyID");
                return LKBiometryTypeNone;
                break;
            case -8:
                NSLog(@"属于多次错误,无法识别");
                if(@available(iOS 11.0, *)){
                    if (self.context.biometryType == LABiometryTypeTouchID) {
                        return LKBiometryTypeTouchID;
                    }else if(self.context.biometryType == LABiometryTypeFaceID){
                        return LKBiometryTypeFaceID;
                    }else{
                        return LKBiometryTypeNone;
                    }
                }else{
                    return LKBiometryTypeTouchID;
                }
                break;
            default:
                return LKBiometryTypeNone;
                break;
        }
    }
}


-(void)lk_showBiologyIDWithInfo:(NSString *)desc State:(LKBiologyIDStateBlock)block{
    
    if (NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_8_0) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"系统版本不支持BiologyID (必须高于iOS 8.0才能使用)");
            block(LKBiologyIDStateVersionNotSupport,nil);
        });
        
        return;
    }
    
    
    self.context.localizedFallbackTitle = desc;
    
    NSError *error = nil;
    
    if ([self.context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        
        // deviceOwnerAuthenticationWithBiometrics
        // LAPolicyDeviceOwnerAuthenticationWithBiometrics 生物指纹面容识别。 选择密码登陆时:dismiss掉指纹面容框, do youself   8.0
        // LAPolicyDeviceOwnerAuthentication 生物指纹面容识别或系统密码验证。 选择密码登陆时 / 或者多次指纹面容错误时 :弹出系统密码验证  9.0
        
        LAPolicy policy = LAPolicyDeviceOwnerAuthenticationWithBiometrics;
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_8_x_Max){
            policy = LAPolicyDeviceOwnerAuthentication; // 看业务需求 是否 需要弹出系统密码验证 !!!
        }
        
        NSString *mydesc = [self lk_IsFaceID] ? @"通过FaceID进行面部识别" : @"通过Home键验证已有指纹";
        
        [self.context evaluatePolicy:policy localizedReason:desc ? : mydesc reply:^(BOOL success, NSError * _Nullable error) {
            
            if (success) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.context evaluatedPolicyDomainState] != nil){
                        NSLog(@"BiologyID 验证成功");
                    }else{
                        NSLog(@"Biology ID 解锁成功"); // 系统密码输入成功
                    }
                    block(LKBiologyIDStateSuccess,error);
                });
                
            }else if(error){
                
                switch (error.code) {
                    case LAErrorAuthenticationFailed:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"BiologyID 多次匹配 验证失败"); // 此时手机已被锁定,需要去设置中设置
                            block(LKBiologyIDStateFail,error);
                            [self alertWithTitle:@"提示" message:[self lk_IsFaceID] ? @"面容不匹配" : @"指纹不匹配"];
                        });
                        break;
                    }
                    case LAErrorUserCancel:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"BiologyID 被用户手动取消");
                            block(LKBiologyIDStateUserCancel,error);
                        });
                    }
                        break;
                    case LAErrorUserFallback:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"用户不使用BiologyID,选择手动输入密码");
                            block(LKBiologyIDStateInputPassword,error);
                        });
                    }
                        break;
                    case LAErrorSystemCancel:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"BiologyID 被系统取消 (如遇到来电,锁屏,按了Home键等)");
                            block(LKBiologyIDStateSystemCancel,error);
                        });
                    }
                        break;
                    case LAErrorPasscodeNotSet:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"BiologyID 无法启动,因为用户没有设置密码");
                            block(LKBiologyIDStatePasswordNotSet,error);
                            [self alertWithTitle:@"提示" message:[self lk_IsFaceID] ? @"FaceID无法启动,请先设置手机密码" : @"TouchID无法启动,请先设置手机密码"];
                        });
                    }
                        break;
                    case LAErrorBiometryNotEnrolled:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"BiologyID 无法启动,因为用户没有设置BiologyID");
                            block(LKBiologyIDStateBiologyIDNotSet,error);
                            [self alertWithTitle:@"提示" message:[self lk_IsFaceID] ? @"FaceID无法启动,请先设置FaceID" : @"TouchID无法启动,请先设置TouchID"];
                        });
                    }
                        break;
                    case LAErrorBiometryNotAvailable:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"BiologyID 无效");
                            block(LKBiologyIDStateBiologyIDNotAvailable,error);
                        });
                    }
                        break;
                    case LAErrorBiometryLockout:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"BiologyID 被锁定(连续多次验证BiologyID失败,系统需要用户手动输入密码)");
                            block(LKBiologyIDStateBiologyIDLockout,error);
                            [self alertWithTitle:@"提示" message:[self lk_IsFaceID] ? @"FaceID已锁定,请至“设置 - 面容 ID 与 密码”解锁后重试" : @"TouchID已锁定,请至“设置 - 指纹 ID 与 密码”解锁后重试"];
                            
                            
                        });
                    }
                        break;
                    case LAErrorAppCancel:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"当前软件被挂起并取消了授权 (如App进入了后台等)");
                            block(LKBiologyIDStateAppCancel,error);
                        });
                    }
                        break;
                    case LAErrorInvalidContext:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"当前软件被挂起并取消了授权 (LAContext对象无效)");
                            block(LKBiologyIDStateInvalidContext,error);
                        });
                    }
                        break;
                    default:
                        break;
                }
            }
        }];
        
    }else{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            switch (error.code) {
                case -6:
                    NSLog(@"当前设备不支持BiologyID");
                    block(LKBiologyIDStateNotSupport,error);
                    [self alertWithTitle:@"提示" message:[self lk_IsFaceID] ? @"当前设备不支持FaceID" : @"当前设备不支持TouchID"];
                    break;
                    
                case -8:
                    NSLog(@"多次错误,无法识别");
                    block(LKBiologyIDStateCantEvaluate,error);
                    [self alertWithTitle:@"提示" message:[self lk_IsFaceID] ? @"FaceID已锁定,请至“设置 - 面容 ID 与 密码”解锁后重试" : @"TouchID已锁定,请至“设置 - 指纹 ID 与 密码”解锁后重试"];
                    break;
                    
                default:
                    break;
            }
            
            
        });
        
    }
    
}

#pragma mark - Business
- (BOOL)lk_IsOpenBiologyFunctionWithUserID:(NSString *)userid{
    
    if (![self lk_canDeviceSupport]) {
        return NO;
    }
    NSMutableDictionary *userDic = [self getUserInfoWithUserId:userid];
    if (!userDic) {
        return NO;
    }
    return [userDic[@"state"] isEqualToString:@"YES"];
}

- (void)lk_needBiologyIDWithUserID:(NSString *)userid
                            Action:(LKBiologyIDStateBlock)callback{
    
    if (![self lk_IsOpenBiologyFunctionWithUserID:userid]) {
        !callback ? : callback(LKBiologyIDStateSuccess,nil); // 把没开也当做认证成功,外部判断就少写一点
    }else{
        [self lk_showBiologyIDWithInfo:nil State:callback];
    }
}

- (void)lk_changeBiologyFunctionState:(LKChangeState)state
                               UserID:(NSString *)userid
                                  Pwd:(NSString *)pwd{
    
    NSMutableDictionary *userDic = [self getUserInfoWithUserId:userid];
    
    if (!userDic) {
        userDic = [NSMutableDictionary dictionary];
        [self.openCacheArr addObject:userDic];
    }
    NSString *state_str = state== LKChangeStateOpen ? @"YES" : @"NO";
    [userDic setObject:state_str forKey:@"state"];
    [userDic setObject:userid forKey:@"userid"];
    [userDic setObject:[pwd aes256_encrypt:AES256_KEY] forKey:@"pwd"];
    // 重新写入本地
    if ([self.openCacheArr writeToFile:LKTouchOpenUserCache atomically:YES]) {
        NSLog(@"插入成功");
    }else{
        NSLog(@"插入失败");
    }
}

- (NSString *)lk_getPwdWithUserId:(NSString *)userId{
    
    NSDictionary *result = [self getUserInfoWithUserId:userId];
    NSString *pwd = result[@"pwd"];
    pwd = [pwd aes256_decrypt:AES256_KEY];
    return pwd;
}


- (NSMutableDictionary *)getUserInfoWithUserId:(NSString *)userid{
    
    __block NSMutableDictionary *result;
    
    [self.openCacheArr enumerateObjectsUsingBlock:^(NSMutableDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj[@"userid"] isEqualToString:userid]) {
            result = obj;
            *stop = YES;
        }
    }];
    return result;
}



#pragma mark - Assit Action
- (void)alertWithTitle:(NSString *)title message:(NSString *)message{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle:(UIAlertControllerStyleAlert)];
    UIViewController *current_vc = [self getAppCurrentVC];
    NSTimeInterval time = [self displayDurationForString:message];
    [current_vc presentViewController:alert animated:YES completion:^{
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
        
    }];
}


- (NSTimeInterval)displayDurationForString:(NSString*)string {
    return MAX((float)string.length * 0.06 + 0.5, kMinimumDismissTimeInterval);
}

- (UIViewController *)getAppCurrentVC{
    
    return [self findCorrectViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
}

- (UIViewController *)findCorrectViewController:(UIViewController *)vc{
    
    if (vc.presentedViewController) {
        return [self findCorrectViewController:vc.presentedViewController];
    }
    else if ([vc isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController *svc = (UISplitViewController *)vc;
        
        if (svc.viewControllers.count) {
            return [self findCorrectViewController:svc.viewControllers.lastObject];
        }else{
            return vc;
        }
    }
    else if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nvc = (UINavigationController *)vc;
        
        if (nvc.viewControllers.count) {
            return [self findCorrectViewController:nvc.topViewController];
        }else{
            return vc;
        }
    }
    else if ([vc isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tvc = (UITabBarController *)vc;
        
        if (tvc.viewControllers.count) {
            return [self findCorrectViewController:tvc.selectedViewController];
        }else{
            return vc;
        }
    }
    else{
        return vc;
    }
}

- (BOOL)lk_IsFaceID {
    LKBiometryType type = [self lk_getDeviceBiometryType];
    if(type == LKBiometryTypeFaceID){
        return YES;
    }else{
        return NO;
    }
}


@end
