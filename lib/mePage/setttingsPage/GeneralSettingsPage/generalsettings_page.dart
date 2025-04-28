import 'package:flutter/material.dart';
import 'package:smartsnut/function_modules.dart';
import 'package:smartsnut/globalvars.dart';

class GeneralSettingsPage extends StatefulWidget{
  const GeneralSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GeneralSettingsPageState();
  }
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage>{
  bool _showAppBarTitle = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
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
                title: _showAppBarTitle ? Text("通用设置") : null,
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
                  Text('通用设置',style: TextStyle(fontSize: GlobalVars.genericPageTitle),)
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
                      onChanged: (value) async {
                        groupValue = 0;
                        if(mounted){
                          setState((){
                            GlobalVars.fontsizeint = 0;
                            Modules.setFontSize();
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
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
                      onChanged: (value) async {
                        groupValue = 1;
                        if(mounted){
                          setState((){
                            GlobalVars.fontsizeint = 1;
                            Modules.setFontSize();
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
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
                      onChanged: (value) async {
                        groupValue = 2;
                        if(mounted){
                          setState((){
                            GlobalVars.fontsizeint = 2;
                            Modules.setFontSize();
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
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
                      onChanged: (value) async {
                        groupValue = 3;
                        if(mounted){
                          setState((){
                            GlobalVars.fontsizeint = 3;
                            Modules.setFontSize();
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
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
                      onChanged: (value) async {
                        groupValue = 4;
                        if(mounted){
                          setState((){
                            GlobalVars.fontsizeint = 4;
                            Modules.setFontSize();
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
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
                      onChanged: (value) async {
                        groupValue = 5;
                        if(mounted){
                          setState((){
                            GlobalVars.fontsizeint = 5;
                            Modules.setFontSize();
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
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
                      onChanged: (value) async {
                        groupValue = 6;
                        if(mounted){
                          setState((){
                            GlobalVars.fontsizeint = 6;
                            Modules.setFontSize();
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
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
                onPressed: () async {
                  Navigator.pop(context);
                  await Modules.saveSettings();
                  setState(() {});
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
                      onChanged: (value) async {
                        groupValue = 0;
                        if(mounted){
                          setState((){
                            GlobalVars.themeColor = 0;
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
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
                      onChanged: (value) async {
                        groupValue = 1;
                        if(mounted){
                          setState((){
                            GlobalVars.themeColor = 1;
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
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
                      onChanged: (value) async {
                        groupValue = 2;
                        if(mounted){
                          setState((){
                            GlobalVars.themeColor = 2;
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
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
                      onChanged: (value) async {
                        groupValue = 3;
                        if(mounted){
                          setState((){
                            GlobalVars.themeColor = 3;
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
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
                      onChanged: (value) async {
                        groupValue = 4;
                        if(mounted){
                          setState((){
                            GlobalVars.themeColor = 4;
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
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
                      onChanged: (value) async {
                        groupValue = 5;
                        if(mounted){
                          setState((){
                            GlobalVars.themeColor = 5;
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
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
                      onChanged: (value) async {
                        groupValue = 6;
                        if(mounted){
                          setState((){
                            GlobalVars.themeColor = 6;
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
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
                      onChanged: (value) async{
                        groupValue = 7;
                        if(mounted){
                          setState((){
                            GlobalVars.themeColor = 7;
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
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
                onPressed: () async {
                  Navigator.pop(context);
                  await Modules.saveSettings();
                  setState(() {});
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
                      onChanged: (value) async {
                        groupValue = 0;
                        if(mounted){
                          setState((){
                            GlobalVars.darkModeint = 0;
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
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
                      onChanged: (value) async {
                        groupValue = 1;
                        if(mounted){
                          setState((){
                            GlobalVars.darkModeint = 1;
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
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
                      onChanged: (value) async {
                        groupValue = 2;
                        if(mounted){
                          setState((){
                            GlobalVars.darkModeint = 2;
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
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
                onPressed: () async {
                  Navigator.pop(context);
                  await Modules.saveSettings();
                  setState(() {});
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

}