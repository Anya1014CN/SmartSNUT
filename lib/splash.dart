import 'dart:io';

import 'package:flutter/material.dart';
import 'package:smartsnut/function_modules.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:smartsnut/login.dart';
import 'package:smartsnut/main.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

//用于即将打开的链接
Uri url = Uri.parse("uri");

class SplashPage extends StatefulWidget{
  const SplashPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SplashPageState();
  }

}

class _SplashPageState extends State<SplashPage>{

  //打开链接
  void launchURL() async{
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
        title: Row(
          children: [
            Icon(Icons.help),
            SizedBox(width: 8),
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


  //根据登录状态加载页面
  loadPage(){
    if(GlobalVars.loginState == 1){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => LoginPage()));
    } else if(GlobalVars.loginState == 2){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => HomePage()));
    }
  }
  
  // 显示用户协议与隐私政策对话框
  showPrivacyDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => Container(
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '用户协议 & 隐私政策',
                      style: TextStyle(
                        fontSize: GlobalVars.alertdialogTitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.25,
                  child: SingleChildScrollView(
                    child: ListBody(
                      children: <Widget>[
                        Text('感谢您使用智慧陕理！', style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                        SizedBox(height: 10),
                        Text('我们非常重视您的个人信息和隐私保护。为了更好地保障您的个人权益，在您使用我们的产品前，请您认真阅读并了解《用户协议》和《隐私政策》的全部内容。', 
                          style: TextStyle(fontSize: GlobalVars.alertdialogContent)
                        ),
                        SizedBox(height: 10),
                        Text('点击下方按钮可查看相关协议的详细内容：', 
                          style: TextStyle(fontSize: GlobalVars.alertdialogContent)
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // 用户协议和隐私政策按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        url = Uri.parse('https://smartsnut.cn/Docs/TermOfUse/');
                        launchURL();
                      },
                      icon: Icon(Icons.description),
                      label: Text('用户协议', style: TextStyle(fontSize: GlobalVars.genericTextMedium)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        url = Uri.parse('https://smartsnut.cn/Docs/PrivacyPolicy/');
                        launchURL();
                      },
                      icon: Icon(Icons.privacy_tip),
                      label: Text('隐私政策', style: TextStyle(fontSize: GlobalVars.genericTextMedium)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // 用户不同意隐私政策
                          GlobalVars.isPrivacyAgreed = true;
                          GlobalVars.isAnalyticsEnabled = false;
                          await Modules.saveSettings();
                          if(context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          minimumSize: Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        child: Text(
                          '不同意',
                          style: TextStyle(
                            fontSize: GlobalVars.genericTextMedium,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // 用户同意隐私政策
                          GlobalVars.isPrivacyAgreed = true;
                          GlobalVars.isAnalyticsEnabled = true;
                          await Modules.saveSettings();
                          initUmengAnalytics();
                          if(context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          minimumSize: Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '同意',
                          style: TextStyle(
                            fontSize: GlobalVars.genericTextMedium,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // 初始化友盟统计
  void initUmengAnalytics() {
    // Windows 版不要初始化友盟统计
    if(Platform.isWindows) return;
    // 使用正确的 initCommon 方法初始化友盟统计
    UmengCommonSdk.initCommon(
      GlobalVars.umengAndroidAppKey, 
      GlobalVars.umengIOSAppKey, 
      GlobalVars.umengChannel
    );
    
    // 设置场景类型（启动时集成）
    UmengCommonSdk.setPageCollectionModeManual();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Modules.checkDirectory();
      await Modules.checkLoginState();

      if(!GlobalVars.isPrivacyAgreed) {
        // 如果用户尚未同意隐私政策，则显示隐私政策弹窗
        await showPrivacyDialog();
      }
      
      // 如果已同意隐私政策且启用了统计，初始化友盟统计
      if (GlobalVars.isPrivacyAgreed && GlobalVars.isAnalyticsEnabled) {
        initUmengAnalytics();
      }
      
      if(GlobalVars.loginState == 2){
        await Modules.readStdAccount();
        await Modules.readEMInfo();
      }
      loadPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.black,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png',width: (MediaQuery.of(context).size.width)*0.3,),
              SizedBox(height: 10,),
              Text('智慧陕理',style: TextStyle(color: Colors.white,fontSize: GlobalVars.splashPageTitle),)
            ],
          ),
        ),
      ),
    );
  }
}