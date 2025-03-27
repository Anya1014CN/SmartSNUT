import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:smartsnut/login.dart';
import 'package:smartsnut/main.dart';

int loginstate = 0;// 0 - Splash；1 - 登录页；2 - 首页

class SplashPage extends StatefulWidget{
  const SplashPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SplashPageState();
  }

}

class _SplashPageState extends State<SplashPage>{

  //检查登录状态
  checkLoginState() async {
    String loginsuccesspath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/LoginSuccess';
    File loginsuccessfile = File(loginsuccesspath);
    if(await loginsuccessfile.exists() == false){
      if(mounted){
        setState(() {
          loginstate = 1;
          loadPage();
        });
      }
    }else{
      if(mounted){
        setState(() {
          loginstate = 2;
          readStdAccount();
        });
      }
    }
  }

  //读取用户信息并保存在变量中
  readStdAccount() async {
    String stdAccountpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdAccount.json';
    File stdAccountfile = File(stdAccountpath);
    GlobalVars.stdAccount = jsonDecode(await stdAccountfile.readAsString());
    if(mounted){
      setState(() {
        GlobalVars.realName = GlobalVars.stdAccount[0]['UserRealName'];
        GlobalVars.userName = GlobalVars.stdAccount[0]['UserName'];
        GlobalVars.passWord = GlobalVars.stdAccount[0]['PassWord'];
      });
    }
    String stdDetailpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdDetail.json';
    File stdDetailfile = File(stdDetailpath);
    String stdDetailString = await stdDetailfile.readAsString();
    Map<String, dynamic> jsonData = json.decode(stdDetailString);
    GlobalVars.stdDetail = jsonData.map((key, value) => MapEntry(key, value.toString()));
    if(mounted){
      setState(() {
        GlobalVars.enrollTime = GlobalVars.stdDetail['入校时间：']!;
        GlobalVars.graduationTime = GlobalVars.stdDetail['毕业时间：']!;
      });
    }
    emBindCheck();
  }

  //判断用户是否绑定电表账号
  emBindCheck() async {
    String openidtxtpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatUserOpenid.txt';
    File openidtxtfile = File(openidtxtpath);
    if(await openidtxtfile.exists() == true){
      if(mounted){
        setState(() {
          GlobalVars.emBinded = true;
        });
      }else{
        setState(() {
          GlobalVars.emBinded = false;
        });
      }
    }
    String emUserDatapath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/emUserData.json';
    File emUserDatafile = File(emUserDatapath);
    if(await emUserDatafile.exists() == true){
      List emUserData = jsonDecode(await emUserDatafile.readAsString());
      if(emUserData[0]['openId'] != ''){
        if(mounted){
          setState(() {
            GlobalVars.emBinded = true;
          });
        }
      }else{
        setState(() {
          GlobalVars.emBinded = false;
        });
      }
    }
    loadPage();
  }

  //根据登录状态加载页面
  loadPage(){
    if(loginstate == 1){
      Future.delayed(Duration(milliseconds: 200),(){Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => LoginPage()));});
    }if(loginstate == 2){
      Future.delayed(Duration(milliseconds: 200),(){Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => HomePage()));});
    }
  }

  @override
  void initState() {
    super.initState();
    checkLoginState();
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