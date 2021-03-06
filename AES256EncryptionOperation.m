//
//  AES256EncryptionOperation.m
//  AES Encryptor
//
//  Created by John Heaton on 11/30/09.
//  Copyright 2009 GJB Software. All rights reserved.
//

#import "AES256EncryptionOperation.h"
#import <openssl/aes.h>
#import <string.h>

#define kAESBlockSize 16

@implementation AES256EncryptionOperation

- (id)initWithTarget:(id)t delegate:(id<AES256EncryptionOperationDelegate>)de inputData:(NSData *)da key:(NSString *)k operationType:(int)type {
	if(self = [super init]) {
		if(!da || !k || [k length] > 32) return nil;
		
		target = t;
		delegate = de;
		inData = [da retain];
		key = [k copy];
		optype = type;
	}
	
	return self;
}

- (NSInteger)blocksForLength:(NSInteger)length blockSize:(NSInteger)blockSize {
	return (((((length - 1) / blockSize) + 1) * blockSize) / blockSize);
}

- (void)main {
	AES_KEY k;
	
	NSInteger bufSize = kAESBlockSize * [self blocksForLength:[inData length] blockSize:kAESBlockSize];
	
	unsigned char *paddedinput = calloc(1, bufSize);
	memcpy(paddedinput, [inData bytes], bufSize);
	
	unsigned char *paddedkey = calloc(1, 256);
	strncpy((char *)paddedkey, [key UTF8String], 256);
	
	unsigned char *output = calloc(1, bufSize);
	
	if(optype == kCryptoOperationTypeEncrypt) {
		AES_set_encrypt_key(paddedkey, 256, &k);
		
		for(NSInteger i=0;i<[self blocksForLength:[inData length] blockSize:kAESBlockSize] * kAESBlockSize;i+=kAESBlockSize) {
			AES_encrypt(&paddedinput[i], &output[i], &k);
		}
	}
	else if(optype == kCryptoOperationTypeDecrypt) {
		AES_set_decrypt_key(paddedkey, 256, &k);
		
		for(NSInteger i=0;i<[self blocksForLength:[inData length] blockSize:kAESBlockSize] * kAESBlockSize;i+=kAESBlockSize) {
			AES_decrypt(&paddedinput[i], &output[i], &k);
		}
	}
	
	free(paddedinput);
	free(paddedkey);
	
	NSData *newData = [[NSData alloc] initWithBytes:output length:kAESBlockSize * [self blocksForLength:[inData length] blockSize:kAESBlockSize]];
	
	free(output);
	
	if(delegate) [delegate cryptoOperation:self didFinishWithData:newData];
}

- (void)dealloc {
	[key release];
	[inData release];
	[super dealloc];
}

@end
