/*
 * Copyright (C) 2026, LibreDarwin.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import <AppKit/NSKeyBinding.h>
#import <AppKit/NSKeyBinding_Private.h>
#import <objc/message.h>
#import <objc/runtime.h>

typedef id (*NSKeyBindingGetterFunction)(id, SEL, IMP);
typedef void (*NSKeyBindingSetterFunction)(id, SEL, id, IMP);

@interface _NSSelectorGetBinding : NSKeyGetBinding
{
	SEL getSel;
	IMP getMethod;
	void *get;
}
- (instancetype)initWithTargetClass:(Class)targetClass
    key:(NSString *)key
    function:(void *)function
    implementation:(IMP)implementation
    selector:(SEL)selector;
@end

@interface _NSSelectorSetBinding : NSKeySetBinding
{
	SEL setSel;
	IMP setMethod;
	void *set;
}
- (instancetype)initWithTargetClass:(Class)targetClass
    key:(NSString *)key
    function:(void *)function
    implementation:(IMP)implementation
    selector:(SEL)selector;
@end

@implementation NSKeyBinding
{
	Class _class;
	NSString *_key;
	void *_funcP;
}

+ (void)suppressCapitalizedKeyWarning
{
}

- (instancetype)initWithTargetClass:(Class)targetClass key:(NSString *)key
{
	if ((self = [super init]) != nil) {
		_class = targetClass;
		_key = [key copy];
		_funcP = NULL;
	}
	return (self);
}

- (void)setKey:(NSString *)key
{
	_key = [key copy];
}

- (NSString *)key
{
	return (_key);
}

- (Class)targetClass
{
	return (_class);
}

@end

@implementation NSKeyGetBinding

- (instancetype)init
{
	return ([super init]);
}

- (id)getValueFromObject:(id)object
{
	return ([object valueForKey:[self key]]);
}

+ (instancetype)lbs_bindingWithTargetClass:(Class)targetClass
    key:(NSString *)key
    function:(void *)function
    implementation:(IMP)implementation
    selector:(SEL)selector
{
	return ([[_NSSelectorGetBinding alloc] initWithTargetClass:targetClass
	    key:key function:function implementation:implementation
	    selector:selector]);
}

@end

@implementation NSKeySetBinding

- (instancetype)init
{
	return ([super init]);
}

- (BOOL)isScalarProperty
{
	return (NO);
}

- (void)setValue:(id)value inObject:(id)object
{
	NSString *key = [self key];

	if ([object respondsToSelector:@selector(takeValue:forKey:)]) {
		((void (*)(id, SEL, id, id))objc_msgSend)(object,
		    @selector(takeValue:forKey:), value, key);
		return;
	}
	if ([key length] == 0)
		return;
	NSString *suffix = [[key substringToIndex:1] uppercaseString];
	if ([key length] > 1)
		suffix = [suffix stringByAppendingString:[key substringFromIndex:1]];
	SEL setter = NSSelectorFromString([NSString stringWithFormat:@"set%@:", suffix]);

	if ([object respondsToSelector:setter])
		((void (*)(id, SEL, id))objc_msgSend)(object, setter, value);
}

+ (instancetype)lbs_bindingWithTargetClass:(Class)targetClass
    key:(NSString *)key
    function:(void *)function
    implementation:(IMP)implementation
    selector:(SEL)selector
{
	return ([[_NSSelectorSetBinding alloc] initWithTargetClass:targetClass
	    key:key function:function implementation:implementation
	    selector:selector]);
}

@end

@implementation _NSSelectorGetBinding

- (instancetype)initWithTargetClass:(Class)targetClass
    key:(NSString *)key
    function:(void *)function
    implementation:(IMP)implementation
    selector:(SEL)selector
{
	if ((self = [super initWithTargetClass:targetClass key:key]) != nil) {
		getSel = selector;
		getMethod = implementation;
		get = function;
	}
	return (self);
}

- (id)getValueFromObject:(id)object
{
	return (((NSKeyBindingGetterFunction)get)(object, getSel, getMethod));
}

@end

@implementation _NSSelectorSetBinding

- (instancetype)initWithTargetClass:(Class)targetClass
    key:(NSString *)key
    function:(void *)function
    implementation:(IMP)implementation
    selector:(SEL)selector
{
	if ((self = [super initWithTargetClass:targetClass key:key]) != nil) {
		setSel = selector;
		setMethod = implementation;
		set = function;
	}
	return (self);
}

- (BOOL)isScalarProperty
{
	return (YES);
}

- (void)setValue:(id)value inObject:(id)object
{
	((NSKeyBindingSetterFunction)set)(object, setSel, value, setMethod);
}

@end
