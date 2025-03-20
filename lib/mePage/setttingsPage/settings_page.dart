import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
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

//电费账号数据
List emUserData = [];
String wechatUserNickname = '';

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
            wechatUserNickname = emUserData[0]['wechatUserNickname'];
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
      electricmeternum = await emnumfile.readAsString();
      await emnumfile.delete();
    }

    String openidpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatUserOpenid.txt';
    File openidfile = File(openidpath);
    if(await openidfile.exists()){
      openid = await openidfile.readAsString();
      await openidfile.delete();
    }

    String wechatIdpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatId.txt';
    File wechatIdfile = File(wechatIdpath);
    if(await wechatIdfile.exists()){
      wechatId = await wechatIdfile.readAsString();
      await wechatIdfile.delete();
    }

    String wechatUserNicknamepath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatUserNickname.txt';
    File wechatUserNicknamefile = File(wechatUserNicknamepath);
    if(await wechatUserNicknamefile.exists()){
      wechatUserNickname = await wechatUserNicknamefile.readAsString();
      await wechatUserNicknamefile.delete();
      setState(() {GlobalVars.emBinded = true;});
    }
    
    emUserData.clear();
    emUserData.add({
      'emNum': electricmeternum,
      'openId': openid,
      'wechatId': wechatId,
      'wechatUserNickname': wechatUserNickname,
    });
    emUserDatafile.writeAsString(jsonEncode(emUserData));
  }

  //保存设置到本地
  saveSettings() async {
    String settingstpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/settings.json';
    File settingstfile = File(settingstpath);
    GlobalVars.settingsTotal = [];
    GlobalVars.settingsTotal.remove('fontSize');
    GlobalVars.settingsTotal.remove('DarkMode');
    GlobalVars.settingsTotal.add({
      'fontSize': GlobalVars.fontsizeint,
      'DarkMode': GlobalVars.darkModeint,
      'ThemeColor': GlobalVars.themeColor
    });
    if(mounted){
    }
    settingstfile.writeAsString(jsonEncode(GlobalVars.settingsTotal));
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
                  Text('应用设置',style: TextStyle(fontSize: GlobalVars.settings_page_title),)
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('通用设置',style: TextStyle(fontSize: GlobalVars.generalsettings_divider_title,color:Theme.of(context).colorScheme.primary),),
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
                        trailing: Icon(Icons.chevron_right),
                        title: Text('字体大小',style: TextStyle(fontSize: GlobalVars.generalsettings_fontsize_title),),
                        subtitle: Text(GlobalVars.fontSize_name,textAlign: TextAlign.end,style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.generalsettings_fontsize_subtitle),),
                        onTap: (){switchTextSize();},
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        trailing: Icon(Icons.chevron_right),
                        title: Text('主题颜色',style: TextStyle(fontSize: GlobalVars.generalsettings_themecolor_title),),
                        subtitle: Text((GlobalVars.themeColor == 0)? '琥珀色':(GlobalVars.themeColor == 1)? '深橙色':(GlobalVars.themeColor == 2)? '曼迪红':(GlobalVars.themeColor == 3)? '深紫色':(GlobalVars.themeColor == 4)? '野鸭绿':(GlobalVars.themeColor == 5)? '粉红色':(GlobalVars.themeColor == 6)? '咖啡色':'鲨鱼灰',textAlign: TextAlign.end,style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.generalsettings_themecolor_subtitle),),
                        onTap: (){switchThemeColor();},
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        trailing: Icon(Icons.chevron_right),
                        title: Text('深色模式',style: TextStyle(fontSize: GlobalVars.generalsettings_darkmode_title),),
                        subtitle: Text((GlobalVars.darkModeint == 0)? '跟随系统':(GlobalVars.darkModeint == 1)? '始终开启':'始终关闭',textAlign: TextAlign.end,style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.generalsettings_darkmode_subtitle),),
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
                  Text('账号设置',style: TextStyle(fontSize: GlobalVars.accountsettings_divider_title,color: Theme.of(context).colorScheme.primary),),
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
                        trailing: Icon(Icons.chevron_right),
                        title: Text('电费账号',style: TextStyle(fontSize: GlobalVars.accountsettings_emaccount_title),),
                        subtitle: Text(GlobalVars.emBinded? '已绑定：$wechatUserNickname':'未绑定',textAlign: TextAlign.end,style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.accountsettings_emaccount_subtitle),),
                        onTap: (){Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => electricmeterbindPage())).then((value) => emBindRead());},
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        trailing: Icon(Icons.chevron_right),
                        title: Text('退出登录',style: TextStyle(fontSize: GlobalVars.accountsettings_authserveraccount_title),),
                        subtitle: Text(GlobalVars.userName,textAlign: TextAlign.end,style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.accountsettings_authserveraccount_subtitle),),
                        onTap: (){
                          showDialog<String>(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: Text('询问：',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
                            content: Text('您确定要退出登录吗？\n退出登录同时会解绑电费账号、清除字体大小、深色模式等设置',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.pop(context, 'Cancel'),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: (){
                                    logout();
                                    Navigator.pop(context);
                                  },
                                child: const Text('确认'),
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
                  Text('关于智慧陕理',style: TextStyle(fontSize: GlobalVars.aboutsnutsettings_divider_title,color:Theme.of(context).colorScheme.primary),),
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
                        trailing: isCheckingUpdate? CircularProgressIndicator():Icon(Icons.chevron_right),
                        title: Text(isCheckingUpdate? '正在检查更新，请稍后...':'检查更新',style: TextStyle(fontSize: GlobalVars.aboutsnutsettings_currentversion_title),),
                        subtitle: Text(GlobalVars.versionCodeString,textAlign: TextAlign.end,style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.generalsettings_fontsize_subtitle),),
                        onTap: isCheckingUpdate? null:(){checkUpdate();},
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        trailing: Icon(Icons.chevron_right),
                        title: Text('官方网站',style: TextStyle(fontSize: GlobalVars.aboutsnutsettings_officialsite_title),),
                        subtitle: Text('https://SmartSNUT.cn',textAlign: TextAlign.end,style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.aboutsnutsettings_officialsite_subtitle),),
                        onTap: () {
                          url = Uri.parse('https://SmartSNUT.cn');
                          launchURL();
                        },
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        trailing: Icon(Icons.chevron_right),
                        title: Text('Github 开源地址',style: TextStyle(fontSize: GlobalVars.aboutsnutsettings_githublink_title),),
                        subtitle: Text('https://github.com/Anya1014CN/SmartSNUT',textAlign: TextAlign.end,style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.aboutsnutsettings_githublink_subtitle),),
                        onTap: () {
                          url = Uri.parse('https://github.com/Anya1014CN/SmartSNUT');
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
                  Text('声明',style: TextStyle(fontSize: GlobalVars.disclamier_divider_title,color: Theme.of(context).colorScheme.primary),),
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
                      Container(
                        padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                        child: Column(
                          children: [
                            Text('智慧陕理使用的所有图标/徽标均来自 Material Design 3 Icons 以及 icons8.com',style: TextStyle(fontSize: GlobalVars.disclamier_title_title),),
                            SizedBox(height: 10,),
                            Text('智慧陕理所使用的字体为 MiSans（https://hyperos.mi.com/font/zh/）',style: TextStyle(fontSize: GlobalVars.disclamier_title_title),),
                            SizedBox(height: 10,),
                            Text('智慧陕理**并非**陕西理工大学官方 APP',style: TextStyle(fontSize: GlobalVars.disclamier_title_title),),
                            SizedBox(height: 10,),
                            Text('智慧陕理 APP 与陕西理工大学**无**任何从属关系',style: TextStyle(fontSize: GlobalVars.disclamier_title_title),),
                            SizedBox(height: 10,),
                            Text('智慧陕理**从未**有意标榜或冒充是陕西理工大学官方APP',style: TextStyle(fontSize: GlobalVars.disclamier_title_title),),
                          ],
                        ),
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
                  Text('开放源代码许可',style: TextStyle(fontSize: GlobalVars.lincense_divider_title,color: Theme.of(context).colorScheme.primary),),
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
                        title: Text('cookie_jar',style: TextStyle(fontSize: GlobalVars.lincense_name_title,fontWeight: FontWeight.bold),),
                        subtitle: Text('A cookie manager for http requests in Dart, by which you can deal with the complex cookie policy and persist cookies easily.',style: TextStyle(fontSize: GlobalVars.lincense_describ_title),),
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
                        title: Text('crypto',style: TextStyle(fontSize: GlobalVars.lincense_name_title,fontWeight: FontWeight.bold),),
                        subtitle: Text('A set of cryptographic hashing functions for Dart.',style: TextStyle(fontSize: GlobalVars.lincense_describ_title),),
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
                        title: Text('dart-lang/sdk',style: TextStyle(fontSize: GlobalVars.lincense_name_title,fontWeight: FontWeight.bold),),
                        subtitle: Text('The Dart SDK, including the VM, JS and Wasm compilers, analysis, core libraries, and more.',style: TextStyle(fontSize: GlobalVars.lincense_describ_title),),
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
                        title: Text('dio_cookie_manager',style: TextStyle(fontSize: GlobalVars.lincense_name_title,fontWeight: FontWeight.bold),),
                        subtitle: Text('A cookie manager combines cookie_jar and dio, based on the interceptor algorithm.',style: TextStyle(fontSize: GlobalVars.lincense_describ_title),),
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
                        title: Text('dio',style: TextStyle(fontSize: GlobalVars.lincense_name_title,fontWeight: FontWeight.bold),),
                        subtitle: Text('A powerful HTTP networking package for Dart/Flutter, supports Global configuration, Interceptors, FormData, Request cancellation, File uploading/downloading, Timeout, Custom adapters, Transformers, etc.',style: TextStyle(fontSize: GlobalVars.lincense_describ_title),),
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
                        title: Text('flex_color_scheme',style: TextStyle(fontSize: GlobalVars.lincense_name_title,fontWeight: FontWeight.bold),),
                        subtitle: Text('A Flutter package to make and use beautiful color scheme based themes.',style: TextStyle(fontSize: GlobalVars.lincense_describ_title),),
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
                        title: Text('flutter',style: TextStyle(fontSize: GlobalVars.lincense_name_title,fontWeight: FontWeight.bold),),
                        subtitle: Text('Flutter makes it easy and fast to build beautiful apps for mobile and beyond',style: TextStyle(fontSize: GlobalVars.lincense_describ_title),),
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
                        title: Text('html',style: TextStyle(fontSize: GlobalVars.lincense_name_title,fontWeight: FontWeight.bold),),
                        subtitle: Text('A Dart implementation of an HTML5 parser.',style: TextStyle(fontSize: GlobalVars.lincense_describ_title),),
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
                        title: Text('intl',style: TextStyle(fontSize: GlobalVars.lincense_name_title,fontWeight: FontWeight.bold),),
                        subtitle: Text('Provides internationalization and localization facilities, including message translation, plurals and genders, date/number formatting and parsing, and bidirectional text.',style: TextStyle(fontSize: GlobalVars.lincense_describ_title),),
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
                        title: Text('open_filex',style: TextStyle(fontSize: GlobalVars.lincense_name_title,fontWeight: FontWeight.bold),),
                        subtitle: Text('A plug-in that can call native APP to open files with string result in flutter, support iOS(DocumentInteraction) / android(intent) / PC(ffi) / web(dart:html)',style: TextStyle(fontSize: GlobalVars.lincense_describ_title),),
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
                        title: Text('path_provider',style: TextStyle(fontSize: GlobalVars.lincense_name_title,fontWeight: FontWeight.bold),),
                        subtitle: Text('A Flutter plugin for finding commonly used locations on the filesystem. Supports Android, iOS, Linux, macOS and Windows. Not all methods are supported on all platforms.',style: TextStyle(fontSize: GlobalVars.lincense_describ_title),),
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
                        title: Text('responsive_builder',style: TextStyle(fontSize: GlobalVars.lincense_name_title,fontWeight: FontWeight.bold),),
                        subtitle: Text('A set of widgets to make responsive UI building in flutter more readable',style: TextStyle(fontSize: GlobalVars.lincense_describ_title),),
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
                        title: Text('url_launcher',style: TextStyle(fontSize: GlobalVars.lincense_name_title,fontWeight: FontWeight.bold),),
                        subtitle: Text('A Flutter plugin for launching a URL.',style: TextStyle(fontSize: GlobalVars.lincense_describ_title),),
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
                        title: Text('provider',style: TextStyle(fontSize: GlobalVars.lincense_name_title,fontWeight: FontWeight.bold),),
                        subtitle: Text('A wrapper around InheritedWidget to make them easier to use and more reusable.',style: TextStyle(fontSize: GlobalVars.lincense_describ_title),),
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

  void showLicense(BuildContext context) async{
    licenseContent = await rootBundle.loadString('assets/credits/License/$licensePath.txt');
    showDialog<String>(
      context: context,
      builder:(BuildContext context) => AlertDialog(
        title: Text('$licenseTitle - License',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
        content: Text(licenseContent,style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
        scrollable: true,
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'OK'),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  //退出登录
  logout() async {
    
    Directory smartSNUTdirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT');
    if(await smartSNUTdirectory.exists() == true){
      await smartSNUTdirectory.delete(recursive: true);
      await smartSNUTdirectory.create();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('退出登录成功'),
      ),
    );
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext ctx) => LoginPage()));
  }

  //切换字体大小
  switchTextSize() {
    int groupValue = GlobalVars.fontsizeint;
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('字体大小',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
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
                            setfontsize();
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('极小',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title))
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
                            setfontsize();
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('超小',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title))
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
                            setfontsize();
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('较小',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title))
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
                            setfontsize();
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('适中',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title))
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
                            setfontsize();
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('较大',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title))
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
                            setfontsize();
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('超大',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title))
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
                            setfontsize();
                          });
                        }
                        saveSettings();
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('极大',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title))
                  ],
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  saveSettings();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
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
      GlobalVars.aboutsnutsettings_officialsite_title = DefaultfontSize.aboutsnutsettings_officialsite_title_defalut + changevalue;
      GlobalVars.aboutsnutsettings_officialsite_subtitle = DefaultfontSize.aboutsnutsettings_officialsite_subtitle_defalut + changevalue;
      GlobalVars.aboutsnutsettings_githublink_title = DefaultfontSize.aboutsnutsettings_githublink_title_defalut + changevalue;
      GlobalVars.aboutsnutsettings_githublink_subtitle = DefaultfontSize.aboutsnutsettings_githublink_subtitle_defalut + changevalue;
      
      GlobalVars.disclamier_divider_title = DefaultfontSize.disclamier_divider_title_default + changevalue;
      GlobalVars.disclamier_title_title = DefaultfontSize.disclamier_title_title_default + changevalue;
      
      GlobalVars.lincense_divider_title = DefaultfontSize.lincense_divider_title_default + changevalue;
      GlobalVars.lincense_name_title = DefaultfontSize.lincense_name_title_default + changevalue;
      GlobalVars.lincense_describ_title = DefaultfontSize.lincense_describ_title_default + changevalue;
      
      //设置完成后刷新页面
      setState(() {});
  }

  //切换主题颜色
  switchThemeColor() {
    int groupValue = GlobalVars.themeColor;
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('主题颜色',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
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
                    Text('琥珀色',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
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
                    Text('深橙色',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
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
                    Text('曼迪红',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
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
                    Text('深紫色',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
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
                    Text('野鸭绿',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
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
                    Text('粉红色',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
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
                    Text('咖啡色',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
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
                    Text('鲨鱼灰',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
                    SizedBox(width: 10,),
                    SizedBox(height: 15,width: 15,child: Container(decoration: BoxDecoration(color: Color(0xFF1D2228)),),)
                  ],
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: (){
                  saveSettings();
                  Navigator.pop(context, 'OK');
                },
                child: const Text('OK'),
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
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('深色模式',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
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
                    Text('跟随系统设置',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title))
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
                    Text('始终开启',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title))
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
                    Text('始终关闭',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title))
                  ],
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: (){
                  Navigator.pop(context);
                  saveSettings();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  //打开链接
  void launchURL() async{
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
        title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
        content: Text('是否要使用系统默认浏览器打开外部链接？\n\n$url',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await launchUrl(url);
              Navigator.pop(context, 'OK');
            },
            child: const Text('确认'),
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
    Response updateServerResponse = await dio.get('https://apis.smartsnut.cn/Generic/UpdateCheck/LatestVersion.json');
    List serverResponseData = updateServerResponse.data;
    if(Platform.isWindows){
      if(serverResponseData[0]['Windows'][0]['LatestVersionInt'] - GlobalVars.versionCodeInt > 0){
        if(mounted){
          showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              scrollable: true,
              title: Text('发现新的 Windows 版智慧陕理  ${GlobalVars.versionCodeString} -> ${serverResponseData[0]['Windows'][0]['LatestVersionString']}',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
              content: Text('是否立即更新？\n\n发布日期：${serverResponseData[0]['Windows'][0]['ReleaseDate']}\n\n更新日志：\n${serverResponseData[0]['Windows'][0]['Changelog']}',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'Cancel'),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    latestDownloadLink = serverResponseData[0]['Windows'][0]['DownloadLink'];
                    Navigator.pop(context, 'OK');
                    getUpdate();
                  },
                  child: const Text('确认'),
                ),
              ],
            ),
          );
        }
      }else{
        if(mounted){
          showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              scrollable: true,
              title: Text('暂未发现新的 Windows 版智慧陕理',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
              content: Text('您正在使用最新版本的 Windows 版智慧陕理：${GlobalVars.versionCodeString}',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
              actions: <Widget>[
                TextButton(
                  onPressed: () {Navigator.pop(context, 'OK');},
                  child: const Text('确认'),
                ),
              ],
            ),
          );
        }
      }
    }if(Platform.isAndroid){
      if(serverResponseData[0]['Android'][0]['LatestVersionInt'] - GlobalVars.versionCodeInt > 0){
        if(mounted){
          showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              scrollable: true,
              title: Text('发现新的 Android 版智慧陕理  ${GlobalVars.versionCodeString} -> ${serverResponseData[0]['Android'][0]['LatestVersionString']}',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
              content: Text('是否立即更新？\n\n发布日期：${serverResponseData[0]['Android'][0]['ReleaseDate']}\n\n更新日志：\n${serverResponseData[0]['Android'][0]['Changelog']}',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'Cancel'),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    latestDownloadLink = serverResponseData[0]['Android'][0]['DownloadLink'];
                    Navigator.pop(context, 'OK');
                    getUpdate();
                  },
                  child: const Text('确认'),
                ),
              ],
            ),
          );
        }
      }else{
        if(mounted){
          showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              scrollable: true,
              title: Text('暂未发现新的 Android 版智慧陕理',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
              content: Text('您正在使用最新版本的 Android 版智慧陕理：${GlobalVars.versionCodeString}',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
              actions: <Widget>[
                TextButton(
                  onPressed: () {Navigator.pop(context, 'OK');},
                  child: const Text('确认'),
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
    showDialog<String>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('正在更新...',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
            content: Column(
              children: [
                Text((Platform.isWindows)? '请勿关闭智慧陕理，下载完成后智慧陕理将会自动重启，完成更新操作':(Platform.isAndroid)? '正在下载安装包，下载完成后智慧陕理将会启动软件更新流程，请您手动进行更新':'正在下载更新...',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
                SizedBox(height: 10,),
                LinearProgressIndicator(
                  value: downloadProgress,
                ),
                SizedBox(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(downloadProgress * 100).toStringAsFixed(2)}%',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
                    Text('${(downloadedSize / 1024 /1024).toStringAsFixed(2)}MB / ${(totalDownloadSize / 1024 / 1024).toStringAsFixed(2)}MB',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title))
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
      Process.start('$exeDir/Windows_latest.exe', [], workingDirectory: exeDir);
    }if(Platform.isAndroid){
      //Android 版更新代码
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
      OpenFilex.open('${(await getApplicationDocumentsDirectory()).path}/Android_latest.apk');
    }
  }
}