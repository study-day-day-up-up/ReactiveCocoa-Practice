//
//  RACPlayground.m
//  reactivecocoa_practise
//
//  Created by ZangChengwei on 16/6/19.
//  Copyright © 2016年 ZangChengwei. All rights reserved.
//

#import "RACPlayground.h"
#import <ReactiveCocoa.h>

void sequence();
void rac_playground()
{
    RACSignal *signal = [RACSignal return:@1];
    [signal subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    
    sequence();
}

int factorial1(int x) {
    int result = 1;
    for (int i = 1; i <= x; ++i) {
        result *= i;
    }
    return result;
}

int factorial2(int x) {
    if (x == 1) return 1;
    return x * factorial2(x - 1);
}


void test() {
    int a = 5;
    int b = 6;
    int c = a + b;
    a = 10;
    NSLog(@"%d", c);
    
}

//sequence的例子
void sequence() {
    
    //RACSequence 三种创建方式
    //1.基本创建方式
    RACSequence *sequence1 = [RACSequence return:@1];
    
    //2.给一个头，给一个身体，然后合并起来
    RACSequence *sequence2 = [RACSequence sequenceWithHeadBlock:^id{
        return @2;
    } tailBlock:^RACSequence *{
        return sequence1;
    }];
    
    //3.根据cocoa下的桥接的特性创建出来的，比如数组和字典等等，详情可以看rac_sequence的方法源码实现
    RACSequence *sequence3 = @[@1, @2, @3].rac_sequence;
    
    
    //RACSequence的变换方式
    //map变换，针对sequence每个值依次变化
    RACSequence *mappedSequence = [sequence1 map:^id(NSNumber *value) {
        return @(value.integerValue * 3);
    }];
    
    //concat变换，把2个sequence连接到一起
    RACSequence *concatedSequence = [sequence2 concat:mappedSequence];
    
    //zip变换，把2个sequence每2个一一对应的拼接到一起
    RACSequence *mergedSequence = [RACSequence zip:@[concatedSequence, sequence3]];
    
    
    //RACSequence的遍历 两种方式
    //1.先取head，再取身体，从身体里再取head，依次取下去
    NSLog(@"head is %@", mergedSequence.head);
    
    //2.最普遍的就是for-in，这里也是有一个桥接的方法，能把Sequence变回NSArray
    for (id value in mergedSequence) {
        NSLog(@"value is %@", value);
    }
    
}
UIView *someObject = nil;
void signalExample() {
    
    // RACSignal 三种创建方式
    //1.用return 得到简单的RACSignal
    id self = nil;
    RACSignal *signal1 = [RACSignal return:@"hello"];
    
    //2.用createSignal创建一个动态的RACSignal
    RACSignal *signal2 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        [subscriber sendCompleted];
        return nil;
    }];
    
    //3.根据cocoa下的桥接的特性创建出来的，详情可以看RACObserve的方法源码实现
    RACSignal *signal3 = RACObserve(someObject, frame);
    
    
    //RACSequence的变换方式
    //map变换
    RACSignal *mappedSignal = [signal1 map:^id(NSString *value) {
        return [value stringByAppendingString:@" world"];
    }];
    
    //concat变换
    RACSignal *concatedSignal = [mappedSignal concat:signal2];
    
    //merge变换
    RACSignal *mergeSignal = [RACSignal merge:@[concatedSignal, signal3]];
    
    
    //RACSequence的遍历 订阅的方法进行
    [mergeSignal subscribeNext:^(id x) {
        NSLog(@"next is %@", x);
    } completed:^{
        NSLog(@"completed");
    }];
    
    
}

RACSignal *makeTimer(int times) {
    RACSignal *timer = [RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]];
    return [[[timer scanWithStart:@(times) reduce:^id(NSNumber *running, id _) {
        return @(running.intValue - 1);
    }] startWith:@(times)]
            takeUntilBlock:^BOOL(NSNumber *x) {
                return x.intValue == 0;
            }];
}

typedef int(^intFunc)(int a);

intFunc addX(int x) {
    return ^int(int p) {
        return x + p;
    };
}

intFunc transparent(intFunc origin) {
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    return ^int(int p) {
        if (results[@(p)]) {
            return [results[@(p)] intValue];
        }
        results[@(p)] = @(origin(p));
        return [results[@(p)] intValue];
    };
}




intFunc other(intFunc intFunc1) {
    return ^int(int p) {
        return -intFunc1(p);
    };
}

void testAddX() {
    intFunc fun1 = addX(5);
    intFunc fun2 = other(fun1);
    
    intFunc fun3 = transparent(fun2);
    
    int result = fun3(7);
    int result2 = fun3(7);
}

void test3() {
    NSArray *a = @[@1, @2, @3];
    // a <*> (* 10)
    NSMutableArray *array = [NSMutableArray array];
    for (NSNumber *v in a) {
        [array addObject:@(v.integerValue * 10)];
    }
    id v = array[2];
    
}

void test4() {
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        [subscriber sendNext:@3];
        [subscriber sendCompleted];
        return nil;
    }];
    
    __block int collection = 0;
    [signal subscribeNext:^(id x) {
        collection += [x intValue];
    }];
    
    [signal aggregateWithStart:@0 reduce:^id(NSNumber *running, NSNumber *next) {
        return @(running.intValue + next.intValue);
    }];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"%@ is the result", x);
    }];
    
    
    
}



int max(int *array, int count)
{
    if (count == 1)
        return array[0];
    
    return array[0] > max(array + 1, count - 1)? array[0] : max(array + 1, count - 1);
}


func absSort (arr : [Int]) -> [Int] {
    return arr.sorted
}



func averageOfFunction(a:Float,b:Float,f:(Float -> Float)) -> Float {
    return (f(a) + f(b)) / 2
}

averageOfFunction(3, 4, square)a

verageOfFunction(3, 4, cube)


























