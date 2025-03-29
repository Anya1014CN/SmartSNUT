class GlobalVars {
  //当前版本号
  static String versionCodeString = '1.3.10';
  static int versionCodeInt = 1003010;
  static String versionReleaseDate = '2025-03-23';

  //用户数据
  static List stdAccount = [];
  static String realName = '';
  static String userName = '';
  static String passWord = '';
  static Map<String, String> stdDetail = {};
  var documentsDirectory = "";
  static String enrollTime = '1900-01-01';
  static String graduationTime = '1900-01-01';

  //判断用户是否绑定电表账号
  static bool emBinded = false;

  //当前日期
  static var today = DateTime.now();
  static int month = DateTime.now().month;
  static int day = DateTime.now().day;
  static int hour = DateTime.now().hour;
  static String weekDay = '';

  //用于存储不同时间段的问候语
  static String greeting = '';
  static String hint = '';

  //用户设置相关
  static List settingsTotal = [];
  static int fontsizeint = 1;//0 - 小；1 - 中；2 - 大
  static int darkModeint = 0;//0 - 跟随系统；1 - 始终开启；2 - 始终关闭
  static int themeColor = 0;//对应八种颜色
  //课表是否显示周六周日
  static bool showSatCourse = true;
  static bool showSunCourse = true;
  //课表的配色
  static int courseBlockColorsInt = 1;

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