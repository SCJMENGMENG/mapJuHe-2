//
//  AnnotationClusterViewController.m
//  mapJuHe
//
//  Created by scj on 2018/9/11.
//  Copyright © 2018年 scj. All rights reserved.
//

#import "AnnotationClusterViewController.h"

#import "MANaviRoute.h"
#import "CommonUtility.h"

#define kCalloutViewMargin  -12
#define Button_Height       70.0

static const NSInteger RoutePlanningPaddingEdge = 20;
static const NSString *RoutePlanningViewControllerStartTitle = @"起点";
static const NSString *RoutePlanningViewControllerDestinationTitle = @"终点";

@interface AnnotationClusterViewController ()

@property (strong, nonatomic) AMapRoute *route;  //路径规划信息
@property (strong, nonatomic) MANaviRoute * naviRoute;  //用于显示当前路线方案.

@property (strong, nonatomic) MAPointAnnotation *startAnnotation;
@property (strong, nonatomic) MAPointAnnotation *destinationAnnotation;

@property (assign, nonatomic) CLLocationCoordinate2D startCoordinate; //起始点经纬度
@property (assign, nonatomic) CLLocationCoordinate2D destinationCoordinate; //终点经纬度

@property (assign, nonatomic) NSUInteger totalRouteNums;  //总共规划的线路的条数
@property (assign, nonatomic) NSUInteger currentRouteIndex; //当前显示线路的索引值，从0开始


@end

@implementation AnnotationClusterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initMapViewAndSearch];
    
    [self setUpData];
    
    [self addDefaultAnnotations];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn addTarget:self action:@selector(aaa) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:@"111" forState:UIControlStateNormal];
    btn.frame = CGRectMake(100, 100, 100, 100);
    btn.backgroundColor = [UIColor redColor];
                [self.view addSubview:btn];
}

- (void)aaa{
    [self searchRoutePlanningDrive];  //驾车路线开始规划
}

//初始化地图,和搜索API
- (void)initMapViewAndSearch {
    self.mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height - 45 - 64)];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
    
    self.search = [[AMapSearchAPI alloc] init];
    self.search.delegate = self;
}

//初始化坐标数据
- (void)setUpData {
    self.startCoordinate = CLLocationCoordinate2DMake(39.910267, 116.370888);
    self.destinationCoordinate = CLLocationCoordinate2DMake(39.989872, 116.481956);
}

//在地图上添加起始和终点的标注点
- (void)addDefaultAnnotations {
    MAPointAnnotation *startAnnotation = [[MAPointAnnotation alloc] init];
    startAnnotation.coordinate = self.startCoordinate;
    startAnnotation.title = (NSString *)RoutePlanningViewControllerStartTitle;
    startAnnotation.subtitle = [NSString stringWithFormat:@"{%f, %f}", self.startCoordinate.latitude, self.startCoordinate.longitude];
    self.startAnnotation = startAnnotation;
    
    MAPointAnnotation *destinationAnnotation = [[MAPointAnnotation alloc] init];
    destinationAnnotation.coordinate = self.destinationCoordinate;
    destinationAnnotation.title = (NSString *)RoutePlanningViewControllerDestinationTitle;
    destinationAnnotation.subtitle = [NSString stringWithFormat:@"{%f, %f}", self.destinationCoordinate.latitude, self.destinationCoordinate.longitude];
    self.destinationAnnotation = destinationAnnotation;
    
    [self.mapView addAnnotation:startAnnotation];
    [self.mapView addAnnotation:destinationAnnotation];
}

//驾车路线开始规划
- (void)searchRoutePlanningDrive {
    
    AMapDrivingRouteSearchRequest *navi = [[AMapDrivingRouteSearchRequest alloc] init];
    navi.requireExtension = YES;
    navi.strategy = 5; //驾车导航策略,5-多策略（同时使用速度优先、费用优先、距离优先三个策略）
    
    /* 出发点. */
    navi.origin = [AMapGeoPoint locationWithLatitude:self.startCoordinate.latitude
                                           longitude:self.startCoordinate.longitude];
    /* 目的地. */
    navi.destination = [AMapGeoPoint locationWithLatitude:self.destinationCoordinate.latitude
                                                longitude:self.destinationCoordinate.longitude];
    
    [self.search AMapDrivingRouteSearch:navi];
}

//路径规划搜索完成回调.
- (void)onRouteSearchDone:(AMapRouteSearchBaseRequest *)request response:(AMapRouteSearchResponse *)response {

    self.route = response.route;

    self.totalRouteNums = self.route.paths.count;
    self.currentRouteIndex = 0;

    [self presentCurrentRouteCourse];
}

//在地图上显示当前选择的路径
- (void)presentCurrentRouteCourse {

    if (self.totalRouteNums <= 0) {
        return;
    }

//    [self.naviRoute removeFromMapView];  //清空地图上已有的路线

    MANaviAnnotationType type = MANaviAnnotationTypeDrive; //驾车类型

    AMapGeoPoint *startPoint = [AMapGeoPoint locationWithLatitude:self.startAnnotation.coordinate.latitude longitude:self.startAnnotation.coordinate.longitude]; //起点

    AMapGeoPoint *endPoint = [AMapGeoPoint locationWithLatitude:self.destinationAnnotation.coordinate.latitude longitude:self.destinationAnnotation.coordinate.longitude];  //终点

    //根据已经规划的路径，起点，终点，规划类型，是否显示实时路况，生成显示方案
    self.naviRoute = [MANaviRoute naviRouteForPath:self.route.paths[self.currentRouteIndex] withNaviType:type showTraffic:YES startPoint:startPoint endPoint:endPoint];

    [self.naviRoute addToMapView:self.mapView];  //显示到地图上

    UIEdgeInsets edgePaddingRect = UIEdgeInsetsMake(RoutePlanningPaddingEdge, RoutePlanningPaddingEdge, RoutePlanningPaddingEdge, RoutePlanningPaddingEdge);

    //缩放地图使其适应polylines的展示
    [self.mapView setVisibleMapRect:[CommonUtility mapRectForOverlays:self.naviRoute.routePolylines]
                        edgePadding:edgePaddingRect
                           animated:NO];
}

#pragma mark - MAMapViewDelegate

//地图上覆盖物的渲染，可以设置路径线路的宽度，颜色等
- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay {

    //showTraffic为YES时，需要带实时路况，路径为多颜色渐变
    if ([overlay isKindOfClass:[MAMultiPolyline class]]) {
        MAMultiColoredPolylineRenderer * polylineRenderer = [[MAMultiColoredPolylineRenderer alloc] initWithMultiPolyline:overlay];

        polylineRenderer.lineWidth = 6;
        polylineRenderer.strokeColors = [self.naviRoute.multiPolylineColors copy];

        return polylineRenderer;
    }

    return nil;
}

@end
