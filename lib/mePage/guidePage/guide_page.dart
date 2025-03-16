import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:smartsnut/mePage/guidePage/emBindGuidePage/embindguide_page.dart';

//功能说明
String describeTitle = '';
String describePath = '';
String describeContent = '';

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
                    Text('使用说明',style: TextStyle(fontSize: GlobalVars.generalsettings_divider_title,color:Theme.of(context).colorScheme.primary),),
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
                          title: Text('电费账号绑定教程',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => EMBindGuidePage()));},
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
                    Text('功能说明',style: TextStyle(fontSize: GlobalVars.generalsettings_divider_title,color:Theme.of(context).colorScheme.primary),),
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
                          title: Text('我的课表',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            describeTitle = '我的课表';
                            describePath = 'CourseTable';
                            showDescribe(context);
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('学籍信息',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            describeTitle = '学籍信息';
                            describePath = 'StdDetail';
                            showDescribe(context);
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('我的考试',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            describeTitle = '我的考试';
                            describePath = 'StdExam';
                            showDescribe(context);
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('我的成绩',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            describeTitle = '我的成绩';
                            describePath = 'StdGrades';
                            showDescribe(context);
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('网费查询',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            describeTitle = '网费查询';
                            describePath = 'SchoolNetwork';
                            showDescribe(context);
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('电费查询',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            describeTitle = '电费查询';
                            describePath = 'ElectricityMeterQuery';
                            showDescribe(context);
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('图书检索',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            describeTitle = '图书检索';
                            describePath = 'Library';
                            showDescribe(context);
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('人脸信息采集系统',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            describeTitle = '人脸信息采集系统';
                            describePath = 'Face';
                            showDescribe(context);
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('WebVPN',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            describeTitle = 'WebVPN';
                            describePath = 'WebVPN';
                            showDescribe(context);
                          },
                        ),
                        Divider(height: 5,indent: 20,endIndent: 20,),
                        ListTile(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                          ),
                          title: Text('一网通办',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                          trailing: Icon(Icons.chevron_right),
                          onTap: (){
                            describeTitle = '一网通办';
                            describePath = 'Newhall';
                            showDescribe(context);
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

  void showDescribe(BuildContext context) async{
    describeContent = await rootBundle.loadString('assets/description/$describePath.txt');
    showDialog<String>(
      context: context,
      builder:(BuildContext context) => AlertDialog(
        title: Text('$describeTitle - 功能说明',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
        content: Text(describeContent,style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
        scrollable: true,
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'OK'),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}