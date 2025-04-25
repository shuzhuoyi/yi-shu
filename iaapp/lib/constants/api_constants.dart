class ApiConstants {
  // 苹果CMS的API基础URL
  static const String baseUrl = 'https://zhouxue.asia';

  // 影片列表接口
  static const String movieList = '/api.php/provide/vod/?ac=list';

  // 影片详情接口 (完整路径，可以直接使用)
  static const String movieDetail = '/api.php/provide/vod/';

  // 影片搜索接口
  static const String movieSearch = '/api.php/provide/vod/?ac=search';
  
  // 分类接口
  static const String categoryList = '/api.php/type/get_list/';
  
  // 视频解析接口
  static const String videoParsingConfig = '/addons/appto/admin.php/a_t_home/getParsingConfig';

  // 用户相关接口
  static const String userLogin = '/index.php/user/login';
  static const String userRegister = '/index.php/user/reg';
  static const String userGetList = '/api.php/user/get_list/';
  static const String userGetInfo = '/index.php/user/ajax_info';
} 