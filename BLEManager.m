//
//  BLEManager.m
//  BleManager
//
//  Created by csj on 2016/11/17.
//  Copyright © 2016年 csj. All rights reserved.
//

#import "BLEManager.h"

@interface BLEManager ()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic ,strong) CBCentralManager      *bleManager;

/*
 *  蓝牙
 */
@property (nonatomic ,strong) CBPeripheral          *peri;

/*
 *  蓝牙特性
 */
@property (nonatomic ,strong) CBCharacteristic      *cha;

@end

@implementation BLEManager

+ (instancetype)shareManager {
    static BLEManager   *_manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[BLEManager alloc] init];
        _manager.bleManager = [[CBCentralManager alloc] initWithDelegate:_manager queue:nil];
    });
    return _manager;
}

#pragma mark - 蓝牙数据辅助功能
/**
 *  计算得出校验码
 **/
- (Byte)getVerifyFromData:(Byte *)temp andLength:(NSInteger)length {
    Byte k = 0x0;
    for (NSInteger i = 0; i < length; i++) {
        k = k ^ temp[i];
    }
    return (Byte)k;
}

/**
 *  校验数据是否正确
 **/
- (BOOL)verifyData:(Byte *)temp andLength:(NSInteger)length {
    if ([self getVerifyFromData:temp andLength:length -1] == temp[length -1]) {
        return YES;
    }
    return NO;
}

#pragma mark - 蓝牙连接的基本方法
/**
 *  搜索蓝牙设备
 **/
- (void)scanBle {
    if (self.bleManager && self.peri) {
        [self.bleManager cancelPeripheralConnection:self.peri];
        self.peri = nil;
    }
    [self.bleManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kServiceOne]]
                                            options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
}

/**
 *  停止扫描蓝牙设备
 **/
- (void)stopScan {
    [self.bleManager stopScan];
}

/**
 *  连接蓝牙设备
 **/
- (void)connectPeripheral:(CBPeripheral *)peripheral {
    if (peripheral) {
        [self.bleManager connectPeripheral:peripheral
                                   options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES}];
    }
}

/**
 *  断开蓝牙设备
 **/
- (void)disConnectPeripheral {
    if (self.bleManager && self.peri) {
        [self.bleManager cancelPeripheralConnection:self.peri];
        if (self.bleDategate && [self.bleDategate respondsToSelector:@selector(bleStates:)]) {
            [self.bleDategate bleStates:NO];
        }
    }
}

/**
 *  发送指令给蓝牙设备
 **/
- (void)writeValue:(NSData *)bleData {
    if (self.peri && self.cha) {
        [self.peri writeValue:bleData
            forCharacteristic:self.cha
                         type:CBCharacteristicWriteWithoutResponse];
    }
}

#pragma mark - 蓝牙本身代理的函数
/**
 *  查看蓝牙是否处于可用状态
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBCentralManagerStatePoweredOn) {
        if (self.bleDategate && [self.bleDategate respondsToSelector:@selector(bleUsable:)]) {
            [self.bleDategate bleUsable:YES];
        }
    } else {
        if (self.bleDategate && [self.bleDategate respondsToSelector:@selector(bleUsable:)]) {
            [self.bleDategate bleUsable:NO];
        }
    }
}

/**
 *  发现周边蓝牙设备
 **/
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if (self.bleDategate && [self.bleDategate respondsToSelector:@selector(didDiscoverPeripheral:advertisementData:RSSI:)]) {
        [self.bleDategate didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    }
}

/**
 *  发现设备服务
 **/
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"发现服务出错: %@", [error localizedDescription]);
        return;
    }
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceOne]]) {
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kCharacteristicUUID]] forService:service];
        }
    }
}

/**
 *  发现特征服务
 **/
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService: (CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"发现特性出错: %@", [error localizedDescription]);
        return;
    }
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceOne]]) {
        for (CBCharacteristic *cbcts in service.characteristics) {
            if ([cbcts.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]]) {
                self.cha = cbcts;
                [peripheral setNotifyValue:YES forCharacteristic:cbcts];
                if (self.bleDategate && [self.bleDategate respondsToSelector:@selector(bleStates:)]) {
                    [self.bleDategate bleStates:YES];
                }
            }
        }
    }
}

/**
 *  设备连接成功
 **/
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    self.peri = peripheral;
    [peripheral setDelegate:self];
    [peripheral discoverServices:@[[CBUUID UUIDWithString:kServiceOne]]];
}

/**
 *  设备连接失败
 **/
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    if (self.bleDategate && [self.bleDategate respondsToSelector:@selector(bleStates:)]) {
        [self.bleDategate bleStates:NO];
    }
}

/**
 *  蓝牙断开连接的通知
 **/
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (self.bleDategate && [self.bleDategate respondsToSelector:@selector(bleStates:)]) {
        [self.bleDategate bleStates:NO];
    }
    self.peri = nil;
}

/**
 *  监听蓝牙连接状态
 **/
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"蓝牙监听出错: %@", error.localizedDescription);
        return;
    }
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]]) {
        if (characteristic.isNotifying) {
            
        } else {
            if (self.bleDategate && [self.bleDategate respondsToSelector:@selector(bleStates:)]) {
                [self.bleDategate bleStates:NO];
            }
            [self.bleManager cancelPeripheralConnection:peripheral];
        }
    }
}

/**
 *  收到蓝牙设备反馈的值
 **/
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"收到数据出错: %@", [error localizedDescription]);
        return;
    }
    if (self.bleDategate && [self.bleDategate respondsToSelector:@selector(peripheral:didUpdateValueForCharacteristic:)]) {
        [self.bleDategate peripheral:peripheral didUpdateValueForCharacteristic:characteristic];
    }
}


#pragma mark - 蓝牙数据指令处理 

/**
 *  数据确认指令 0xae
 **/
- (void)sendConfirm {
    Byte byte[] = {0x0f,0xae,0x00,0x00,0x00,0x00,0xa1};
    NSData *adata = [NSData dataWithBytes:byte length:sizeof(byte)/sizeof(Byte)];
    [self writeValue:adata];
    NSLog(@"发送确认指令:%@",adata);
}

/**
 *  绑定设备0xa1
 **/
- (void)bindDev:(NSString *)pwStr {
    NSInteger passwordValue = [pwStr intValue];
    Byte password1 = passwordValue / 0x100;
    Byte password2 = passwordValue % 0x100;
    Byte data[] = {0x0f,0xa1,password2,password1,0x00,0x00};
    Byte result = [self getVerifyFromData:data andLength:6];
    Byte byte[] = {0x0f,0xa1,password2,password1,0x00,0x00,result};
    NSData *adata = [NSData dataWithBytes:byte length:sizeof(byte)/sizeof(Byte)];
    [self writeValue:adata];
    NSLog(@"发送绑定指令:%@",adata);
}

/**
 *  请求时间同步 0xa0
 **/
- (void)syncTime {
    NSInteger timeInterval = [[NSDate date] timeIntervalSince1970];
    Byte high1 = timeInterval/0x1000000;
    Byte high2 = (timeInterval%0x1000000)/0x10000;
    Byte high3 = ((timeInterval%0x1000000)%0x10000)/0x100;
    Byte high4 = ((timeInterval%0x1000000)%0x10000)%0x100;
    Byte data[] = {0x0f,0xa0,high4,high3,high2,high1};
    Byte result = [self getVerifyFromData:data andLength:6];
    Byte byte[] = {0x0f,0xa0,high4,high3,high2,high1,result};
    NSData *adata = [NSData dataWithBytes:byte length:sizeof(byte)/sizeof(Byte)];
    [self writeValue:adata];
    NSLog(@"发送时间同步指令:%@",adata);
}

/**
 *  请求固件版本0xab
 **/
- (void)requestDevVersion {
    Byte byte[] = {0x0f,0xab,0x00,0x00,0x00,0x00,0xa4};
    NSData *adata = [NSData dataWithBytes:byte length:sizeof(byte)/sizeof(Byte)];
    [self writeValue:adata];
    NSLog(@"发送请求设备版本指令:%@",adata);
}

/**
 *  请求设备状态0xa8
 **/
- (void)requestDevState {
    Byte byte[] = {0x0f,0xa8,0x00,0x00,0x00,0x00,0xa7};
    NSData *adata = [NSData dataWithBytes:byte length:sizeof(byte)/sizeof(Byte)];
    [self writeValue:adata];
    NSLog(@"发送请求状态指令:%@",adata);
}

/**
 *  请求设备电压0xa5
 **/
- (void)requestDevVoltage {
    Byte byte[] = {0x0f,0xa5,0x00,0x00,0x00,0x00,0xaa};
    NSData *adata = [NSData dataWithBytes:byte length:sizeof(byte)/sizeof(Byte)];
    [self writeValue:adata];
    NSLog(@"发送请求电压指令:%@",adata);
}

/**
 *  请求设备参比指血0xa3
 **/
- (void)requestDevRef {
    Byte byte[] = {0x0f,0xa3,0x00,0x00,0x00,0x00,0xac};
    NSData *adata = [NSData dataWithBytes:byte length:sizeof(byte)/sizeof(Byte)];
    [self writeValue:adata];
    NSLog(@"发送请求参比指血指令:%@",adata);
}

/**
 *  请求设备日志0xaa
 **/
- (void)requestDevLog {
    Byte byte[] = {0x0f,0xaa,0x00,0x00,0x00,0x00,0xa5};
    NSData *adata = [NSData dataWithBytes:byte length:sizeof(byte)/sizeof(Byte)];
    [self writeValue:adata];
    NSLog(@"发送请求设备日志指令:%@",adata);
}

//请求告警线的临界值
- (void) requestAlarmData {
    Byte byte[] = {0x0f,0xac,0x00,0x00,0x00,0x00,0xa3};
    NSData *adata = [NSData dataWithBytes:byte length:sizeof(byte)/sizeof(Byte)];
    [self writeValue:adata];
    NSLog(@"发送请求告警值指令:%@",adata);

}

/**
 *  请求数据0xa7
 **/
-(void)requestDevDataFrom:(NSInteger)from toPosition:(NSInteger)position{
    Byte data[] = {0x0f,0xa7,from%0x100,from/0x100,position%0x100,position/0x100};
    Byte result = [self getVerifyFromData:data andLength:6];
    Byte data2[] = {0x0f,0xa7,from%0x100,from/0x100,position%0x100,position/0x100,result};
    NSData *adata = [NSData dataWithBytes:data2 length:sizeof(data2)/sizeof(Byte)];
    [self writeValue:adata];
    NSLog(@"发送请求设备数据指令:%@  %zd --> %zd",adata,from ,position);
}

@end
