import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartsnut/function_modules.dart';
import 'package:smartsnut/login.dart';
import 'package:smartsnut/mePage/electricMeterBindPage/electricmeterbind_page.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:url_launcher/url_launcher.dart';

//检查更新状态
bool isCheckingUpdate = false;
String latestDownloadLink = '';//最新版本下载链接

//开源许可
String licenseTitle = '';
String licensePath = '';
String licenseContent = '';

//用于即将打开的链接的完整URL
Uri url = Uri.parse("uri");

class SettingsPage extends StatefulWidget{
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SettingsPage();
  }
}

class _SettingsPage extends State<SettingsPage>{
  bool _showAppBarTitle = false;

  //判断用户是否绑定电表账号
  emBindRead() async {
    //读取用户数据
    String emUserDatapath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emUserData.json';
    File emUserDatafile = File(emUserDatapath);
    if(await emUserDatafile.exists() == true){
      List emUserData = jsonDecode(await emUserDatafile.readAsString());
      if(emUserData[0]['openId'] != ''){
        if(mounted){
          setState(() {
            GlobalVars.wechatUserNickname = emUserData[0]['wechatUserNickname'];
            GlobalVars.emBinded = true;
          });
        }
      }else{
        setState(() {
          GlobalVars.emBinded = false;
        });
      }
    }
    
    //若用户使用旧版数据，则进行迁移
    String emnumpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emnum.txt';
    File emnumfile = File(emnumpath);
    if(await emnumfile.exists()){
      GlobalVars.emNum = int.parse(await emnumfile.readAsString());
      await emnumfile.delete();
    }

    String openidpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatUserOpenid.txt';
    File openidfile = File(openidpath);
    if(await openidfile.exists()){
      GlobalVars.openId = await openidfile.readAsString();
      await openidfile.delete();
    }

    String wechatIdpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatId.txt';
    File wechatIdfile = File(wechatIdpath);
    if(await wechatIdfile.exists()){
      GlobalVars.wechatUserId = await wechatIdfile.readAsString();
      await wechatIdfile.delete();
    }

    String wechatUserNicknamepath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatUserNickname.txt';
    File wechatUserNicknamefile = File(wechatUserNicknamepath);
    if(await wechatUserNicknamefile.exists()){
      GlobalVars.wechatUserNickname = await wechatUserNicknamefile.readAsString();
      await wechatUserNicknamefile.delete();
      setState(() {GlobalVars.emBinded = true;});
    }
    
    GlobalVars.emUserData.clear();
    GlobalVars.emUserData.add({
      'emNum': GlobalVars.emNum,
      'openId': GlobalVars.openId,
      'wechatId': GlobalVars.wechatUserId,
      'wechatUserNickname': GlobalVars.wechatUserNickname,
    });
    emUserDatafile.writeAsString(jsonEncode(GlobalVars.emUserData));
  }

  //保存设置到本地
  saveSettings() async {
    String settingstpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/settings.json';
    File settingstfile = File(settingstpath);
    GlobalVars.settingsTotal.clear();
    GlobalVars.settingsTotal.add({
      'fontSize': GlobalVars.fontsizeint,
      'DarkMode': GlobalVars.darkModeint,
      'ThemeColor': GlobalVars.themeColor,
      'showSatCourse': GlobalVars.showSatCourse,
      'showSunCourse': GlobalVars.showSunCourse,
      'courseBlockColorsint': GlobalVars.courseBlockColorsInt,
      'autoRefreshCourseTable': GlobalVars.autoRefreshCourseTable,
      'lastCourseTableRefreshTime': GlobalVars.lastCourseTableRefreshTime,
      'switchTomorrowCourseAfter20': GlobalVars.switchTomorrowCourseAfter20,
      'switchNextWeekCourseAfter20': GlobalVars.switchNextWeekCourseAfter20,
      'showTzgg': GlobalVars.showTzgg,
    });
    if(mounted){
      setState(() {});
    }
    await settingstfile.writeAsString(jsonEncode(GlobalVars.settingsTotal));
  }

  @override
  void initState() {
    emBindRead();
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification.metrics.pixels > 80 && !_showAppBarTitle) {
            setState(() {
              _showAppBarTitle = true;
            });
          } else if (scrollNotification.metrics.pixels <= 80 &&
              _showAppBarTitle) {
            setState(() {
              _showAppBarTitle = false;
            });
          }
          return true;
        },
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHigh,
                leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back),
                ),
                pinned: true,
                expandedHeight: 0,
                title: _showAppBarTitle ? Text("应用设置") : null,
              ),
            ];
          },
          body: ListView(
            children: [
            Container(
              padding: EdgeInsets.fromLTRB(15, 10, 15, 30),
              child: Row(
                children: [
                  Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/settings.png'):AssetImage('assets/icons/darktheme/settings.png'),height: 40,),
                  SizedBox(width: 10,),
                  Text('应用设置',style: TextStyle(fontSize: GlobalVars.genericPageTitle),)
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('通用设置',style: TextStyle(fontSize: GlobalVars.dividerTitle,color:Theme.of(context).colorScheme.primary),),
                  Divider(height: 5,indent: 20,endIndent: 20,color: Theme.of(context).colorScheme.primary,),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
                color: Theme.of(context).colorScheme.surfaceDim,
                shadowColor: Theme.of(context).colorScheme.onPrimary,
                child: Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    children: [
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.format_size, color: Theme.of(context).colorScheme.primary),
                        trailing: Icon(Icons.chevron_right),
                        title: Text('字体大小',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                        subtitle: Text((GlobalVars.fontsizeint == 0)? '极小':(GlobalVars.fontsizeint == 1)? '超小':(GlobalVars.fontsizeint == 2)? '较小':(GlobalVars.fontsizeint == 3)? '适中':(GlobalVars.fontsizeint == 4)? '较大':(GlobalVars.fontsizeint == 5)? '超大':'极大',
                          style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                        onTap: (){switchTextSize();},
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.palette, color: Theme.of(context).colorScheme.primary),
                        trailing: Icon(Icons.chevron_right),
                        title: Text('主题颜色',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                        subtitle: Text((GlobalVars.themeColor == 0)? '琥珀色':(GlobalVars.themeColor == 1)? '深橙色':(GlobalVars.themeColor == 2)? '曼迪红':(GlobalVars.themeColor == 3)? '深紫色':(GlobalVars.themeColor == 4)? '野鸭绿':(GlobalVars.themeColor == 5)? '粉红色':(GlobalVars.themeColor == 6)? '咖啡色':'鲨鱼灰',
                          style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                        onTap: (){switchThemeColor();},
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.primary),
                        trailing: Icon(Icons.chevron_right),
                        title: Text('深色模式',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                        subtitle: Text((GlobalVars.darkModeint == 0)? '跟随系统':(GlobalVars.darkModeint == 1)? '始终开启':'始终关闭',
                          style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                        onTap: (){switchThemeMode();},
                      ),
                    ],
                  )
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('首页设置',style: TextStyle(fontSize: GlobalVars.dividerTitle,color:Theme.of(context).colorScheme.primary),),
                  Divider(height: 5,indent: 20,endIndent: 20,color: Theme.of(context).colorScheme.primary,),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
                color: Theme.of(context).colorScheme.surfaceDim,
                shadowColor: Theme.of(context).colorScheme.onPrimary,
                child: Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    children: [
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.calendar_view_week, color: Theme.of(context).colorScheme.primary),
                        trailing: Switch(
                          value: GlobalVars.switchTomorrowCourseAfter20,
                          onChanged: (value) {
                            GlobalVars.switchTomorrowCourseAfter20 = value;
                            saveSettings();
                          },
                        ),
                        title: Text('自动切换明日课程',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                        subtitle: Text('在每天晚上的 20:00 之后，自动切换首页的课表到明日课表',style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.notifications, color: Theme.of(context).colorScheme.primary),
                        trailing: Switch(
                          value: GlobalVars.showTzgg,
                          onChanged: (value) {
                            GlobalVars.showTzgg = value;
                            saveSettings();
                          },
                        ),
                        title: Text('在首页显示 “通知公告” 栏目',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                        subtitle: Text('展示学校官网的通知公告',style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                      ),
                    ],
                  )
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('课表设置',style: TextStyle(fontSize: GlobalVars.dividerTitle,color:Theme.of(context).colorScheme.primary),),
                  Divider(height: 5,indent: 20,endIndent: 20,color: Theme.of(context).colorScheme.primary,),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
                color: Theme.of(context).colorScheme.surfaceDim,
                shadowColor: Theme.of(context).colorScheme.onPrimary,
                child: Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    children: [
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.refresh_outlined, color: Theme.of(context).colorScheme.primary),
                        trailing: Switch(
                          value: GlobalVars.autoRefreshCourseTable,
                          onChanged: (value) {
                            GlobalVars.switchNextWeekCourseAfter20 = value;
                            saveSettings();
                          },
                        ),
                        title: Text('自动更新课表',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                        subtitle: Text('当课表数据 >= 24 小时未刷新时，自动从教务系统获取最新的课表数据',style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.calendar_view_week, color: Theme.of(context).colorScheme.primary),
                        trailing: Switch(
                          value: GlobalVars.switchNextWeekCourseAfter20,
                          onChanged: (value) {
                            GlobalVars.switchNextWeekCourseAfter20 = value;
                            saveSettings();
                          },
                        ),
                        title: Text('自动切换下周课表',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                        subtitle: Text('在每周日的晚上 20:00 之后，自动切换 “我的课表” 页面的课表到下周课表',style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.calendar_view_week, color: Theme.of(context).colorScheme.primary),
                        trailing: Switch(
                          value: GlobalVars.showSatCourse,
                          onChanged: (value) {
                            GlobalVars.showSatCourse = value;
                            saveSettings();
                          },
                        ),
                        title: Text('显示周六课程',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                        subtitle: Text('在 "我的课表" 中显示周六的课程',style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.calendar_view_week, color: Theme.of(context).colorScheme.primary),
                        trailing: Switch(
                          value: GlobalVars.showSunCourse,
                          onChanged: (value) {
                            GlobalVars.showSunCourse = value;
                            saveSettings();
                          },
                        ),
                        title: Text('显示周日课程',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                        subtitle: Text('在 "我的课表" 中显示周日的课程',style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.color_lens, color: Theme.of(context).colorScheme.primary),
                        trailing: Icon(Icons.chevron_right),
                        title: Text('课程色系',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                        subtitle: Text((GlobalVars.courseBlockColorsInt == 0)? '莫兰迪色系':'马卡龙色系',
                          style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                        onTap: (){switchCourseBlockColor();},
                      ),
                    ],
                  )
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('账号设置',style: TextStyle(fontSize: GlobalVars.dividerTitle,color: Theme.of(context).colorScheme.primary),),
                  Divider(height: 5,indent: 20,endIndent: 20,color: Theme.of(context).colorScheme.primary,),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
                color: Theme.of(context).colorScheme.surfaceDim,
                shadowColor: Theme.of(context).colorScheme.onPrimary,
                child: Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    children: [
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.electric_bolt, color: Theme.of(context).colorScheme.primary),
                        trailing: Icon(Icons.chevron_right),
                        title: Text('电费账号', style: TextStyle(fontSize: GlobalVars.listTileTitle)),
                        subtitle: Text(GlobalVars.emBinded ? '已绑定：${GlobalVars.wechatUserNickname}' : '未绑定',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: GlobalVars.listTileSubtitle)),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => ElectricmeterbindPage()))
                            .then((value) => emBindRead());
                        },
                      ),
                      Divider(height: 1, indent: 20, endIndent: 20),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                        trailing: Icon(Icons.chevron_right),
                        title: Text('退出登录', style: TextStyle(fontSize: GlobalVars.listTileTitle)),
                        subtitle: Text(GlobalVars.userName,style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: GlobalVars.listTileSubtitle)),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: Row(
                                children: [
                                  Icon(Icons.help),
                                  SizedBox(width: 8),
                                  Text('询问：', style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('您确定要退出登录吗？', style: TextStyle(fontSize: GlobalVars.alertdialogContent, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 10),
                                  Text('退出登录后将会：', style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                                  SizedBox(height: 5),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.primary),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text('解绑电费账号',
                                          style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.primary),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text('清除字体大小、深色模式等设置',
                                          style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.primary),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text('删除所有本地保存的数据',
                                          style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('取消'),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(context).colorScheme.error,
                                  ),
                                  onPressed: (){
                                    logout();
                                    Navigator.pop(context);
                                  },
                                  child: Text('确定退出'),
                                ),
                              ],
                            ),
                          );    
                        },
                      ),
                    ],
                  )
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('关于智慧陕理',style: TextStyle(fontSize: GlobalVars.dividerTitle,color:Theme.of(context).colorScheme.primary),),
                  Divider(height: 5,indent: 20,endIndent: 20,color: Theme.of(context).colorScheme.primary,),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
                color: Theme.of(context).colorScheme.surfaceDim,
                shadowColor: Theme.of(context).colorScheme.onPrimary,
                child: Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    children: [
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.system_update, color: Theme.of(context).colorScheme.primary),
                        trailing: isCheckingUpdate ? CircularProgressIndicator(strokeWidth: 3) : Icon(Icons.chevron_right),
                        title: Text(isCheckingUpdate ? '正在检查更新，请稍后...' : '检查更新', 
                          style: TextStyle(fontSize: GlobalVars.listTileTitle)),
                        subtitle: Text(GlobalVars.versionCodeString, 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: GlobalVars.listTileSubtitle)),
                        onTap: isCheckingUpdate ? null : () {checkUpdate();},
                      ),
                      Divider(height: 1, indent: 20, endIndent: 20),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
                        trailing: Icon(Icons.chevron_right),
                        title: Text('更新日志', 
                          style: TextStyle(fontSize: GlobalVars.listTileTitle)),
                        subtitle: Text('查看版本更新历史记录', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: GlobalVars.listTileSubtitle)),
                        onTap: () async {
                          String changelogContent = await rootBundle.loadString('assets/Changelog.txt');
                          if(context.mounted){
                            showDialog(
                              context: context,
                              builder:(BuildContext context) => AlertDialog(
                                title: Text('历史版本更新日志',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
                                content: Text(changelogContent,style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                                scrollable: true,
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                      Divider(height: 1, indent: 20, endIndent: 20),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.account_box_outlined, color: Theme.of(context).colorScheme.primary),
                        trailing: Icon(Icons.chevron_right),
                        title: Text('微信公众号', 
                          style: TextStyle(fontSize: GlobalVars.listTileTitle)),
                        subtitle: Text('智慧陕理', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: GlobalVars.listTileSubtitle)),
                        onTap: () {
                          showWechatQRCode();
                        },
                      ),
                      Divider(height: 1, indent: 20, endIndent: 20),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
                        trailing: Icon(Icons.chevron_right),
                        title: Text('官方网站', 
                          style: TextStyle(fontSize: GlobalVars.listTileTitle)),
                        subtitle: Text('https://SmartSNUT.cn', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: GlobalVars.listTileSubtitle)),
                        onTap: () {
                          url = Uri.parse('https://SmartSNUT.cn');
                          launchURL();
                        },
                      ),
                      Divider(height: 1, indent: 20, endIndent: 20),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                        trailing: Icon(Icons.chevron_right),
                        title: Text('Github 开源地址', 
                          style: TextStyle(fontSize: GlobalVars.listTileTitle)),
                        subtitle: Text('https://github.com/Anya1014CN/SmartSNUT', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: GlobalVars.listTileSubtitle)),
                        onTap: () {
                          url = Uri.parse('https://github.com/Anya1014CN/SmartSNUT');
                          launchURL();
                        },
                      ),
                      Divider(height: 1, indent: 20, endIndent: 20),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                        trailing: Icon(Icons.chevron_right),
                        title: Text('Gitee 开源地址', 
                          style: TextStyle(fontSize: GlobalVars.listTileTitle)),
                        subtitle: Text('https://gitee.com/Anya1014CN/SmartSNUT', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: GlobalVars.listTileSubtitle)),
                        onTap: () {
                          url = Uri.parse('https://gitee.com/Anya1014CN/SmartSNUT');
                          launchURL();
                        },
                      ),
                      Divider(height: 1, indent: 20, endIndent: 20),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.verified, color: Theme.of(context).colorScheme.primary),
                        trailing: Icon(Icons.chevron_right),
                        title: Text('APP 备案号', 
                          style: TextStyle(fontSize: GlobalVars.listTileTitle)),
                        subtitle: Text('陕ICP备2024023952号-3A', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: GlobalVars.listTileSubtitle)),
                        onTap: () {
                          url = Uri.parse('https://beian.miit.gov.cn/');
                          launchURL();
                        },
                      ),
                    ],
                  )
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('声明',style: TextStyle(fontSize: GlobalVars.dividerTitle,color: Theme.of(context).colorScheme.primary),),
                  Divider(height: 5,indent: 20,endIndent: 20,color: Theme.of(context).colorScheme.primary,),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
                color: Theme.of(context).colorScheme.surfaceDim,
                shadowColor: Theme.of(context).colorScheme.onPrimary,
                child: Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.copyright, color: Theme.of(context).colorScheme.primary),
                        title: Text('素材来源', style: TextStyle(fontSize: GlobalVars.listTileTitle, fontWeight: FontWeight.bold)),
                        subtitle: Text('智慧陕理使用的所有图标/徽标均来自 Material Design 3 Icons 以及 icons8.com', 
                          style: TextStyle(fontSize: GlobalVars.genericTextSmall)),
                      ),
                      Divider(height: 1, indent: 20, endIndent: 20),
                      ListTile(
                        leading: Icon(Icons.font_download, color: Theme.of(context).colorScheme.primary),
                        title: Text('字体使用', style: TextStyle(fontSize: GlobalVars.listTileTitle, fontWeight: FontWeight.bold)),
                        subtitle: Text('智慧陕理所使用的字体为 MiSans', 
                          style: TextStyle(fontSize: GlobalVars.genericTextSmall)),
                        onTap: () {
                          url = Uri.parse('https://hyperos.mi.com/font/zh/');
                          launchURL();
                        },
                        trailing: Icon(Icons.open_in_new, size: 16),
                      ),
                      Divider(height: 1, indent: 20, endIndent: 20),
                      ExpansionTile(
                        leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                        title: Text('非官方声明', style: TextStyle(fontSize: GlobalVars.listTileTitle, fontWeight: FontWeight.bold)),
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(20, 0, 20, 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.primary),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text('智慧陕理并非陕西理工大学官方APP',
                                        style: TextStyle(fontSize: GlobalVars.genericTextSmall)),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.primary),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text('智慧陕理APP与陕西理工大学无任何从属关系',
                                        style: TextStyle(fontSize: GlobalVars.genericTextSmall)),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.primary),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text('智慧陕理从未有意标榜或冒充是陕西理工大学官方APP',
                                        style: TextStyle(fontSize: GlobalVars.genericTextSmall)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('开放源代码许可',style: TextStyle(fontSize: GlobalVars.dividerTitle,color: Theme.of(context).colorScheme.primary),),
                  Divider(height: 5,indent: 20,endIndent: 20,color: Theme.of(context).colorScheme.primary,),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
                color: Theme.of(context).colorScheme.surfaceDim,
                shadowColor: Theme.of(context).colorScheme.onPrimary,
                child: Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    children: [
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        title: Text('cookie_jar',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                        subtitle: Text('A cookie manager for http requests in Dart, by which you can deal with the complex cookie policy and persist cookies easily.',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                        trailing: Icon(Icons.chevron_right),
                        onTap: (){
                          licenseTitle = 'cookie_jar';
                          licensePath = 'cookie_jar_LICENSE';
                          showLicense(context);
                        },
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        title: Text('crypto',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                        subtitle: Text('A set of cryptographic hashing functions for Dart.',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                        trailing: Icon(Icons.chevron_right),
                        onTap: (){
                          licenseTitle = 'crypto';
                          licensePath = 'crypto_LICENSE';
                          showLicense(context);
                        },
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        title: Text('dart-lang/sdk',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                        subtitle: Text('The Dart SDK, including the VM, JS and Wasm compilers, analysis, core libraries, and more.',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                        trailing: Icon(Icons.chevron_right),
                        onTap: (){
                          licenseTitle = 'dart-lang/sdk';
                          licensePath = 'dart-lang&sdk_LICENSE';
                          showLicense(context);
                        },
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        title: Text('ddddocr',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                        subtitle: Text('一个容易使用的通用验证码识别python库',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                        trailing: Icon(Icons.chevron_right),
                        onTap: (){
                          licenseTitle = 'ddddocr';
                          licensePath = 'ddddocr_LICENSE';
                          showLicense(context);
                        },
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        title: Text('dio_cookie_manager',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                        subtitle: Text('A cookie manager combines cookie_jar and dio, based on the interceptor algorithm.',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                        trailing: Icon(Icons.chevron_right),
                        onTap: (){
                          licenseTitle = 'dio_cookie_manager';
                          licensePath = 'dio_cookie_manager_LICENSE';
                          showLicense(context);
                        },
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        title: Text('dio',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                        subtitle: Text('A powerful HTTP networking package for Dart/Flutter, supports Global configuration, Interceptors, FormData, Request cancellation, File uploading/downloading, Timeout, Custom adapters, Transformers, etc.',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                        trailing: Icon(Icons.chevron_right),
                        onTap: (){
                          licenseTitle = 'dio';
                          licensePath = 'dio_LICENSE';
                          showLicense(context);
                        },
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        title: Text('flex_color_scheme',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                        subtitle: Text('A Flutter package to make and use beautiful color scheme based themes.',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                        trailing: Icon(Icons.chevron_right),
                        onTap: (){
                          licenseTitle = 'flex_color_scheme';
                          licensePath = 'flex_color_scheme_LICENSE';
                          showLicense(context);
                        },
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        title: Text('flutter',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                        subtitle: Text('Flutter makes it easy and fast to build beautiful apps for mobile and beyond',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                        trailing: Icon(Icons.chevron_right),
                        onTap: (){
                          licenseTitle = 'flutter';
                          licensePath = 'flutter_LICENSE';
                          showLicense(context);
                        },
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        title: Text('html',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                        subtitle: Text('A Dart implementation of an HTML5 parser.',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                        trailing: Icon(Icons.chevron_right),
                        onTap: (){
                          licenseTitle = 'html';
                          licensePath = 'html_LICENSE';
                          showLicense(context);
                        },
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        title: Text('intl',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                        subtitle: Text('Provides internationalization and localization facilities, including message translation, plurals and genders, date/number formatting and parsing, and bidirectional text.',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                        trailing: Icon(Icons.chevron_right),
                        onTap: (){
                          licenseTitle = 'intl';
                          licensePath = 'intl_LICENSE';
                          showLicense(context);
                        },
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        title: Text('open_filex',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                        subtitle: Text('A plug-in that can call native APP to open files with string result in flutter, support iOS(DocumentInteraction) / android(intent) / PC(ffi) / web(dart:html)',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                        trailing: Icon(Icons.chevron_right),
                        onTap: (){
                          licenseTitle = 'open_filex';
                          licensePath = 'open_filex_LICENSE';
                          showLicense(context);
                        },
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        title: Text('path_provider',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                        subtitle: Text('A Flutter plugin for finding commonly used locations on the filesystem. Supports Android, iOS, Linux, macOS and Windows. Not all methods are supported on all platforms.',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                        trailing: Icon(Icons.chevron_right),
                        onTap: (){
                          licenseTitle = 'path_provider';
                          licensePath = 'path_provider_LICENSE';
                          showLicense(context);
                        },
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        title: Text('responsive_builder',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                        subtitle: Text('A set of widgets to make responsive UI building in flutter more readable',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                        trailing: Icon(Icons.chevron_right),
                        onTap: (){
                          licenseTitle = 'responsive_builder';
                          licensePath = 'responsive_builder_LICENSE';
                          showLicense(context);
                        },
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        title: Text('url_launcher',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                        subtitle: Text('A Flutter plugin for launching a URL.',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                        trailing: Icon(Icons.chevron_right),
                        onTap: (){
                          licenseTitle = 'url_launcher';
                          licensePath = 'url_launcher_LICENSE';
                          showLicense(context);
                          },
                        ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        title: Text('provider',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                        subtitle: Text('A wrapper around InheritedWidget to make them easier to use and more reusable.',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                        trailing: Icon(Icons.chevron_right),
                        onTap: (){
                          licenseTitle = 'provider';
                          licensePath = 'provider_LICENSE';
                          showLicense(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //显示微信公众号二维码
  showWechatQRCode() async{
    if(context.mounted){
      showDialog(
        context: context,
        builder:(BuildContext context) => AlertDialog(
          title: Text('微信公众号 - 智慧陕理',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
          content: Column(
            children: [
              Text('关注公众号，即可订阅 “智慧陕理” 的最新消息，向我们发送意见与建议、获取技术支持',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
              SizedBox(height: 12,),
              Divider(height: 15,indent: 20,endIndent: 20,),
              SizedBox(height: 12,),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: Image.asset('assets/images/WechatQRCode.png',fit: BoxFit.fitWidth),
              )
            ],
          ),
          scrollable: true,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  //开放源代码许可
  showLicense(BuildContext context) async{
    licenseContent = await rootBundle.loadString('assets/credits/License/$licensePath.txt');
    if(context.mounted){
      showDialog(
        context: context,
        builder:(BuildContext context) => AlertDialog(
          title: Text('$licenseTitle - License',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
          content: Text(licenseContent,style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
          scrollable: true,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  //退出登录
  logout() async {
    
    Directory smartSNUTdirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT');
    if(await smartSNUTdirectory.exists() == true){
      await smartSNUTdirectory.delete(recursive: true);
      await smartSNUTdirectory.create();
    }

    if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
          content: Text('退出登录成功'),
        ),
      );
    }

    if(mounted){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext ctx) => LoginPage()));
    }
  }

  //切换字体大小
  switchTextSize() {
    int groupValue = GlobalVars.fontsizeint;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('字体大小',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 0,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 0;
                        if(mounted){
                          setState((){
                            GlobalVars.fontsizeint = 0;
                            Modules.setFontSize();
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('极小',style: TextStyle(fontSize: GlobalVars.alertdialogContent))
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 1,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 1;
                        if(mounted){
                          setState((){
                            GlobalVars.fontsizeint = 1;
                            Modules.setFontSize();
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('超小',style: TextStyle(fontSize: GlobalVars.alertdialogContent))
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 2,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 2;
                        if(mounted){
                          setState((){
                            GlobalVars.fontsizeint = 2;
                            Modules.setFontSize();
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('较小',style: TextStyle(fontSize: GlobalVars.alertdialogContent))
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 3,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 3;
                        if(mounted){
                          setState((){
                            GlobalVars.fontsizeint = 3;
                            Modules.setFontSize();
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('适中',style: TextStyle(fontSize: GlobalVars.alertdialogContent))
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 4,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 4;
                        if(mounted){
                          setState((){
                            GlobalVars.fontsizeint = 4;
                            Modules.setFontSize();
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('较大',style: TextStyle(fontSize: GlobalVars.alertdialogContent))
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 5,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 5;
                        if(mounted){
                          setState((){
                            GlobalVars.fontsizeint = 5;
                            Modules.setFontSize();
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('超大',style: TextStyle(fontSize: GlobalVars.alertdialogContent))
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 6,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 6;
                        if(mounted){
                          setState((){
                            GlobalVars.fontsizeint = 6;
                            Modules.setFontSize();
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('极大',style: TextStyle(fontSize: GlobalVars.alertdialogContent))
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  saveSettings();
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  //切换主题颜色
  switchThemeColor() {
    int groupValue = GlobalVars.themeColor;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('主题颜色',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 0,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 0;
                        if(mounted){
                          setState((){
                            GlobalVars.themeColor = 0;
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('琥珀色',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                    SizedBox(width: 10,),
                    SizedBox(height: 15,width: 15,child: Container(decoration: BoxDecoration(color: Color(0xFFE65100)),),)
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 1,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 1;
                        if(mounted){
                          setState((){
                            GlobalVars.themeColor = 1;
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('深橙色',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                    SizedBox(width: 10,),
                    SizedBox(height: 15,width: 15,child: Container(decoration: BoxDecoration(color: Color(0xFFBF360C)),),)
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 2,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 2;
                        if(mounted){
                          setState((){
                            GlobalVars.themeColor = 2;
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('曼迪红',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                    SizedBox(width: 10,),
                    SizedBox(height: 15,width: 15,child: Container(decoration: BoxDecoration(color: Color(0xFFCD5758)),),)
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 3,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 3;
                        if(mounted){
                          setState((){
                            GlobalVars.themeColor = 3;
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('深紫色',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                    SizedBox(width: 10,),
                    SizedBox(height: 15,width: 15,child: Container(decoration: BoxDecoration(color: Color(0xFF4527A0)),),)
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 4,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 4;
                        if(mounted){
                          setState((){
                            GlobalVars.themeColor = 4;
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('野鸭绿',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                    SizedBox(width: 10,),
                    SizedBox(height: 15,width: 15,child: Container(decoration: BoxDecoration(color: Color(0xFF2D4421)),),)
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 5,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 5;
                        if(mounted){
                          setState((){
                            GlobalVars.themeColor = 5;
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('粉红色',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                    SizedBox(width: 10,),
                    SizedBox(height: 15,width: 15,child: Container(decoration: BoxDecoration(color: Color(0xFFBC004B)),),)
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 6,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 6;
                        if(mounted){
                          setState((){
                            GlobalVars.themeColor = 6;
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('咖啡色',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                    SizedBox(width: 10,),
                    SizedBox(height: 15,width: 15,child: Container(decoration: BoxDecoration(color: Color(0xFF452F2B)),),)
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 7,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 7;
                        if(mounted){
                          setState((){
                            GlobalVars.themeColor = 7;
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('鲨鱼灰',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                    SizedBox(width: 10,),
                    SizedBox(height: 15,width: 15,child: Container(decoration: BoxDecoration(color: Color(0xFF1D2228)),),)
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: (){
                  saveSettings();
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  //切换主题模式
  switchThemeMode() {
    int groupValue = GlobalVars.darkModeint;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('深色模式',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 0,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 0;
                        if(mounted){
                          setState((){
                            GlobalVars.darkModeint = 0;
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('跟随系统设置',style: TextStyle(fontSize: GlobalVars.alertdialogContent))
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 1,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 1;
                        if(mounted){
                          setState((){
                            GlobalVars.darkModeint = 1;
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('始终开启',style: TextStyle(fontSize: GlobalVars.alertdialogContent))
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 2,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 2;
                        if(mounted){
                          setState((){
                            GlobalVars.darkModeint = 2;
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('始终关闭',style: TextStyle(fontSize: GlobalVars.alertdialogContent))
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: (){
                  Navigator.pop(context);
                  saveSettings();
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  //切换课程色系
  switchCourseBlockColor() {
    int groupValue = GlobalVars.courseBlockColorsInt;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('课程色系',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 0,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 0;
                        if(mounted){
                          setState((){
                            GlobalVars.courseBlockColorsInt = 0;
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('莫兰迪色系',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio(
                      value: 1,
                      groupValue: groupValue,
                      onChanged: (value){
                        groupValue = 1;
                        if(mounted){
                          setState((){
                            GlobalVars.courseBlockColorsInt = 1;
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('马卡龙色系',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: (){
                  saveSettings();
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  //打开链接
  void launchURL() async{
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
        title: Row(
          children: [
            Icon(Icons.help),
            SizedBox(width: 8,),
            Text('询问：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
          ],
        ),
        content: Text('是否要使用系统默认浏览器打开外部链接？\n\n$url',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await launchUrl(url);
              if(context.mounted){
                Navigator.pop(context);
              }
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  //检查更新
  checkUpdate() async {
    if(mounted){
      setState(() {
        isCheckingUpdate = true;
      });
    }
    Dio dio = Dio();
    late Response updateServerResponse;
    try{
      updateServerResponse = await dio.get('https://apis.smartsnut.cn/Generic/UpdateCheck/LatestVersion.json');
    }catch(e){
      return;
    }
    List serverResponseData = updateServerResponse.data;
    if(Platform.isWindows){
      if(serverResponseData[0]['Windows'][0]['LatestVersionInt'] - GlobalVars.versionCodeInt > 0){
        if(mounted){
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              scrollable: true,
              title: Text('发现新的 Windows 版智慧陕理  ${GlobalVars.versionCodeString} -> ${serverResponseData[0]['Windows'][0]['LatestVersionString']}',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
              content: Text('是否立即更新？\n\n发布日期：${serverResponseData[0]['Windows'][0]['ReleaseDate']}\n\n更新日志：\n${serverResponseData[0]['Windows'][0]['Changelog']}',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    latestDownloadLink = serverResponseData[0]['Windows'][0]['DownloadLink'];
                    Navigator.pop(context);
                    getUpdate();
                  },
                  child: Text('确定'),
                ),
              ],
            ),
          );
        }
      }else{
        if(mounted){
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              scrollable: true,
              title: Text('暂未发现新的 Windows 版智慧陕理',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
              content: Text('您正在使用最新版本的 Windows 版智慧陕理：${GlobalVars.versionCodeString}',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
              actions: [
                TextButton(
                  onPressed: () {Navigator.pop(context);},
                  child: Text('确定'),
                ),
              ],
            ),
          );
        }
      }
    }if(Platform.isAndroid){
      if(serverResponseData[0]['Android'][0]['LatestVersionInt'] - GlobalVars.versionCodeInt > 0){
        if(mounted){
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              scrollable: true,
              title: Text('发现新的 Android 版智慧陕理  ${GlobalVars.versionCodeString} -> ${serverResponseData[0]['Android'][0]['LatestVersionString']}',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
              content: Text('是否立即更新？\n\n发布日期：${serverResponseData[0]['Android'][0]['ReleaseDate']}\n\n更新日志：\n${serverResponseData[0]['Android'][0]['Changelog']}',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    latestDownloadLink = serverResponseData[0]['Android'][0]['DownloadLink'];
                    Navigator.pop(context);
                    getUpdate();
                  },
                  child: Text('确定'),
                ),
              ],
            ),
          );
        }
      }else{
        if(mounted){
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              scrollable: true,
              title: Text('暂未发现新的 Android 版智慧陕理',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
              content: Text('您正在使用最新版本的 Android 版智慧陕理：${GlobalVars.versionCodeString}',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
              actions: [
                TextButton(
                  onPressed: () {Navigator.pop(context);},
                  child: Text('确定'),
                ),
              ],
            ),
          );
        }
      }
    }
    if(mounted){
      setState(() {
        isCheckingUpdate = false;
      });
    }
  }

  //下载更新
  getUpdate() async {
    int downloadedSize = 0;
    int totalDownloadSize = 0;
    double downloadProgress = 0;
    Dio dio = Dio();
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('正在更新...',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Column(
              children: [
                Text((Platform.isWindows)? '请勿关闭智慧陕理，下载完成后智慧陕理将会自动重启，完成更新操作':(Platform.isAndroid)? '正在下载安装包，下载完成后智慧陕理将会启动软件更新流程，请您手动进行更新':'正在下载更新...',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                SizedBox(height: 10,),
                LinearProgressIndicator(
                  value: downloadProgress,
                ),
                SizedBox(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(downloadProgress * 100).toStringAsFixed(2)}%',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                    Text('${(downloadedSize / 1024 /1024).toStringAsFixed(2)}MB / ${(totalDownloadSize / 1024 / 1024).toStringAsFixed(2)}MB',style: TextStyle(fontSize: GlobalVars.alertdialogContent))
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
    
    if(Platform.isWindows){
    //Windows 版更新代码
      String exePath = Platform.resolvedExecutable;
      String exeDir = File(exePath).parent.path;
      try{
        await dio.download(
          latestDownloadLink,
          '$exeDir/Windows_latest.exe',
          onReceiveProgress: (count, total) {
            if(mounted){
              setState(() {
                downloadProgress = count / total;
              });
            }
          },
        );
      }catch(e){
        if(mounted){
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              scrollable: true,
              title: Row(
                children: [
                  Icon(Icons.error),
                  SizedBox(width: 8,),
                  Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
                ],
              ),
              content: Text('Windows 版更新下载失败，请您稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
              actions: [
                TextButton(
                  onPressed: () {Navigator.pop(context);},
                  child: Text('确定'),
                ),
              ],
            ),
          );
        }
        return;
      }
      Process.start('$exeDir/Windows_latest.exe', [], workingDirectory: exeDir);
    }if(Platform.isAndroid){
      //Android 版更新代码
      try{
        await dio.download(
          latestDownloadLink,
          '${(await getApplicationDocumentsDirectory()).path}/Android_latest.apk',
          onReceiveProgress: (count, total) {
            if(mounted){
              setState(() {
                downloadProgress = count / total;
                downloadedSize = count;
                totalDownloadSize = total;
              });
            }
          },
        );
      }catch(e){
        if(mounted){
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              scrollable: true,
              title: Row(
                children: [
                  Icon(Icons.error),
                  SizedBox(width: 8,),
                  Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
                ],
              ),
              content: Text('Android 版更新下载失败，请您稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
              actions: [
                TextButton(
                  onPressed: () {Navigator.pop(context);},
                  child: Text('确定'),
                ),
              ],
            ),
          );
        }
        return;
      }
      OpenFilex.open('${(await getApplicationDocumentsDirectory()).path}/Android_latest.apk');
    }
  }
}