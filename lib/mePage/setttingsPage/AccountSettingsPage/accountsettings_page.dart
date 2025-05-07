import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartsnut/function_modules.dart';
import 'package:smartsnut/login.dart';
import 'package:smartsnut/mePage/electricMeterBindPage/electricmeterbind_page.dart';
import 'package:smartsnut/globalvars.dart';

class AccountSettingsPage extends StatefulWidget{
  const AccountSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AccountSettingsPageState();
  }
}

class _AccountSettingsPageState extends State<AccountSettingsPage>{
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

  @override
  void dispose() {
    super.dispose();
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
                title: _showAppBarTitle ? Text("账号设置") : null,
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
                  Text('账号设置',style: TextStyle(fontSize: GlobalVars.genericPageTitle),)
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
                          Navigator.push(context, CustomPageRoute(page: ElectricmeterbindPage())).then((value) => emBindRead());
                        },
                      ),
                      Divider(height: 1, indent: 20, endIndent: 20),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.primary),
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
            ],
          ),
        ),
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
}