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

    //弹出对话框字体
    GlobalVars.alertdialogTitle = DefaultfontSize.alertdialogTitle + changevalue;
    GlobalVars.alertdialogContent = DefaultfontSize.alertdialogContent + changevalue;

    //通用页面字体
    GlobalVars.splashPageTitle = DefaultfontSize.splashPageTitle + changevalue;
    GlobalVars.bottonbarAppnameTitle = DefaultfontSize.bottonbarAppnameTitle + changevalue;
    GlobalVars.bottonbarSelectedTitle = DefaultfontSize.bottonbarSelectedTitle + changevalue;
    GlobalVars.bottonbarUnselectedTitle = DefaultfontSize.bottonbarUnselectedTitle + changevalue;
    GlobalVars.genericPageTitle = DefaultfontSize.genericPageTitle + changevalue;
    GlobalVars.genericPageTitleSmall = DefaultfontSize.genericPageTitleSmall + changevalue;
    GlobalVars.genericGreetingTitle = DefaultfontSize.genericGreetingTitle + changevalue;
    GlobalVars.genericFloationActionButtonTitle = DefaultfontSize.genericFloationActionButtonTitle + changevalue;
    GlobalVars.dividerTitle = DefaultfontSize.dividerTitle + changevalue;
    GlobalVars.listTileTitle = DefaultfontSize.listTileTitle + changevalue;
    GlobalVars.listTileSubtitle = DefaultfontSize.listTileSubtitle + changevalue;
    GlobalVars.genericFunctionsButtonTitle = DefaultfontSize.genericFunctionsButtonTitle + changevalue;
    GlobalVars.genericSwitchContainerTitle = DefaultfontSize.genericSwitchContainerTitle + changevalue;
    GlobalVars.genericSwitchMenuTitle = DefaultfontSize.genericSwitchMenuTitle + changevalue;
    GlobalVars.genericTextSmall = DefaultfontSize.genericTextSmall + changevalue;
    GlobalVars.genericTextMedium = DefaultfontSize.genericTextMedium + changevalue;
    GlobalVars.genericTextLarge = DefaultfontSize.genericTextLarge + changevalue;
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
                    selectedLabelTextStyle: TextStyle(fontSize: GlobalVars.bottonbarSelectedTitle),
                    unselectedLabelTextStyle: TextStyle(fontSize: GlobalVars.bottonbarUnselectedTitle),
                    leading:sizingInformation.isDesktop? 
                    Container(
                      padding: EdgeInsets.fromLTRB(10, 10, 20, 10),
                      child: Row(
                      children: [
                       Image(image: AssetImage('assets/images/logo.png'),width: 60,height: 60,),
                       SizedBox(width: 10,),
                       Text('智慧陕理',style: TextStyle(fontSize: GlobalVars.bottonbarAppnameTitle),)
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