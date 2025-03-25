import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartsnut/AppPage/app_page.dart';
import 'package:smartsnut/Home/home.dart';
import 'package:smartsnut/splash.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:smartsnut/mePage/me_page.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:intl/date_symbol_data_local.dart';

bool loaded = false;//防止重复加载页面
var deviceType;//定义屏幕类型（桌面，平板，手表等）
bool settingsLoaded = false;

//页面选择状态
int railselectedIndex = 0;

void main() {
  //runApp(const SmartSNUT());
  runApp(SmartSNUT(),);
}

class SmartSNUT extends StatefulWidget{
  const SmartSNUT ({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SmartSNUT();
  }
}
 
class _SmartSNUT extends State<SmartSNUT> {

  //读取设置并保存在变量中
  readSettings() async {
    String settingstpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/settings.json';
    File settingstfile = File(settingstpath);
    if(await settingstfile.exists()){
      GlobalVars.settingsTotal = jsonDecode(await settingstfile.readAsString());
      setState(() {
        GlobalVars.fontsizeint = GlobalVars.settingsTotal[0]['fontSize']?? 3;
        GlobalVars.darkModeint = GlobalVars.settingsTotal[0]['DarkMode']?? 0;
        GlobalVars.themeColor = GlobalVars.settingsTotal[0]['ThemeColor']?? 1;
        GlobalVars.showSatCourse = GlobalVars.settingsTotal[0]['showSatCourse']?? true;
        GlobalVars.showSunCourse = GlobalVars.settingsTotal[0]['showSunCourse']?? true;
        GlobalVars.courseBlockColorsInt = GlobalVars.settingsTotal[0]['courseBlockColorsint']?? 0;
      });
    }else{
      setState(() {
        GlobalVars.fontsizeint = 3;
        GlobalVars.darkModeint = 0;
        GlobalVars.themeColor = 1;
        GlobalVars.showSatCourse = true;
        GlobalVars.showSunCourse = true;
        GlobalVars.courseBlockColorsInt = 0;
      });
    }
    setfontsize();
  }

  //设置字体大小
  setfontsize() {
    double changevalue = 0;
    if(GlobalVars.fontsizeint == 0){
      changevalue = -6;
      GlobalVars.fontSize_name = '极小';
    }
    if(GlobalVars.fontsizeint == 1){
      changevalue = -4;
      GlobalVars.fontSize_name = '超小';
    }
    if(GlobalVars.fontsizeint == 2){
      changevalue = -2;
      GlobalVars.fontSize_name = '较小';
    }
    if(GlobalVars.fontsizeint == 3){
      changevalue = 0;
      GlobalVars.fontSize_name = '适中';
    }
    if(GlobalVars.fontsizeint == 4){
      changevalue = 2;
      GlobalVars.fontSize_name = '较大';
    }
    if(GlobalVars.fontsizeint == 5){
      changevalue = 4;
      GlobalVars.fontSize_name = '超大';
    }
    if(GlobalVars.fontsizeint == 6){
      changevalue = 6;
      GlobalVars.fontSize_name = '极大';
    }

      //弹出对话框字体
      GlobalVars.alertdialog_title_title = DefaultfontSize.alertdialog_title_title_default + changevalue;
      GlobalVars.alertdialog_content_title = DefaultfontSize.alertdialog_content_title_default + changevalue;
      
      //主页底栏/侧栏字体
      GlobalVars.bottonbar_appname_title = DefaultfontSize.bottonbar_appname_title_default + changevalue;
      GlobalVars.bottonbar_selected_title = DefaultfontSize.bottonbar_selected_title_default + changevalue;
      GlobalVars.bottonbar_unselected_title = DefaultfontSize.bottonbar_unselected_title_default + changevalue;

      //闪屏页字体
      GlobalVars.smartsnut_text_title = DefaultfontSize.smartsnut_text_title_default + changevalue;

      //登录页字体
      GlobalVars.welcome_page_title = DefaultfontSize.welcome_page_title_default + changevalue;
      GlobalVars.login_hint_title = DefaultfontSize.login_hint_title_default + changevalue;
      GlobalVars.login_button_title = DefaultfontSize.login_button_title_default + changevalue;

      //首页字体
      GlobalVars.homegreeting_text_title = DefaultfontSize.homegreeting_text_title_default + changevalue;

      GlobalVars.homecoursetable_divider_title = DefaultfontSize.homecoursetable_divider_title_default + changevalue;
      GlobalVars.homecoursetable_datetime_title = DefaultfontSize.homecoursetable_datetime_title_default + changevalue;
      GlobalVars.homecoursetable_nocourse_title = DefaultfontSize.homecoursetable_nocourse_title_default + changevalue;
      GlobalVars.homecoursetable_coursename_title = DefaultfontSize.homecoursetable_coursename_title_default + changevalue;
      GlobalVars.homecoursetable_coursedetail_title = DefaultfontSize.homecoursetable_coursedetail_title_default + changevalue;
      GlobalVars.homecoursetable_morehint_title = DefaultfontSize.homecoursetable_morehint_title_default + changevalue;

      GlobalVars.frefunc_divider_title = DefaultfontSize.frefunc_divider_title_default + changevalue;
      //按钮字体在 应用页字体中//

      GlobalVars.tzgg_divider_title = DefaultfontSize.tzgg_divider_title_default + changevalue;
      GlobalVars.tzgg_newstitle_title = DefaultfontSize.tzgg_newstitle_title_default + changevalue;
      GlobalVars.tzgg_newsdate_title = DefaultfontSize.tzgg_newsdate_title_default + changevalue;

      //应用页字体
      GlobalVars.apppagegreeting_text_title = DefaultfontSize.apppagegreeting_text_title_default + changevalue;
      GlobalVars.jwgl_divider_title = DefaultfontSize.jwgl_divider_title_default + changevalue;
      GlobalVars.coursetable_button_title = DefaultfontSize.coursetable_button_title_default + changevalue;
      GlobalVars.stddetail_button_title = DefaultfontSize.stddetail_button_title_default + changevalue;
      GlobalVars.stdexam_button_title = DefaultfontSize.stdexam_button_title_default + changevalue;
      GlobalVars.stdgrade_button_title = DefaultfontSize.stdgrade_button_title_default + changevalue;

      GlobalVars.hqb_divider_title = DefaultfontSize.hqb_divider_title_default + changevalue;
      GlobalVars.networkque_button_title = DefaultfontSize.networkque_button_title_default + changevalue;
      GlobalVars.emque_button_title = DefaultfontSize.emque_button_title_default + changevalue;


      GlobalVars.external_divider_title = DefaultfontSize.external_divider_title_default + changevalue;
      GlobalVars.library_button_title = DefaultfontSize.library_button_title_default + changevalue;
      GlobalVars.face_button_title = DefaultfontSize.face_button_title_default + changevalue;
      GlobalVars.webvpn_button_title = DefaultfontSize.webvpn_button_title_default + changevalue;
      GlobalVars.newhall_button_title = DefaultfontSize.newhall_button_title_default + changevalue;

      //我的页字体
      GlobalVars.person_text_title = DefaultfontSize.person_text_title_default + changevalue;
      GlobalVars.personday_text_title = DefaultfontSize.personday_text_title_default + changevalue;

      GlobalVars.hint_text_title = DefaultfontSize.hint_text_title_default + changevalue;
      
      GlobalVars.embind_button_title = DefaultfontSize.embind_button_title_default + changevalue;
      GlobalVars.settings_button_title = DefaultfontSize.settings_button_title_default + changevalue;
      GlobalVars.guide_button_title = DefaultfontSize.guide_button_title_default + changevalue;
      GlobalVars.logout_button_title = DefaultfontSize.logout_button_title_default + changevalue;

      //课表页字体
      GlobalVars.coursetable_page_title = DefaultfontSize.coursetable_page_title_default + changevalue;
      GlobalVars.refreshcoursetable_button_title = DefaultfontSize.refreshcoursetable_button_title_default + changevalue;
      GlobalVars.coursetableswitchterm_title_title = DefaultfontSize.coursetableswitchterm_title_title_default + changevalue;
      GlobalVars.coursetableswitchterm_year_title = DefaultfontSize.coursetableswitchterm_year_title_default + changevalue;
      GlobalVars.coursetableswitchterm_term_title = DefaultfontSize.coursetableswitchterm_term_title_default + changevalue;
      GlobalVars.coursetableweek_text_title = DefaultfontSize.coursetableweek_text_title_default + changevalue;
      GlobalVars.nocoursetable_hint_title = DefaultfontSize.nocoursetable_hint_title_default + changevalue;
      GlobalVars.nocoursetable_hint_subtitle = DefaultfontSize.nocoursetable_hint_subtitle_default + changevalue;
      GlobalVars.coursetable_tablehead_title = DefaultfontSize.coursetable_tablehead_title_default + changevalue;
      GlobalVars.coursetable_coursename_title = DefaultfontSize.coursetable_coursename_title_default + changevalue;
      GlobalVars.coursetable_courselocation_title = DefaultfontSize.coursetable_courselocation_title_default + changevalue;
      GlobalVars.coursetable_coursedetailsheet_title = DefaultfontSize.coursetable_coursedetailsheet_title_default + changevalue;
      GlobalVars.coursetable_coursedetailsheet_coursecontent  = DefaultfontSize.coursetable_coursedetailsheet_coursecontent_default  + changevalue;
      GlobalVars.coursetable_coursedetailsheet_coursetitle  = DefaultfontSize.coursetable_coursedetailsheet_coursetitle_default  + changevalue;

      //学籍信息页字体
      GlobalVars.stddetail_page_title = DefaultfontSize.stddetail_page_title_default + changevalue;
      GlobalVars.stddetail_title_title = DefaultfontSize.stddetail_title_title_default + changevalue;
      GlobalVars.stddetail_content_title = DefaultfontSize.stddetail_content_title_default + changevalue;

      //考试页字体
      GlobalVars.stdexam_page_title = DefaultfontSize.stdexam_page_title_default + changevalue;
      GlobalVars.refreshstdexam_button_title = DefaultfontSize.refreshstdexam_button_title_default + changevalue;
      GlobalVars.stdexamswitchterm_title_title = DefaultfontSize.stdexamswitchterm_title_title_default + changevalue;
      GlobalVars.stdexamswitchterm_year_title = DefaultfontSize.stdexamswitchterm_year_title_default + changevalue;
      GlobalVars.stdexamswitchterm_term_title = DefaultfontSize.stdexamswitchterm_term_title_default + changevalue;
      GlobalVars.stdexam_type_title = DefaultfontSize.stdexam_type_title_default + changevalue;
      GlobalVars.nostdexam_hint_title = DefaultfontSize.nostdexam_hint_title_default + changevalue;
      GlobalVars.nostdexam_hint_subtitle = DefaultfontSize.nostdexam_hint_subtitle_default + changevalue;
      GlobalVars.stdexam_courseexamname_title = DefaultfontSize.stdexam_courseexamname_title_default + changevalue;
      GlobalVars.stdexam_courseexamdate_title = DefaultfontSize.stdexam_courseexamdate_title_default + changevalue;
      GlobalVars.stdexam_courseexamtime_title = DefaultfontSize.stdexam_courseexamtime_title_default + changevalue;
      GlobalVars.stdexam_courseexamseatno_title = DefaultfontSize.stdexam_courseexamseatno_title_default + changevalue;
      GlobalVars.stdexam_courseexamtype_title = DefaultfontSize.stdexam_courseexamtype_title_default + changevalue;

      //成绩页字体
      GlobalVars.stdgrade_page_title = DefaultfontSize.stdgrade_page_title_default + changevalue;
      GlobalVars.refreshstdgrade_button_title = DefaultfontSize.refreshstdgrade_button_title_default + changevalue;
      GlobalVars.stdgradeswitchterm_title_title = DefaultfontSize.stdgradeswitchterm_title_title_default + changevalue;
      GlobalVars.stdgradeswitchterm_year_title = DefaultfontSize.stdgradeswitchterm_year_title_default + changevalue;
      GlobalVars.stdgradeswitchterm_term_title = DefaultfontSize.stdgradeswitchterm_term_title_default + changevalue;
      GlobalVars.nostdgrade_hint_title = DefaultfontSize.nostdgrade_hint_title_default + changevalue;
      GlobalVars.nostdgrade_hint_subtitle = DefaultfontSize.nostdgrade_hint_subtitle_default + changevalue;
      GlobalVars.stdgrade_coursename_title = DefaultfontSize.stdgrade_coursename_title_default + changevalue;
      GlobalVars.stdgrade_coursecredit_title = DefaultfontSize.stdgrade_coursecredit_title_default + changevalue;
      GlobalVars.stdgrade_coursegradetotal_title = DefaultfontSize.stdgrade_coursegradetotal_title_default + changevalue;
      GlobalVars.stdgrade_coursegradefinal_title = DefaultfontSize.stdgrade_coursegradefinal_title_default + changevalue;
      GlobalVars.stdgrade_coursegradegpa_title = DefaultfontSize.stdgrade_coursegradegpa_title_default + changevalue;
      GlobalVars.stdgrade_coursetype_title = DefaultfontSize.stdgrade_coursetype_title_default + changevalue;

      //绩点计算器页字体
      GlobalVars.gpacalculator_page_title = DefaultfontSize.gpacalculator_page_title_default + changevalue;
      GlobalVars.gpacalculator_GPAtitle_title = DefaultfontSize.gpacalculator_GPAtitle_title_default + changevalue;
      GlobalVars.gpacalculator_GPAcontent_title = DefaultfontSize.gpacalculator_GPAcontent_title_default + changevalue;
      GlobalVars.gpacalculator_coursename_title = DefaultfontSize.gpacalculator_coursename_title_default + changevalue;
      GlobalVars.gpacalculator_coursename_content = DefaultfontSize.gpacalculator_coursename_content_default + changevalue;

      //网费查询页字体
      GlobalVars.networkquery_page_title = DefaultfontSize.networkquery_page_title_default + changevalue;
      GlobalVars.networkquery_button_title = DefaultfontSize.networkquery_button_title_default + changevalue;
      GlobalVars.networktopup_button_title = DefaultfontSize.networktopup_button_title_default + changevalue;
      GlobalVars.networkdetail_account_title = DefaultfontSize.networkdetail_account_title_default + changevalue;
      GlobalVars.networkdetail_realname_title = DefaultfontSize.networkdetail_realname_title_default + changevalue;
      GlobalVars.networkdetail_balance_title = DefaultfontSize.networkdetail_balance_title_default + changevalue;
      GlobalVars.networkdetail_state_title = DefaultfontSize.networkdetail_state_title_default + changevalue;
      GlobalVars.networkdetail_expire_title = DefaultfontSize.networkdetail_expire_title_default + changevalue;
      GlobalVars.networkquery_hint_title = DefaultfontSize.networkquery_hint_title_default + changevalue;
      GlobalVars.networkquery_hint_subtitle = DefaultfontSize.networkquery_hint_subtitle_default + changevalue;

      //电费查询页字体
      GlobalVars.emquery_page_title = DefaultfontSize.emquery_page_title_default + changevalue;
      GlobalVars.emdetail_emid_title = DefaultfontSize.emdetail_emid_title_default + changevalue;
      GlobalVars.emdetail_emleft_title = DefaultfontSize.emdetail_emleft_title_default + changevalue;
      GlobalVars.emdetail_emtotal_title = DefaultfontSize.emdetail_emtotal_title_default + changevalue;
      GlobalVars.emdetail_emstate_title = DefaultfontSize.emdetail_emstate_title_default + changevalue;
      GlobalVars.emdetail_emaddress_title = DefaultfontSize.emdetail_emaddress_title_default + changevalue;
      GlobalVars.emquery_nonetwork_title = DefaultfontSize.emquery_nonetwork_title_default + changevalue;
      GlobalVars.emquery_querying_title = DefaultfontSize.emquery_querying_title_default + changevalue;

      //电费账号绑定页字体
      GlobalVars.embind_page_title = DefaultfontSize.embind_page_title_default + changevalue;
      GlobalVars.embind_wechatname_title = DefaultfontSize.embind_wechatname_title_default + changevalue;
      GlobalVars.embind_emnum_title = DefaultfontSize.embind_emnum_title_default + changevalue;
      GlobalVars.embindrefresh_button_title = DefaultfontSize.embindrefresh_button_title_default + changevalue;
      GlobalVars.embindunbind_button_title = DefaultfontSize.embindunbind_button_title_default + changevalue;
      GlobalVars.embind_binding_title = DefaultfontSize.embind_binding_title_default + changevalue;
      GlobalVars.embind_hint_title = DefaultfontSize.embind_hint_title_default + changevalue;
      GlobalVars.embind_hint_subtitle = DefaultfontSize.embind_hint_subtitle_default + changevalue;

      //应用设置页字体
      GlobalVars.settings_page_title = DefaultfontSize.settings_page_title_default + changevalue;
      
      GlobalVars.generalsettings_divider_title = DefaultfontSize.generalsettings_divider_title_default + changevalue;
      GlobalVars.generalsettings_fontsize_title = DefaultfontSize.generalsettings_fontsize_title_default + changevalue;
      GlobalVars.generalsettings_fontsize_subtitle = DefaultfontSize.generalsettings_fontsize_subtitle_default + changevalue;
      GlobalVars.generalsettings_themecolor_title = DefaultfontSize.generalsettings_themecolor_title_default + changevalue;
      GlobalVars.generalsettings_themecolor_subtitle = DefaultfontSize.generalsettings_themecolor_subtitle_default + changevalue;
      GlobalVars.generalsettings_darkmode_title = DefaultfontSize.generalsettings_darkmode_title_default + changevalue;
      GlobalVars.generalsettings_darkmode_subtitle = DefaultfontSize.generalsettings_darkmode_subtitle_default + changevalue;
      
      GlobalVars.accountsettings_divider_title = DefaultfontSize.accountsettings_divider_title_default + changevalue;
      GlobalVars.accountsettings_emaccount_title = DefaultfontSize.accountsettings_emaccount_title_default + changevalue;
      GlobalVars.accountsettings_emaccount_subtitle = DefaultfontSize.accountsettings_emaccount_subtitle_default + changevalue;
      GlobalVars.accountsettings_authserveraccount_title = DefaultfontSize.accountsettings_authserveraccount_title_default + changevalue;
      GlobalVars.accountsettings_authserveraccount_subtitle = DefaultfontSize.accountsettings_authserveraccount_subtitle_default + changevalue;

      GlobalVars.aboutsnutsettings_divider_title = DefaultfontSize.aboutsnutsettings_divider_title_default + changevalue;
      GlobalVars.aboutsnutsettings_currentversion_title = DefaultfontSize.aboutsnutsettings_divider_title_default + changevalue;
      GlobalVars.aboutsnutsettings_changelog_title = DefaultfontSize.aboutsnutsettings_changelog_title_defalut + changevalue;
      GlobalVars.aboutsnutsettings_changelog_subtitle = DefaultfontSize.aboutsnutsettings_changelog_title_defalut + changevalue;
      GlobalVars.aboutsnutsettings_officialsite_title = DefaultfontSize.aboutsnutsettings_officialsite_title_defalut + changevalue;
      GlobalVars.aboutsnutsettings_officialsite_subtitle = DefaultfontSize.aboutsnutsettings_officialsite_subtitle_defalut + changevalue;
      GlobalVars.aboutsnutsettings_githublink_title = DefaultfontSize.aboutsnutsettings_githublink_title_defalut + changevalue;
      GlobalVars.aboutsnutsettings_githublink_subtitle = DefaultfontSize.aboutsnutsettings_githublink_subtitle_defalut + changevalue;
      
      GlobalVars.disclamier_divider_title = DefaultfontSize.disclamier_divider_title_default + changevalue;
      GlobalVars.disclamier_title_title = DefaultfontSize.disclamier_title_title_default + changevalue;
      
      GlobalVars.lincense_divider_title = DefaultfontSize.lincense_divider_title_default + changevalue;
      GlobalVars.lincense_name_title = DefaultfontSize.lincense_name_title_default + changevalue;
      GlobalVars.lincense_describ_title = DefaultfontSize.lincense_describ_title_default + changevalue;
  }

  //每秒刷新一次数据及页面
  refreshState() async {
    Future.delayed(Duration(seconds: 2),(){
      if(mounted){
        setState(() {
          GlobalVars.today = DateTime.now();
          GlobalVars.month = DateTime.now().month;
          GlobalVars.day = DateTime.now().day;
          GlobalVars.hour = DateTime.now().hour;
          initializeDateFormatting("zh_CN");
          GlobalVars.weekDay = DateFormat('EEEE',"zh_CN").format(DateTime.now());
        });
      }
    });
  }

  @override
  void initState() {
    readSettings();
    super.initState();
    readSettings();
  }
  @override
  Widget build(BuildContext context) {
    refreshState();
    //处理首页和应用页的问候语
    if(GlobalVars.hour >= 0 && GlobalVars.hour <= 5){
      GlobalVars.greeting = '晚上好';
    }if(GlobalVars.hour >= 6 && GlobalVars.hour <= 11){
      GlobalVars.greeting = '早上好';
    }if(GlobalVars.hour >= 12 && GlobalVars.hour <= 13){
      GlobalVars.greeting = '中午好';
    }if(GlobalVars.hour >= 14 && GlobalVars.hour <= 18){
      GlobalVars.greeting = '下午好';
    }if(GlobalVars.hour >= 19 && GlobalVars.hour <= 23){
      GlobalVars.greeting = '晚上好';
    }
    //处理我的页的问候语
    if(GlobalVars.hour >= 0 && GlobalVars.hour <= 5){
      GlobalVars.hint = '劳逸结合，注意休息';
    }if(GlobalVars.hour >= 6 && GlobalVars.hour <= 8){
      GlobalVars.hint = '新的一天，元气满满';
    }if(GlobalVars.hour >= 9 && GlobalVars.hour <= 11){
      GlobalVars.hint = '专心学习，高效进步';
    }if(GlobalVars.hour >= 12 && GlobalVars.hour <= 13){
      GlobalVars.hint = '适量休息，补充能量';
    }if(GlobalVars.hour >= 14 && GlobalVars.hour <= 17){
      GlobalVars.hint = '专注实践，提升自我';
    }if(GlobalVars.hour >= 18 && GlobalVars.hour <= 19){
      GlobalVars.hint = '总结反思，调整步伐';
    }if(GlobalVars.hour >= 20 && GlobalVars.hour < 24){
      GlobalVars.hint = '适时放松，迎接明天';
    }
    return MaterialApp(
      title: '智慧陕理',
      theme: FlexThemeData.light(
        fontFamily: 'MiSans',
        scheme: (GlobalVars.themeColor == 0)? FlexScheme.amber:(GlobalVars.themeColor == 1)? FlexScheme.deepOrangeM3:(GlobalVars.themeColor == 2)? FlexScheme.mandyRed:(GlobalVars.themeColor == 3)? FlexScheme.deepBlue:(GlobalVars.themeColor == 4)? FlexScheme.mallardGreen:(GlobalVars.themeColor == 5)? FlexScheme.pinkM3:(GlobalVars.themeColor == 6)? FlexScheme.espresso:FlexScheme.shark,
        subThemesData: const FlexSubThemesData(
          interactionEffects: true,
          tintedDisabledControls: true,
          useM2StyleDividerInM3: true,
          inputDecoratorIsFilled: true,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          alignedDropdown: true,
          navigationRailUseIndicator: true,
          navigationRailLabelType: NavigationRailLabelType.all,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        ),
      darkTheme: FlexThemeData.dark(
        fontFamily: 'MiSans',
        scheme: (GlobalVars.themeColor == 0)? FlexScheme.amber:(GlobalVars.themeColor == 1)? FlexScheme.deepOrangeM3:(GlobalVars.themeColor == 2)? FlexScheme.mandyRed:(GlobalVars.themeColor == 3)? FlexScheme.deepBlue:(GlobalVars.themeColor == 4)? FlexScheme.mallardGreen:(GlobalVars.themeColor == 5)? FlexScheme.pinkM3:(GlobalVars.themeColor == 6)? FlexScheme.espresso:FlexScheme.shark,
        subThemesData: const FlexSubThemesData(
          interactionEffects: true,
          tintedDisabledControls: true,
          blendOnColors: true,
          useM2StyleDividerInM3: true,
          inputDecoratorIsFilled: true,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          alignedDropdown: true,
          navigationRailUseIndicator: true,
          navigationRailLabelType: NavigationRailLabelType.all,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        ),
      themeMode: (GlobalVars.darkModeint == 0)? ThemeMode.system:(GlobalVars.darkModeint == 1)? ThemeMode.dark:ThemeMode.light,
      home: SplashPage(),
    );
  }
}

class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage>{
  int selectedHomeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      //底部 Tab
      bottomNavigationBar: ResponsiveBuilder(
          builder: (context, sizingInformation) {
            if (sizingInformation.deviceScreenType == DeviceScreenType.desktop || sizingInformation.deviceScreenType == DeviceScreenType.tablet) {
              return SizedBox(width: 0,height: 0,);
            }
            else{
              return NavigationBar(
                onDestinationSelected: (int index) {
                  if(mounted){
                    setState(() {
                      selectedHomeIndex = index;
                    });
                  }
                },
                indicatorColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                selectedIndex: selectedHomeIndex,
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.home),
                    selectedIcon: Icon(Icons.home),
                    label: '首页',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.touch_app),
                    selectedIcon: Icon(Icons.touch_app),
                    label: '校内应用',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person),
                    selectedIcon: Icon(Icons.person),
                    label: '我的',
                  ),
                ],
              );
            }
          },
        ),
      body: ResponsiveBuilder(
          builder: (context, sizingInformation) {
            if (sizingInformation.deviceScreenType == DeviceScreenType.desktop || sizingInformation.deviceScreenType == DeviceScreenType.tablet) {
              return Row(
                children: [
                  NavigationRail(
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                    selectedIndex: railselectedIndex,
                    onDestinationSelected: (int index) {
                      if(mounted){
                        setState(() {
                          railselectedIndex = index;
                        });
                      }
                    },
                    labelType: NavigationRailLabelType.selected,
                    selectedLabelTextStyle: TextStyle(fontSize: GlobalVars.bottonbar_selected_title),
                    unselectedLabelTextStyle: TextStyle(fontSize: GlobalVars.bottonbar_unselected_title),
                    leading:sizingInformation.isDesktop? 
                    Container(
                      padding: EdgeInsets.fromLTRB(10, 10, 20, 10),
                      child: Row(
                      children: [
                       Image(image: AssetImage('assets/images/logo.png'),width: 60,height: 60,),
                       SizedBox(width: 10,),
                       Text('智慧陕理',style: TextStyle(fontSize: GlobalVars.bottonbar_appname_title),)
                        ],
                      ),
                    ):
                    Image(image: AssetImage('assets/images/logo.png'),width: 60,height: 60,),
                    destinations: <NavigationRailDestination>[
                      NavigationRailDestination(
                        icon: Icon(Icons.home),
                        selectedIcon: Icon(Icons.home),
                        label: Text('首页',style: TextStyle(color: Theme.of(context).colorScheme.primary),),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.touch_app),
                        selectedIcon: Icon(Icons.touch_app),
                        label: Text('校内应用',style: TextStyle(color: Theme.of(context).colorScheme.primary),),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person),
                        selectedIcon: Icon(Icons.person),
                        label: Text('我的',style: TextStyle(color: Theme.of(context).colorScheme.primary),),
                      ),
                    ],
                  ),
                  <Widget>[
                    Expanded(child: Home(),),
                    Expanded(child: AppPage(),),
                    Expanded(child: MePage(),),
                  ][railselectedIndex],
                ],
              );
            }
            else{
              return <Widget>[
                Home(),
                AppPage(),
                MePage(),
              ][selectedHomeIndex];
            }
          },
        )
    );
  }
}