import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smartsnut/login.dart';
import 'package:smartsnut/mePage/guidePage/guide_page.dart';
import 'package:smartsnut/mePage/electricMeterBindPage/electricmeterbind_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartsnut/mePage/setttingsPage/settings_page.dart';
import 'package:smartsnut/globalvars.dart';


bool isloggedin = false;//判断是否已经登录

class MePage extends StatefulWidget{
  const MePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MePageState();
  }
}

class _MePageState extends State<MePage>{

  @override
  void initState() {
    super.initState();
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    
    return ListView(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(23, 50, 0, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${GlobalVars.realName}，',style: TextStyle(fontSize: GlobalVars.genericGreetingTitle,fontWeight: FontWeight.w300),),
              Text('这是你在陕理工的',style: TextStyle(fontSize: GlobalVars.genericGreetingTitle,fontWeight: FontWeight.w300),),
              Row(
                children: [
                  Text('第 ',style: TextStyle(fontSize: GlobalVars.genericGreetingTitle,fontWeight: FontWeight.w300),),
                  Text('${GlobalVars.today.difference(DateTime.parse(GlobalVars.enrollTime)).inDays}',style: TextStyle(fontSize: GlobalVars.genericGreetingTitle + 5,fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary),),
                  Text(' 天。',style: TextStyle(fontSize: GlobalVars.genericGreetingTitle,fontWeight: FontWeight.w300),),
                ],
              ),
              Text('距离毕业还',style: TextStyle(fontSize: GlobalVars.genericGreetingTitle,fontWeight: FontWeight.w300),),
              Row(
                children: [
                  Text('有 ',style: TextStyle(fontSize: GlobalVars.genericGreetingTitle,fontWeight: FontWeight.w300),),
                  Text('${DateTime.parse(GlobalVars.graduationTime).difference(GlobalVars.today).inDays}',style: TextStyle(fontSize: GlobalVars.genericGreetingTitle + 5,fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.error),),
                  Text(' 天。',style: TextStyle(fontSize: GlobalVars.genericGreetingTitle,fontWeight: FontWeight.w300),),
                ],
              ),
            ],
          )
        ),
        Divider(height: 5,indent: 20,endIndent: 20,color: Theme.of(context).colorScheme.primary,),
        Container(
          padding: EdgeInsets.fromLTRB(30, 10, 30, 10),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            shadowColor: Theme.of(context).colorScheme.onPrimary,
            color: Theme.of(context).colorScheme.surfaceDim,
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/bulb.png'):AssetImage('assets/icons/darktheme/bulb.png'),height: 36,),
                  SizedBox(height: 10,),
                  Text(GlobalVars.hint,style: TextStyle(fontSize: GlobalVars.genericTextMedium,fontWeight: FontWeight.bold,),)
                ],
              ),
            ),
          ),
        ),
        Divider(height: 5,indent: 20,endIndent: 20,color: Theme.of(context).colorScheme.primary,),
        Container(
          padding: EdgeInsets.fromLTRB(30, 10, 30, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 125,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        shadowColor: Theme.of(context).colorScheme.onPrimary,
                        color: Theme.of(context).colorScheme.surfaceDim,
                        child: TextButton(
                          style: ElevatedButton.styleFrom(
                            shadowColor: Theme.of(context).colorScheme.onPrimary,
                            backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => ElectricmeterbindPage()));},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SizedBox(height: 10,),
                              Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/electricitybind.png'):AssetImage('assets/icons/darktheme/electricitybind.png'),height: 50,),
                              SizedBox(height: 5,),
                              Expanded(child: Text('解/绑电费账号',style: TextStyle(fontSize: GlobalVars.genericFunctionsButtonTitle),overflow: TextOverflow.ellipsis,),)
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 5,),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 125,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        shadowColor: Theme.of(context).colorScheme.onPrimary,
                        color: Theme.of(context).colorScheme.surfaceDim,
                        child: TextButton(
                          style: ElevatedButton.styleFrom(
                            shadowColor: Theme.of(context).colorScheme.onPrimary,
                            backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => SettingsPage()));},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SizedBox(height: 10,),
                              Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/settings.png'):AssetImage('assets/icons/darktheme/settings.png'),height: 50,),
                              SizedBox(height: 5,),
                              Expanded(child: Text('应用设置',style: TextStyle(fontSize: GlobalVars.genericFunctionsButtonTitle),overflow: TextOverflow.ellipsis,),)
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5,),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 125,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        shadowColor: Theme.of(context).colorScheme.onPrimary,
                        color: Theme.of(context).colorScheme.surfaceDim,
                        child: TextButton(
                          style: ElevatedButton.styleFrom(
                            shadowColor: Theme.of(context).colorScheme.onPrimary,
                            backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => Guidepage()));},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SizedBox(height: 10,),
                              Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/guide.png'):AssetImage('assets/icons/darktheme/guide.png'),height: 50,),
                              SizedBox(height: 5,),
                              Expanded(child: Text('教程&说明',style: TextStyle(fontSize: GlobalVars.genericFunctionsButtonTitle),overflow: TextOverflow.ellipsis,),)
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 5,),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 125,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        shadowColor: Theme.of(context).colorScheme.onPrimary,
                        color: Theme.of(context).colorScheme.surfaceDim,
                        child: TextButton(
                          style: ElevatedButton.styleFrom(
                            shadowColor: Theme.of(context).colorScheme.onPrimary,
                            backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: (){
                            showDialog<String>(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: Text('询问：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
                              content: Text('您确定要退出登录吗？\n退出登录同时会解绑电费账号、清除字体大小、颜色模式等设置',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SizedBox(height: 10,),
                              Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/exit.png'):AssetImage('assets/icons/darktheme/exit.png'),height: 50,),
                              SizedBox(height: 5,),
                              Expanded(child: Text('退出登录',style: TextStyle(fontSize: GlobalVars.genericFunctionsButtonTitle),overflow: TextOverflow.ellipsis,),)
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 5,indent: 20,endIndent: 20,color: Theme.of(context).colorScheme.primary,),
        Container(
          padding: EdgeInsets.all(10),
          child: Text('智慧陕理工',style: TextStyle(fontSize: 12,color: Colors.grey,fontWeight: FontWeight.w100),textAlign: TextAlign.center,),
        ),
      ],
    );
  }

  //退出登录
  logout() async {
    
    //清空并重新创建数据目录
    Directory smartSNUTdirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT');
    if(await smartSNUTdirectory.exists() == true){
      await smartSNUTdirectory.delete(recursive: true);
      await smartSNUTdirectory.create();
    }

    if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('退出登录成功'),
        ),
      );
    }

    if(mounted){
      setState(() {
        isloggedin = false;  
      });
    }
    if(mounted){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext ctx) => LoginPage()));
    }
  }
}