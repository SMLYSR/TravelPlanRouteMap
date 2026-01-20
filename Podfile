platform :ios, '15.0'

target 'TravelPlanRouteMap' do
  use_frameworks!
  
  # 高德地图 SDK（NO IDFA 版本，避免 App Store 审核问题）
  pod 'AMap3DMap-NO-IDFA'      # 3D地图 SDK
  pod 'AMapSearch-NO-IDFA'     # 搜索功能（地理编码、POI搜索）
  pod 'AMapLocation-NO-IDFA'   # 定位 SDK
end

target 'TravelPlanRouteMapTests' do
  inherit! :search_paths
end

target 'TravelPlanRouteMapUITests' do
  inherit! :search_paths
end
