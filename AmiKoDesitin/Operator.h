//
//  Operator.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 26 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

// Landscape signature, generated with AmiKo OSX (also used in Generika)
#define DOCTOR_TN_H     45.0
#define DOCTOR_TN_W     90.0

#define KEY_AMK_DOC_TITLE       @"title"
#define KEY_AMK_DOC_NAME        @"given_name"
#define KEY_AMK_DOC_SURNAME     @"family_name"
#define KEY_AMK_DOC_ADDRESS     @"postal_address"
#define KEY_AMK_DOC_CITY        @"city"
#define KEY_AMK_DOC_ZIP         @"zip_code"
#define KEY_AMK_DOC_PHONE       @"phone_number"
#define KEY_AMK_DOC_EMAIL       @"email_address"
#define KEY_AMK_DOC_GLN         @"gln"
#define KEY_AMK_DOC_IBAN        @"iban"
#define KEY_AMK_DOC_VAT         @"vat_number"
#define KEY_AMK_DOC_ZSR_NUMBER  @"zsr_number"

#define KEY_AMK_DOC_SIGNATURE   @"signature"
#define DOC_SIGNATURE_FILENAME  @"op_signature.png"

@interface Operator : NSObject

@property (atomic, copy) NSString *title;
@property (atomic, copy) NSString *givenName;
@property (atomic, copy) NSString *familyName;
@property (atomic, copy) NSString *postalAddress;
@property (atomic, copy) NSString *city;
@property (atomic, copy) NSString *zipCode;
@property (atomic, copy) NSString *phoneNumber;
@property (atomic, copy) NSString *emailAddress;
@property (atomic, copy) NSString *gln;
@property (atomic, copy) NSString *IBAN;
@property (atomic, copy) NSString *vatNumber;
@property (atomic, copy) NSString *zsrNumber;

@property (nonatomic, strong, readwrite) NSString *signature;

- (void)importFromDict:(NSDictionary *)dict;
- (void)importSignatureFromDict:(NSDictionary *)dict;
- (BOOL)importSignatureFromFile;
- (NSDictionary *)toDictionary;

- (UIImage *)thumbnailFromSignature:(CGSize) size;
- (NSInteger)entriesCount;
- (NSString *)getStringForPrescriptionPrinting;
- (NSString *)getStringForLabelPrinting;

@end
