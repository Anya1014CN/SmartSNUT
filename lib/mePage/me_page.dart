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
        // 问候语区域
        Container(
          padding: EdgeInsets.fromLTRB(16, 40, 16, 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withAlpha(179),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${GlobalVars.realName}，',style: TextStyle(fontSize: GlobalVars.genericGreetingTitle, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.primary),),
              Text('这是你在陕理工的',style: TextStyle(fontSize: GlobalVars.genericGreetingTitle, fontWeight: FontWeight.w300),),
              Wrap(
                spacing: 0,
                children: [
                  Text('第 ',style: TextStyle(fontSize: GlobalVars.genericGreetingTitle, fontWeight: FontWeight.w300),),
                  Text('${GlobalVars.today.difference(DateTime.parse(GlobalVars.enrollTime)).inDays}',style: TextStyle(fontSize: GlobalVars.genericGreetingTitle + 5, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),),
                  Text(' 天。',style: TextStyle(fontSize: GlobalVars.genericGreetingTitle, fontWeight: FontWeight.w300),),
                ],
              ),
              Text('距离毕业还',style: TextStyle(fontSize: GlobalVars.genericGreetingTitle, fontWeight: FontWeight.w300),),
              Wrap(
                spacing: 0,
                children: [
                  Text('有 ',style: TextStyle(fontSize: GlobalVars.genericGreetingTitle, fontWeight: FontWeight.w300),),
                  Text('${DateTime.parse(GlobalVars.graduationTime).difference(GlobalVars.today).inDays}',style: TextStyle(fontSize: GlobalVars.genericGreetingTitle + 5, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error),),
                  Text(' 天。',style: TextStyle(fontSize: GlobalVars.genericGreetingTitle, fontWeight: FontWeight.w300),),
                ],
              ),
            ],
          )
        ),
        
        SizedBox(height: 10),
        
        // 每日提示标题
        Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                width: 4,
                height: 18,
                margin: EdgeInsets.only(right: 8),
              ),
              Text(
                '每日提示',
                style: TextStyle(
                  fontSize: GlobalVars.dividerTitle,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary
                ),
              ),
            ],
          ),
        ),
        
        // 每日提示卡片
        Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
            color: Theme.of(context).colorScheme.surfaceDim,
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image(
                    image: Theme.of(context).brightness == Brightness.light
                      ? AssetImage('assets/icons/lighttheme/bulb.png')
                      : AssetImage('assets/icons/darktheme/bulb.png'),
                    height: 40,
                  ),
                  SizedBox(height: 16),
                  Text(
                    GlobalVars.hint,
                    style: TextStyle(
                      fontSize: GlobalVars.genericTextMedium,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )
                ],
              ),
            ),
          ),
        ),
        
        // 功能区标题
        Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                width: 4,
                height: 18,
                margin: EdgeInsets.only(right: 8),
              ),
              Text(
                '其他功能',
                style: TextStyle(
                  fontSize: GlobalVars.dividerTitle,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary
                ),
              ),
            ],
          ),
        ),
        
        // 功能区卡片
        Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
            color: Theme.of(context).colorScheme.surfaceDim,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '解/绑电费账号',
                          'electricitybind',
                          () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (BuildContext ctx) => ElectricmeterbindPage()
                            ));
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '应用设置',
                          'settings',
                          () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (BuildContext ctx) => SettingsPage()
                            ));
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '教程&说明',
                          'guide',
                          () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (BuildContext ctx) => Guidepage()
                            ));
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '退出登录',
                          'exit',
                          () {
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
                                    child: const Text('取消'),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context).colorScheme.error,
                                    ),
                                    onPressed: (){
                                      logout();
                                      Navigator.pop(context);
                                    },
                                    child: const Text('确定退出'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // 底部版权信息
        Container(
          padding: EdgeInsets.fromLTRB(0, 16, 0, 20),
          child: Text(
            '智慧陕理工',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w300
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // 功能按钮构建辅助方法
  Widget buildFunctionButton(BuildContext context, String title, String iconName, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: Theme.of(context).brightness == Brightness.light
                ? AssetImage('assets/icons/lighttheme/$iconName.png')
                : AssetImage('assets/icons/darktheme/$iconName.png'),
              height: 40,
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: GlobalVars.genericFunctionsButtonTitle,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
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
      setState(() {
        isloggedin = false;  
      });
    }
    if(mounted){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext ctx) => LoginPage()));
    }
  }
}