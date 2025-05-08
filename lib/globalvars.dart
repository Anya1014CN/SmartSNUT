import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';

class GlobalVars {
  //当前版本号
  static String versionCodeString = '1.12.32';
  static int versionCodeInt = 1012032;
  static String versionReleaseDate = '2025-05-04';

  //友盟统计相关
  static bool isPrivacyAgreed = false; // 是否同意隐私政策
  static bool isAnalyticsEnabled = false; // 是否启用统计功能
  static const String umengAndroidAppKey = "67da8acb65c707471a237c33"; // 替换为您的友盟Android AppKey
  static const String umengIOSAppKey = "67da8acb65c707471a237c33"; // 替换为您的友盟iOS AppKey
  static const String umengChannel = "official"; // 渠道

  //加载相关
  static bool operationCanceled = false;
  static String loadingHint = '';

  static int loginState = 0; //1 - 未登录；2 - 已登录

  //Dio 相关
  static Dio globalDio = Dio(
    BaseOptions(
      headers: {
        'User-Agent':
            (Platform.isWindows)? 'SmartSNUT-Windows/${GlobalVars.versionCodeString}':(Platform.isAndroid)? 'SmartSNUT-Android/${GlobalVars.versionCodeString}':'SmartSNUT/${GlobalVars.versionCodeString}',
      }
    )
  );
  static CookieJar globalCookieJar = CookieJar();

  //学期数据
  static Map semesterData = {}; //学期

  //用户数据
  static List stdAccount = [];
  static String realName = '';
  static String userName = '';
  static String passWord = '';
  static Map stdDetail = {};
  var documentsDirectory = "";
  static String enrollTime = '1900-01-01';
  static String graduationTime = '1900-01-01';

  //电表数据
  static List emUserData = [];//电费账号用户数据
  static String emAvatarPath = '';
  static String openId = '';
  static String wechatUserNickname = '';
  static String wechatUserId = '';
  static List emDetail = [];//电表详细数据
  static String electricUserUid = '';
  static int emNum = 0;//电表的总数

  //班级通讯录数据
  static List classList = [];//班级列表
  static List classMemberList = [];//班级成员列表

  //判断用户是否绑定电表账号
  static bool emBinded = false;

  //当前日期
  static var today = DateTime.now();
  static String monthString = '';
  static String dayString = '';
  static int hour = DateTime.now().hour;
  static String weekDay = '';
  //明日日期
  static String tomorrowMonthString = '';
  static String tomorrowDayString = '';
  static String tomorrowWeekDay = '';
  static int currentDOW = 0;//每周的第几天

  //用于存储不同时间段的问候语
  static String greeting = '';
  static String hint = '';

  //用户设置相关
  static List settingsTotal = [];
  static int fontsizeint = 1;//0 - 小；1 - 中；2 - 大
  static int darkModeint = 0;//0 - 跟随系统；1 - 始终开启；2 - 始终关闭
  static int themeColor = 0;//对应八种颜色
  //首页显示通知公告
  static bool showTzgg = true;
  //自动刷新课表
  static bool autoRefreshCourseTable = true;
  static int lastCourseTableRefreshTime = 0; //上次刷新时间
  //自动切换明日课表
  static bool switchTomorrowCourseAfter20 = true;
  //自动切换下周课表
  static bool switchNextWeekCourseAfter20 = true;
  //课表是否显示周六周日
  static bool showSatCourse = true;
  static bool showSunCourse = true;
  //课表的配色
  static int courseBlockColorsInt = 1;
  //上次刷新学期信息的时间
  static int lastSemeatersDataRefreshTime = 0;

  //字体大小相关
  //弹出对话框字体
  static double alertdialogTitle = 20;
  static double alertdialogContent = 14;

  //通用页面字体
  static double splashPageTitle = 30;
  static double bottonbarAppnameTitle = 20;
  static double bottonbarSelectedTitle = 18;
  static double bottonbarUnselectedTitle = 14;
  static double genericPageTitle = 40; //页面大标题
  static double genericPageTitleSmall = 20; //页面小标题
  static double genericGreetingTitle = 35; //页面的问候语
  static double genericFloationActionButtonTitle = 16; //浮动按钮标题
  static double dividerTitle= 15; //分割线的文字标题
  static double listTileTitle = 18;
  static double listTileSubtitle = 16;
  static double genericFunctionsButtonTitle = 16; //应用功能按钮字体
  static double genericSwitchContainerTitle = 20; //考试类型，学年学期切换、绩点等容器的字体大小
  static double genericSwitchMenuTitle = 20; //考试类型等弹出菜单的字体大小
  static double genericTextSmall = 14; //常规文本小字体
  static double genericTextMedium = 16; //常规文本中等字体
  static double genericTextLarge = 20; //常规文本大字体
}

//用于存储所有字体的“适中”的大小
class DefaultfontSize{
  //弹出对话框字体
  static double alertdialogTitle = 20;
  static double alertdialogContent = 14;

  //通用页面字体
  static double splashPageTitle = 30;
  static double bottonbarAppnameTitle = 20;
  static double bottonbarSelectedTitle = 18;
  static double bottonbarUnselectedTitle = 14;
  static double genericPageTitle = 40; //页面大标题
  static double genericPageTitleSmall = 20; //页面小标题
  static double genericGreetingTitle = 35; //页面的问候语
  static double genericFloationActionButtonTitle = 16; //浮动按钮标题
  static double dividerTitle= 15; //分割线的文字标题
  static double listTileTitle = 18;
  static double listTileSubtitle = 16;
  static double genericFunctionsButtonTitle = 16; //应用功能按钮字体
  static double genericSwitchContainerTitle = 20; //考试类型，学年学期切换、绩点等容器的字体大小
  static double genericSwitchMenuTitle = 20; //考试类型等弹出菜单的字体大小
  static double genericTextSmall = 14; //常规文本小字体
  static double genericTextMedium = 16; //常规文本中等字体
  static double genericTextLarge = 20; //常规文本大字体
}
