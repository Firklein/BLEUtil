//
//  BLEManager.h
//  BleManager
//
//  Created by csj on 2016/11/17.
//  Copyright © 2016年 csj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

/**
 *  蓝牙特征以及服务通道
 **/
static NSString *kCharacteristicUUID        =   @"0xFFB2";
static NSString *kServiceOne                =   @"0xFFB0";


/**
 *  蓝牙数据回调
 **/
@protocol BLEDelegate <NSObject>

/**
 *  发现周边蓝牙设备
 **/
- (void)didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;

/**
 *  接受到蓝牙返回数据的处理
 **/
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic;

/**
 *  判断蓝牙是否可用
 **/
- (void)bleUsable:(BOOL) isUsable;

/**
 *  蓝牙的连接状态
 **/
- (void)bleStates:(BOOL) isConnect;

@end

@interface BLEManager : NSObject

/**
 *  回调的代理
 **/
@property (weak, nonatomic) id<BLEDelegate> bleDategate;

/**
 *  搜索蓝牙设备
 **/
- (void)scanBle;

/**
 *  停止搜索蓝牙设备
 **/
- (void)stopScan;

/**
 *  连接蓝牙设备
 **/
- (void)connectPeripheral:(CBPeripheral *)peripheral;

/**
 *  断开蓝牙连接
 **/
- (void)disConnectPeripheral;

/**
 *  发指令给蓝牙设备
 **/
- (void)writeValue:(NSData *)bleData;


#pragma mark - 数据指令处理
/**
 *  数据确认指令 0xae
 **/
- (void)sendConfirm;

/**
 *  请求固件版本0xab
 **/
- (void)requestDevVersion;

/**
 *  密码绑定设备0xa1
 **/
- (void)bindDev:(NSString *)pwStr;

/**
 *  请求时间同步 0xa0
 **/
- (void)syncTime;

/**
 *  请求设备日志0xaa
 **/
- (void)requestDevLog;

/**
 *  请求设备状态0xa8
 **/
- (void)requestDevState;

/**
 *  请求数据0xa7
 **/
-(void)requestDevDataFrom:(NSInteger)from toPosition:(NSInteger)position;

/**
 *  请求设备参比指血0xa3
 **/
- (void)requestDevRef;

/**
 *  请求告警线的临界值
 **/
- (void) requestAlarmData;

/**
 *  请求设备电压0xa5
 **/
- (void)requestDevVoltage;

/**
 *  获取单例manager
 **/
+ (instancetype)shareManager;

@end
