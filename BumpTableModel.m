//
//  BumpTableModel.m
//  Flock
//
//  Created by Sahil Desai on 12/11/12.
//  Copyright (c) 2012 Bump Technologies Inc. All rights reserved.
//

#import "BumpTableModel.h"

@interface BumpTableModel ()
@property (nonatomic) NSMutableDictionary *sectionNumberForRow;
@property (nonatomic) NSMutableDictionary *rowNumberForRow;
@end

@implementation BumpTableModel : NSObject
@dynamic selectedRows;

+ (id)modelWithSections:(NSArray*)sections {
    BumpTableModel *model = [self new];
    model.sections = sections;
    return model;
}

+ (id)modelWithRows:(NSArray*)rows {
    BumpTableSection *section = [BumpTableSection sectionWithKey:@"all" rows:rows];
    NSArray *sections = [NSArray arrayWithObject:section];
    return [BumpTableModel modelWithSections:sections];
}

- (void) generateIndexPathIndex {
    self.sectionNumberForRow = [NSMutableDictionary dictionary];
    self.rowNumberForRow = [NSMutableDictionary dictionary];

    for (int sectionNumber = 0; sectionNumber < [self.sections count]; sectionNumber++) {
        BumpTableSection *section = [self.sections objectAtIndex:sectionNumber];

        for (int rowNumber = 0; rowNumber < [[section rows] count]; rowNumber++) {
            BumpTableRow *row = [[section rows] objectAtIndex:rowNumber];
            [self.sectionNumberForRow setObject:@(sectionNumber) forKey:row.key];
            [self.rowNumberForRow setObject:@(rowNumber) forKey:row.key];
        }
    }
}

- (NSIndexPath *)indexPathForRow:(BumpTableRow *)row {
    assert(self.rowNumberForRow);
    return [NSIndexPath indexPathForRow:[self.rowNumberForRow[row.key] intValue]
                              inSection:[self.sectionNumberForRow[row.key] intValue]];
}

- (NSDictionary *)sectionIndexes {
    NSMutableDictionary *indexes = [NSMutableDictionary dictionaryWithCapacity:[_sections count]];
    [_sections enumerateObjectsUsingBlock:^(BumpTableSection *s, NSUInteger idx, BOOL *stop) {
        [indexes setObject:[NSIndexSet indexSetWithIndex:idx] forKey:s.key];
    }];
    return indexes;
}

- (NSDictionary *)rowIndexPaths {
    NSMutableDictionary *indexPaths = [NSMutableDictionary dictionaryWithCapacity:
                                       [_sections sumWithBlock:
                                        ^int(BumpTableSection *s) {
                                            return s.rows.count + 1;
                                        }]];
    [_sections enumerateObjectsUsingBlock:^(BumpTableSection *s, NSUInteger sidx, BOOL *stop) {
        NSMutableDictionary *sectionIndexPaths = [NSMutableDictionary dictionaryWithCapacity:s.rows.count];
        [s.rows enumerateObjectsUsingBlock:^(BumpTableRow *r, NSUInteger ridx, BOOL *stop) {
            [sectionIndexPaths setObject:[NSIndexPath indexPathForRow:ridx inSection:sidx]
                                  forKey:r.key];
        }];
        [indexPaths setObject:sectionIndexPaths forKey:s.key];
        [indexPaths addEntriesFromDictionary:sectionIndexPaths];
    }];
    return indexPaths;
}

- (BumpTableModel *)modelForSearchString:(NSString *)searchString {
    return [BumpTableModel modelWithRows:[self rowsForSearchString:searchString]];
}

- (NSMutableArray *)rowsForSearchString:(NSString *)searchString {
    searchString = [searchString lowercaseString];
    NSMutableArray *results = [NSMutableArray array];
    [_sections enumerateObjectsUsingBlock:^(BumpTableSection *s, NSUInteger sidx, BOOL *stop) {
        [s.rows enumerateObjectsUsingBlock:^(BumpTableRow *r, NSUInteger ridx, BOOL *stop) {
            if ([r.searchString rangeOfString:searchString].location != NSNotFound) {
                [results addObject:r];
            }
        }];
    }];

    return results;
}

- (NSArray *)selectedRows {
    NSMutableArray *rows = [NSMutableArray array];
    [_sections enumerateObjectsUsingBlock:^(BumpTableSection *s, NSUInteger idx, BOOL *stop) {
        [s.rows enumerateObjectsUsingBlock:^(BumpTableRow *r, NSUInteger idx, BOOL *stop) {
            if (r.selected) [rows addObject:r];
        }];
    }];

    return rows;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<Model sections:%@\n>", [_sections indentedDescription]];
}

@end

@implementation BumpTableHeaderFooter
@synthesize height, generator;

+ (id)headerFooterForHeight:(CGFloat)height generator:(BumpTableHeaderFooterGenerator)generator {
    BumpTableHeaderFooter *hf = [BumpTableHeaderFooter new];
    hf.height = height;
    hf.generator = generator;
    return hf;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<Header/Footer height: %f generator:%d\n>", height, !!generator];
}

@end

@implementation BumpTableSection
@synthesize key, rows, indexTitle, header, footer;

+ (id)sectionWithKey:(NSObject <NSCopying>*)key rows:(NSArray*)rows {
    BumpTableSection *section = [self new];
    section.key = key;
    section.rows = rows;
    return section;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<Section key:%@\nheader:%@\nfooter:%@\nrows:%@\n>", key, header, footer, [rows indentedDescription]];
}

@end

@implementation BumpTableRow {
    BOOL _selected;
    NSString *_searchString;
}

@synthesize key, height, reuseIdentifier, generator, customizer, onSelection, onDeselection, onTap;
@dynamic searchString, selected;


+ (id)rowWithKey:(NSObject <NSCopying>*)key
          height:(CGFloat)height
 reuseIdentifier:(NSString *)reuseIdentifier
       generator:(BumpTableCellGenerator)generator {
    BumpTableRow *row = [self new];
    row.key = key;
    row.height = height;
    row.reuseIdentifier = reuseIdentifier;
    row.generator = generator;
    row.selectable = YES;
    return row;
}

- (void)setSelected:(BOOL)selected {
    assert(self.selectable);
    _selected = selected;
}
- (BOOL)selected {
    return _selected;
}

- (void)setSearchString:(NSString *)searchString {
    _searchString = [searchString lowercaseString];
}

- (NSString *)searchString {
    return _searchString;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<Row key:%@\nheight:%f\nreuse:%@\ngenerator:%d\ncustomizer:%d\nonSelection:%d\nonDeselection:%d\n>",
            key, height, reuseIdentifier, !!generator, !!customizer, !!onSelection, !!onDeselection];
}

@end

@implementation BumpTableRow (Tagging)

- (BOOL)isFlockFriendRow {
    NSDictionary *keyDict = (NSDictionary *)self.key;
    return [[keyDict objectForKey:@"flockFriend"] boolValue];
}

- (BOOL)isNonFlockFriendRow {
    NSDictionary *keyDict = (NSDictionary *)self.key;
    return (![self isFlockFriendRow] &&
            [keyDict objectForKey:@"phoneNumber"] == [NSNull null]);
}

- (BOOL)isPhoneNumberFriendRow {
    NSDictionary *keyDict = (NSDictionary *)self.key;
    return (![self isFlockFriendRow] &&
            [keyDict objectForKey:@"phoneNumber"] != [NSNull null]);
}

@end