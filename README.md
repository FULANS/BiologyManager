# BiologyManager
TouchID、FaceID


1. 将 BiologyID 托入工程
2. #import "LKBiologyIDManager.h"

API :
1. - (BOOL)lk_canDeviceSupport ;  // 判断设备是否支持生物解锁 (硬件)
2. - (LKBiometryType)lk_getDeviceBiometryType; // 获取设备支持的解锁类型
3. - (void)lk_showBiologyIDWithInfo:(NSString *)desc State:(LKBiologyIDStateBlock)block; // 调用识别方法


#pragma mark --- 公司层具体业务!!!
1. - (BOOL)lk_IsOpenBiologyFunctionWithUserID:(NSString *)userid;  // 判断用户 在App中是否设置了 使用 指纹 / 面容ID 的权限

2. - (void)lk_changeBiologyFunctionState:(LKChangeState)state
UserID:(NSString *)userid
Pwd:(NSString *)pwd;  // 用户 在 App内部打开 / 关闭 指纹/面容ID 的操作

3. - (NSString *)lk_getPwdWithUserId:(NSString *)userId;  // 根据 传入的用户的 userid 获取 本地缓存的密码

其中公司层业务涉及到的加密处理,使用的是AES256 (用的其他大佬写的类)  若用不到就删除掉对应的公司层业务代码或者对于加密不加密无所谓可直接无视即可 !!!


更新说明:
1. 这个类在X出来之前 只做了TouchID的功能,  最近加了FaceID的处理判断
2. 苹果爸爸对开发者很友好, 两者功能对应的API基本相同,所以调整不大
3. FaceID需要在info.plist中增加NSFaceIDUsageDescription权限申请说明



模拟器测试方法 Usage:

选中模拟器，菜单栏--> Hardware --> Face ID/Touch ID
Enrolled                                   相当于已经设置了Face ID或者Touch ID
Matching Touch/Matching Face               匹配ID
Non-matching Touch/Non-matching Face       不匹配


