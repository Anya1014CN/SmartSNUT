import 'package:flutter/material.dart';
import 'package:smartsnut/function_modules.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';

class CourseTableSettingsPage extends StatefulWidget{
  const CourseTableSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CourseTableSettingsPageState();
  }
}

class _CourseTableSettingsPageState extends State<CourseTableSettingsPage>{
  bool _showAppBarTitle = false;

  @override
  void dispose() {
    super.dispose();
    if (GlobalVars.isPrivacyAgreed && GlobalVars.isAnalyticsEnabled) {
      UmengCommonSdk.onPageEnd("我的 - 应用设置 - 课表设置");
    }
  }

  @override
  void initState() {
    super.initState();
    if (GlobalVars.isPrivacyAgreed && GlobalVars.isAnalyticsEnabled) {
      UmengCommonSdk.onPageStart("我的 - 应用设置 - 课表设置");
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
                title: _showAppBarTitle ? Text("课表设置") : null,
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
                  Text('课表设置',style: TextStyle(fontSize: GlobalVars.genericPageTitle),)
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
                        leading: Icon(Icons.refresh_outlined, color: Theme.of(context).colorScheme.primary),
                        trailing: Switch(
                          value: GlobalVars.autoRefreshCourseTable,
                          onChanged: (value) async {
                            GlobalVars.autoRefreshCourseTable = value;
                            await Modules.saveSettings();
                            setState(() {});
                          },
                        ),
                        title: Text('自动更新课表',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                        subtitle: Text('当课表数据 >= 24 小时未刷新时，自动从教务系统获取最新的课表数据',style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.calendar_view_week, color: Theme.of(context).colorScheme.primary),
                        trailing: Switch(
                          value: GlobalVars.switchNextWeekCourseAfter20,
                          onChanged: (value) async {
                            GlobalVars.switchNextWeekCourseAfter20 = value;
                            await Modules.saveSettings();
                            setState(() {});
                          },
                        ),
                        title: Text('自动切换下周课表',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                        subtitle: Text('在每周日的晚上 20:00 之后，自动切换 “我的课表” 页面的课表到下周课表',style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.calendar_view_week, color: Theme.of(context).colorScheme.primary),
                        trailing: Switch(
                          value: GlobalVars.showSatCourse,
                          onChanged: (value) async {
                            GlobalVars.showSatCourse = value;
                            await Modules.saveSettings();
                            setState(() {});
                          },
                        ),
                        title: Text('显示周六课程',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                        subtitle: Text('在 "我的课表" 中显示周六的课程',style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.calendar_view_week, color: Theme.of(context).colorScheme.primary),
                        trailing: Switch(
                          value: GlobalVars.showSunCourse,
                          onChanged: (value) async {
                            GlobalVars.showSunCourse = value;
                            await Modules.saveSettings();
                            setState(() {});
                          },
                        ),
                        title: Text('显示周日课程',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                        subtitle: Text('在 "我的课表" 中显示周日的课程',style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                      ),
                      Divider(height: 5,indent: 20,endIndent: 20,),
                      ListTile(
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                        ),
                        leading: Icon(Icons.color_lens, color: Theme.of(context).colorScheme.primary),
                        trailing: Icon(Icons.chevron_right),
                        title: Text('课程色系',style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                        subtitle: Text((GlobalVars.courseBlockColorsInt == 0)? '莫兰迪色系':'马卡龙色系',
                          style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.primary,fontSize: GlobalVars.listTileSubtitle),),
                        onTap: (){switchCourseBlockColor();},
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

  //切换课程色系
  switchCourseBlockColor() {
    int groupValue = GlobalVars.courseBlockColorsInt;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('课程色系',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
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
                            GlobalVars.courseBlockColorsInt = 0;
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('莫兰迪色系',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
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
                            GlobalVars.courseBlockColorsInt = 1;
                          });
                        }
                        await Modules.saveSettings();
                        setState(() {});
                      },
                    ),
                    SizedBox(width: 10,),
                    Text('马卡龙色系',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
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