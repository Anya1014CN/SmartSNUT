import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:url_launcher/url_launcher.dart';

//功能说明
String describeTitle = '';
String describePath = '';
String describeContent = '';

//用于即将打开的链接的完整URL
Uri url = Uri.parse("uri");

class Guidepage extends StatefulWidget{
  const Guidepage({super.key});
  
  @override
  State<StatefulWidget> createState() {
    return _GuidePageState();
  }
}

class _GuidePageState extends State<Guidepage>{
  bool _showAppBarTitle = false;

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
                title: _showAppBarTitle ? Text("教程&说明") : null,
              ),
            ];
          },
          body: ListView(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 30),
                child: Row(
                  children: [
                    Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/guide.png'):AssetImage('assets/icons/darktheme/guide.png'),height: 40,),
                    SizedBox(width: 10,),
                    Text('教程&说明',style: TextStyle(fontSize: 40),)
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('使用说明',style: TextStyle(fontSize: GlobalVars.dividerTitle,color:Theme.of(context).colorScheme.primary),),
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
                          title: Text('电费账号绑定教程',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            url = Uri.parse('https://smartsnut.cn/Docs/UserManual/EMBindGuide.html');
                            launchURL();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('功能说明',style: TextStyle(fontSize: GlobalVars.dividerTitle,color:Theme.of(context).colorScheme.primary),),
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
                          title: Text('我的课表',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            url = Uri.parse('https://smartsnut.cn/Docs/UserManual/Functions/JiaoWu/CourseTableForStd.html');
                            launchURL();
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('学籍信息',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            url = Uri.parse('https://smartsnut.cn/Docs/UserManual/Functions/JiaoWu/StdDetail.html');
                            launchURL();
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('我的考试',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            url = Uri.parse('https://smartsnut.cn/Docs/UserManual/Functions/JiaoWu/StdExam.html');
                            launchURL();
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('我的成绩',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            url = Uri.parse('https://smartsnut.cn/Docs/UserManual/Functions/JiaoWu/StdExam.html');
                            launchURL();
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('绩点计算器',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            url = Uri.parse('https://smartsnut.cn/Docs/UserManual/Functions/JiaoWu/GPACalculator.html');
                            launchURL();
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('网费查询',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            url = Uri.parse('https://smartsnut.cn/Docs/UserManual/Functions/HouQin/SchoolNetworkQuery.html');
                            launchURL();
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('电费查询',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            url = Uri.parse('https://smartsnut.cn/Docs/UserManual/Functions/HouQin/ElectricMeterQuery.html');
                            launchURL();
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('图书检索',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            url = Uri.parse('http://smartsnut.cn/Docs/UserManual/Functions/ExternalLink/Library.html');
                            launchURL();
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('人脸信息采集系统',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            url = Uri.parse('http://smartsnut.cn/Docs/UserManual/Functions/ExternalLink/Face.html');
                            launchURL();
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('WebVPN',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            url = Uri.parse('http://smartsnut.cn/Docs/UserManual/Functions/ExternalLink/WebVPN.html');
                            launchURL();
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('一网通办',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            url = Uri.parse('http://smartsnut.cn/Docs/UserManual/Functions/ExternalLink/NewHall.html');
                            launchURL();
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
  
  //打开链接
  void launchURL() async{
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
        title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
        content: Text('是否要使用系统默认浏览器打开外部链接？\n\n$url',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await launchUrl(url);
              Navigator.pop(context, 'OK');
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}