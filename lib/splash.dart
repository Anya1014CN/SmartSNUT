import 'package:flutter/material.dart';
import 'package:smartsnut/function_modules.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:smartsnut/login.dart';
import 'package:smartsnut/main.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'dart:io';

class SplashPage extends StatefulWidget{
  const SplashPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SplashPageState();
  }

}

class _SplashPageState extends State<SplashPage>{
  

  //根据登录状态加载页面
  loadPage(){
    if(!GlobalVars.isPrivacyAgreed) {
      // 如果用户尚未同意隐私政策，则显示隐私政策弹窗
      showPrivacyDialog();
    } else if(GlobalVars.loginState == 1){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => LoginPage()));
    } else if(GlobalVars.loginState == 2){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => HomePage()));
    }
  }
  
  // 显示隐私协议对话框
  void showPrivacyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('隐私政策提示', style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('感谢您使用智慧陕理！', style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                SizedBox(height: 10),
                Text('我们非常重视您的个人信息和隐私保护。为了更好地保障您的个人权益，在您使用我们的产品前，请您认真阅读并了解《隐私政策》的全部内容。', 
                  style: TextStyle(fontSize: GlobalVars.alertdialogContent)
                ),
                SizedBox(height: 10),
                Text('我们的产品集成友盟+SDK，友盟+SDK需要收集您的设备Mac地址、唯一设备识别码（IMEI/android ID/IDFA/OPENUDID/GUID/IP地址/SIM 卡 IMSI 信息）以提供统计分析服务，并通过地理位置校准报表数据准确性，提供基础反作弊能力。', 
                  style: TextStyle(fontSize: GlobalVars.alertdialogContent)
                ),
                SizedBox(height: 10),
                Text('您可以选择同意或拒绝数据收集。如果拒绝，应用的核心功能仍将正常工作，但我们将无法获得改进应用的必要数据。', 
                  style: TextStyle(fontSize: GlobalVars.alertdialogContent)
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('不同意'),
              onPressed: () {
                // 用户不同意隐私政策
                GlobalVars.isPrivacyAgreed = true;
                GlobalVars.isAnalyticsEnabled = false;
                Modules.savePrivacySettings().then((_) {
                  // 用户不同意，不初始化友盟SDK
                  if(GlobalVars.loginState == 1){
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => LoginPage()));
                  } else if(GlobalVars.loginState == 2){
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => HomePage()));
                  }
                });
              },
            ),
            TextButton(
              child: Text('同意'),
              onPressed: () {
                // 用户同意隐私政策
                GlobalVars.isPrivacyAgreed = true;
                GlobalVars.isAnalyticsEnabled = true;
                Modules.savePrivacySettings().then((_) {
                  // 完成友盟SDK初始化
                  initUmengAnalytics();
                  if(GlobalVars.loginState == 1){
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => LoginPage()));
                  } else if(GlobalVars.loginState == 2){
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => HomePage()));
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }
  
  // 初始化友盟统计
  void initUmengAnalytics() {
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
      await Modules.readPrivacySettings(); // 读取隐私设置
      await Modules.checkLoginState();
      
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