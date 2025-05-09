import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
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

class AboutPage extends StatefulWidget{
  const AboutPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AboutPageState();
  }
}

class _AboutPageState extends State<AboutPage>{
  bool _showAppBarTitle = false;

  @override
  void dispose() {
    super.dispose();
    if (GlobalVars.isPrivacyAgreed && GlobalVars.isAnalyticsEnabled && !Platform.isWindows) {
      UmengCommonSdk.onPageEnd("我的 - 应用设置 - 关于智慧陕理");
    }
  }

  @override
  void initState() {
    super.initState();
    if (GlobalVars.isPrivacyAgreed && GlobalVars.isAnalyticsEnabled && !Platform.isWindows) {
      UmengCommonSdk.onPageStart("我的 - 应用设置 - 关于智慧陕理");
    }
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
                title: _showAppBarTitle ? Text("关于智慧陕理") : null,
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
                  SizedBox(width: 12,),
                  Text('关于智慧陕理',style: TextStyle(fontSize: GlobalVars.genericPageTitle),)
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
                        subtitle: Text('智慧陕理所使用的字体为 OPPO Sans 4.0', 
                          style: TextStyle(fontSize: GlobalVars.genericTextSmall)),
                        onTap: () {
                          url = Uri.parse('https://open.oppomobile.com/new/developmentDoc/info?id=13223');
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
    late Response updateServerResponse;
    try{
      updateServerResponse = await GlobalVars.globalDio.get('https://apis.smartsnut.cn/Generic/UpdateCheck/LatestVersion.json');
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
        await GlobalVars.globalDio.download(
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
        await GlobalVars.globalDio.download(
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