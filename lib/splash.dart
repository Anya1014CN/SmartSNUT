import 'package:flutter/material.dart';
import 'package:smartsnut/function_modules.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:smartsnut/login.dart';
import 'package:smartsnut/main.dart';

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
    if(GlobalVars.loginState == 1){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => LoginPage()));
    }if(GlobalVars.loginState == 2){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => HomePage()));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Modules.checkDirectory();
      await Modules.checkLoginState();
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