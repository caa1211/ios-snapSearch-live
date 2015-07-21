//
//  SettingViewController.m
//  ios-snapSearch-live
//
//  Created by Carter Chang on 7/21/15.
//  Copyright (c) 2015 Carter Chang. All rights reserved.
//

#import "SettingViewController.h"
#import "DDParentCell.h"
#import "DDChildCell.h"

@interface SettingViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *selectableSearch;
@property (strong, nonatomic) NSArray *selectableDict;
@property (strong, nonatomic) NSArray *selectableEC;
@property (strong, nonatomic) NSDictionary *searchFilter;
@property (strong, nonatomic) NSDictionary *ecFilter;
@property (strong, nonatomic) NSDictionary *dictFilter;
@end

NSMutableIndexSet *expandedSections;
enum {
    ECSection = 0,
    SearchSection,
    DictionarySection
};

@implementation SettingViewController

- (void) initVariables {
    self.selectableSearch = @[
                              @{
                                  @"title": @"Yahoo",
                                  @"value": @{
                                          @"url": @"https://search.yahoo.com/search?p="
                                          }
                                  },
                              @{
                                  @"title": @"Google",
                                  @"value": @{
                                          @"url": @"https://www.google.com.tw/search?q="
                                          }
                                  }
                           ];
    self.selectableDict = @[
                              @{
                                  @"title": @"Dictionary.com",
                                  @"value": @{
                                          @"url": @"http://dictionary.reference.com/browse/",
                                          @"params": @"?s=t"
                                          }
                                  },
                              @{
                                  @"title": @"TheFreeDictionary",
                                  @"value": @{
                                          @"url": @"http://www.thefreedictionary.com/"
                                          }
                                  }
                              ];
    self.selectableEC = @[
                              @{
                                  @"title": @"Yahoo Auction",
                                  @"value": @{
                                          @"url": @"https://tw.search.bid.yahoo.com/search/auction/product?p="
                                          }
                                  },
                              @{
                                  @"title": @"Yahoo Shopping",
                                  @"value": @{
                                          @"url": @"https://tw.search.buy.yahoo.com/search/shopping/product?p="
                                          }
                                  }
                              ,
                              @{
                                  @"title": @"Yahoo Store",
                                  @"value": @{
                                          @"url": @"https://tw.search.mall.yahoo.com/search/mall/product?p="
                                          }
                                  }
                              
                              ];

    NSDictionary * searchSettingData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"search"];
    NSDictionary * ecSettingData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ec"];
    NSDictionary * dictSettingData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"dict"];
    
    self.searchFilter = searchSettingData != nil ? searchSettingData : self.selectableSearch[0];
    self.ecFilter = ecSettingData != nil? ecSettingData : self.selectableEC[0];
    self.dictFilter = dictSettingData != nil ? dictSettingData : self.selectableDict[0];
    
  }


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(onCancel)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"OK" style:UIBarButtonItemStylePlain target:self action:@selector(onOk)];
    
    
    self.title = @"Setting";
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"DDParentCell" bundle:nil] forCellReuseIdentifier:@"DDParentCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"DDChildCell" bundle:nil] forCellReuseIdentifier:@"DDChildCell"];
    
    expandedSections = [[NSMutableIndexSet alloc] init];
    
    [self initVariables];
}

-(void) onCancel{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void) onOk{
    
    [[NSUserDefaults standardUserDefaults] setObject:self.ecFilter forKey:@"ec"];
    [[NSUserDefaults standardUserDefaults] setObject:self.searchFilter forKey:@"search"];
    [[NSUserDefaults standardUserDefaults] setObject:self.dictFilter forKey:@"dict"];
    
    [self.delegate didChangeSetting];
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger num;
    if (![expandedSections containsIndex:section]) {
        num = 1;
    }
    else{
        switch (section) {
            case ECSection:
                num = 4;
                break;
            case SearchSection:
                num = 3;
                break;
            case DictionarySection:
                num = 3;
                break;
            default:
                break;
        }
    }
    return num;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger section = indexPath.section;
    UITableViewCell *cell = nil;
    BOOL currentlyExpanded = [expandedSections containsIndex:section];
    NSArray *selectableArray;
    NSDictionary *filter;
    switch (section) {
        case ECSection:
            selectableArray = self.selectableEC;
            filter = self.ecFilter;
            break;
        case SearchSection:
            selectableArray = self.selectableSearch;
            filter = self.searchFilter;
            break;
        case DictionarySection:
            selectableArray = self.selectableDict;
            filter = self.dictFilter;
            break;
        default:
            break;
    }
    
    
    if (!currentlyExpanded) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"DDParentCell"];
        ((DDParentCell*)cell).titleLabel.text = filter[@"title"];
    } else {
        /* Child cell */
        cell = [tableView dequeueReusableCellWithIdentifier:@"DDChildCell"];
        NSString *title = selectableArray[indexPath.row-1][@"title"];
        ((DDChildCell*)cell).titleLabel.text = title;
        
        if([title isEqual:filter[@"title"]]){
            [((DDChildCell*)cell) addMark];
        }
    }

    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    NSInteger section = indexPath.section;
    BOOL currentlyExpanded = [expandedSections containsIndex:section];
    
    if(currentlyExpanded && indexPath.row == 0){
        return 0;
    }else{
        return tableView.rowHeight;
    }
}

- (void) tableViewRemoveAllMarks:(UITableView *)tableView bySection:(NSInteger)section {
    for (NSInteger i = 1; i < [tableView numberOfRowsInSection:section]; ++i){
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section]];
        [(DDChildCell *)cell removeMark];
    }
}

- (NSMutableArray *) collectSubRowsOnSection:(NSInteger)section
                               withTableView:(UITableView*)tableView
                           andExpandedStatus:(BOOL)currentlyExpanded{
    NSInteger rows;
    NSMutableArray *arrRows = [NSMutableArray array];
    
    if (currentlyExpanded) {
        /* collect child rows for this section */
        rows = [self tableView:tableView numberOfRowsInSection:section];
        [expandedSections removeIndex:section];
    } else {
        /* collect parent row for this section */
        [expandedSections addIndex:section];
        rows = [self tableView:tableView numberOfRowsInSection:section];
    }
    
    for (int i = 1; i < rows; i++) {
        NSIndexPath *tmpIndexPath = [NSIndexPath indexPathForRow:i inSection:section];
        [arrRows addObject:tmpIndexPath];
    }
    return arrRows;
}

- (void) toggleDDHeadOnTable:(UITableView*)tableView withIndexPath:(NSIndexPath *)indexPath
                 onRootTitle:(NSString *)rootTitle
{
    
    NSInteger section = indexPath.section;
    BOOL currentlyExpanded = [expandedSections containsIndex:section];
    NSMutableArray *arrRows = [self collectSubRowsOnSection:section withTableView:tableView andExpandedStatus:currentlyExpanded];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (currentlyExpanded) {
        // will get all child rows in arrRows, all of them should be deleted befor collapse dd
        [cell setHidden:NO];
        [tableView deleteRowsAtIndexPaths:arrRows withRowAnimation:UITableViewRowAnimationTop];
        ((DDParentCell *)cell).titleLabel.text = rootTitle;
        
    } else {
        // will get all child rows in arrRows, all of them should be added befor expand dd
        [cell setHidden:YES];
        [tableView insertRowsAtIndexPaths:arrRows withRowAnimation:UITableViewRowAnimationTop];
    }
}

-(NSDictionary *) clickDDOnTable:(UITableView *)tableView toggleIndex:(NSIndexPath*)indexPath withDataArray:(NSArray*)selectableAry
{
    NSDictionary *filter = nil;
    NSInteger section = indexPath.section;
    NSString *rootTitle = nil;
    
    if (indexPath.row == 0) {
        // Click Parent row
        [self toggleDDHeadOnTable:tableView withIndexPath:indexPath  onRootTitle:nil];
    }else {
        // Click Child row
        filter = selectableAry[indexPath.row-1];
        rootTitle = filter[@"title"];
        
        [self tableViewRemoveAllMarks: tableView bySection:section];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [(DDChildCell *)cell addMark];
        
        NSIndexPath *parentIndexPath = [NSIndexPath indexPathForRow:0 inSection:section];
        [self toggleDDHeadOnTable:tableView withIndexPath:parentIndexPath  onRootTitle:rootTitle];
        
        //NSLog(@"click Child %ld", indexPath.row);
    }
    return filter;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;

    //NSArray *selectableArray;
    //NSDictionary *filter;
    switch (section) {
        case ECSection:
            //selectableArray = self.selectableEC;
            self.ecFilter = [self clickDDOnTable:tableView toggleIndex:indexPath withDataArray:self.selectableEC];
            break;
        case SearchSection:
            //selectableArray = self.selectableSearch;
            //filter = self.searchFilter;
            self.searchFilter = [self clickDDOnTable:tableView toggleIndex:indexPath withDataArray:self.selectableSearch];
            break;
        case DictionarySection:
            //selectableArray = self.selectableDict;
            //filter = self.dictFilter;
            self.dictFilter = [self clickDDOnTable:tableView toggleIndex:indexPath withDataArray:self.selectableDict];
            break;
        default:
            break;
    }
    
    //filter = [self clickDDOnTable:tableView toggleIndex:indexPath withDataArray:selectableArray];
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case ECSection:
            return @"EC";
            break;
            
        case SearchSection:
            return @"Search";
            break;
            
        case DictionarySection:
            return @"Dictionary";
            break;
        default:
            return @"";
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if([self tableView:self.tableView titleForHeaderInSection:section] == nil){
        return 0;
    }
    else{
        return 30;
    }
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 42.0f)];
    
    [view setBackgroundColor:[UIColor colorWithRed:0.936 green:0.922 blue:0.939 alpha:1.000]];
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 150, 30)];
    [lbl setFont:[UIFont boldSystemFontOfSize:15]];
    [lbl setTextColor:[UIColor grayColor]];
    [view addSubview:lbl];
    
    [lbl setText:[NSString stringWithFormat:@"%@", [self tableView:self.tableView titleForHeaderInSection:section]]];
    
    return view;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
