import 'package:flutter/material.dart';
import 'package:smartsnut/AppPage/electricMeter/electricmeter_page.dart';
import 'package:smartsnut/AppPage/stdGrades/stdgrades_page.dart';
import 'package:smartsnut/AppPage/schoolNetwork/schoolnetwork_page.dart';
import 'package:smartsnut/AppPage/stdDetail/stddetail_page.dart';
import 'package:smartsnut/AppPage/stdExam/stdexam_page.dart';
import 'package:smartsnut/globalvars.dart';
import 'courseTable/coursetable_page.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

//用于存储外部链接的完整URL
Uri url = Uri.parse("uri");

bool loginstate = false;

//获取当前日期
int month = DateTime.now().month;
int day = DateTime.now().day;
int hour = DateTime.now().hour;

//用于存储不同时间段的问候语
String greeting = '';

class AppPage extends StatefulWidget{
  const AppPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AppPageState();
  }
}

class _AppPageState extends State<AppPage>{

  @override
  void initState() {
    super.initState();
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    if(hour >= 0 && hour <= 5){
      greeting = '晚上好';
    }if(hour >= 6 && hour <= 11){
      greeting = '早上好';
    }if(hour >= 12 && hour <= 13){
      greeting = '中午好';
    }if(hour >= 14 && hour <= 18){
      greeting = '下午好';
    }if(hour >= 19 && hour <= 23){
      greeting = '晚上好';
    }
    return ListView(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(10, 50, 0, 30),
          child: Text('$greeting，${GlobalVars.realName}',style: TextStyle(fontWeight: FontWeight.w300,fontSize: GlobalVars.genericGreetingTitle),),
        ),
        Container(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('教务功能',style: TextStyle(fontSize: GlobalVars.dividerTitle,color: Theme.of(context).colorScheme.primary),),
              Divider(height: 5,indent: 20,endIndent: 20,color: Theme.of(context).colorScheme.primary,),
            ],
          ),
        ),
        FittedBox(
          fit: BoxFit.cover,
          child: Container(
            padding: EdgeInsets.fromLTRB(10, 5, 10, 10),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                  child: Row(
                    children: [
                      Container(
                        width: (MediaQuery.of(context).size.width)/2 - 25,
                        padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                        height: 100,
                        child: ElevatedButton(
                          onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => CourseTablePage()));},
                          style: ElevatedButton.styleFrom(
                            shadowColor: Theme.of(context).colorScheme.onPrimary,
                            backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(21),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/schedule.png'):AssetImage('assets/icons/darktheme/schedule.png'),height: 36,),
                              SizedBox(width: 10,),
                              Expanded(child: Text('我的课表',style: TextStyle(fontSize: GlobalVars.genericFunctionsButtonTitle),overflow: TextOverflow.ellipsis,maxLines: 2,textAlign: TextAlign.center,))
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 5), // 按钮之间的间距
                      Container(
                        width: (MediaQuery.of(context).size.width)/2 - 25,
                        padding: EdgeInsets.fromLTRB(5, 0, 10, 0),
                        height: 100,
                        child: ElevatedButton(
                          onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => StdDetailPage()));},
                          style: ElevatedButton.styleFrom(
                            shadowColor: Theme.of(context).colorScheme.onPrimary,
                            backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(21),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/account.png'):AssetImage('assets/icons/darktheme/account.png'),height: 36,),
                              SizedBox(width: 10,),
                              Expanded(child: Text('学籍信息',style: TextStyle(fontSize: GlobalVars.genericFunctionsButtonTitle),overflow: TextOverflow.ellipsis,maxLines: 2,textAlign: TextAlign.center,))
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(0, 5, 0, 10),
                  child: Row(
                      children: [
                        Container(
                          width: (MediaQuery.of(context).size.width)/2 - 25,
                          padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                          height: 100,
                          child: ElevatedButton(
                            onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => StdExamPage()));},
                            style: ElevatedButton.styleFrom(
                              shadowColor: Theme.of(context).colorScheme.onPrimary,
                              backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(21),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/exam.png'):AssetImage('assets/icons/darktheme/exam.png'),height: 36,),
                                SizedBox(width: 10,),
                                Expanded(child: Text('我的考试',style: TextStyle(fontSize: GlobalVars.genericFunctionsButtonTitle),overflow: TextOverflow.ellipsis,maxLines: 2,textAlign: TextAlign.center,))
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 5), // 按钮之间的间距
                        Container(
                          width: (MediaQuery.of(context).size.width)/2 - 25,
                          padding: EdgeInsets.fromLTRB(5, 0, 10, 0),
                          height: 100,
                          child: ElevatedButton(
                            onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => StdGradesPage()));},
                            style: ElevatedButton.styleFrom(
                              shadowColor: Theme.of(context).colorScheme.onPrimary,
                              backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(21),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/grade.png'):AssetImage('assets/icons/darktheme/grade.png'),height: 36,),
                                SizedBox(width: 10,),
                                Expanded(child: Text('我的成绩',style: TextStyle(fontSize: GlobalVars.genericFunctionsButtonTitle),overflow: TextOverflow.ellipsis,maxLines: 2,textAlign: TextAlign.center,))
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('后勤功能',style: TextStyle(fontSize: GlobalVars.dividerTitle,color: Theme.of(context).colorScheme.primary),),
              Divider(height: 5,indent: 20,endIndent: 20,color: Theme.of(context).colorScheme.primary,),
            ],
          ),
        ),
        FittedBox(
          fit: BoxFit.cover,
          child: Container(
            padding: EdgeInsets.fromLTRB(10, 5, 10, 10),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                  child: Row(
                    children: [
                      Container(
                        width: (MediaQuery.of(context).size.width)/2 - 25,
                        padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                        height: 100,
                        child: ElevatedButton(
                          onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => SchoolNetworkPage()));},
                          style: ElevatedButton.styleFrom(
                            shadowColor: Theme.of(context).colorScheme.onPrimary,
                            backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(21),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/web.png'):AssetImage('assets/icons/darktheme/web.png'),height: 36,),
                              SizedBox(width: 10,),
                              Expanded(child: Text('网费查询',style: TextStyle(fontSize: GlobalVars.genericFunctionsButtonTitle),overflow: TextOverflow.ellipsis,maxLines: 2,textAlign: TextAlign.center,))
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 5), // 按钮之间的间距
                      Container(
                        width: (MediaQuery.of(context).size.width)/2 - 25,
                        padding: EdgeInsets.fromLTRB(5, 0, 10, 0),
                        height: 100,
                        child: ElevatedButton(
                          onPressed: (){
                              if(GlobalVars.emBinded == false){
                                  showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) => AlertDialog(
                                    title: Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
                                    content: Text('您还没有绑定电费账号，\n请先前往 “我的 -> 解/绑电费账号” 绑定后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, 'OK'),
                                        child: const Text('确定'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }else{
                                Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => Electricmeterpage()));
                              }
                            },
                          style: ElevatedButton.styleFrom(
                            shadowColor: Theme.of(context).colorScheme.onPrimary,
                            backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(21),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/electricity.png'):AssetImage('assets/icons/darktheme/electricity.png'),height: 36,),
                              SizedBox(width: 10,),
                              Expanded(child: Text('电费查询',style: TextStyle(fontSize: GlobalVars.genericFunctionsButtonTitle),overflow: TextOverflow.ellipsis,maxLines: 2,textAlign: TextAlign.center,))
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('校内链接',style: TextStyle(fontSize: GlobalVars.dividerTitle,color: Theme.of(context).colorScheme.primary),),
              Divider(height: 5,indent: 20,endIndent: 20,color: Theme.of(context).colorScheme.primary,),
            ],
          ),
        ),
        FittedBox(
          fit: BoxFit.cover,
          child: Container(
            padding: EdgeInsets.fromLTRB(10, 5, 10, 10),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                  child: Row(
                    children: [
                      Container(
                        width: (MediaQuery.of(context).size.width)/2 - 25,
                        padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                        height: 100,
                        child: ElevatedButton(
                          onPressed: (){
                            url = Uri.parse('https://findsnut.libsp.com/');
                            launchURL();
                          },
                          style: ElevatedButton.styleFrom(
                            shadowColor: Theme.of(context).colorScheme.onPrimary,
                            backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(21),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/library.png'):AssetImage('assets/icons/darktheme/library.png'),height: 36,),
                              SizedBox(width: 10,),
                              Expanded(child: Text('图书检索',style: TextStyle(fontSize: GlobalVars.genericFunctionsButtonTitle),overflow: TextOverflow.ellipsis,maxLines: 2,textAlign: TextAlign.center,))
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 5), // 按钮之间的间距
                      Container(
                        width: (MediaQuery.of(context).size.width)/2 - 25,
                        padding: EdgeInsets.fromLTRB(5, 0, 10, 0),
                        height: 100,
                        child: ElevatedButton(
                          onPressed: (){
                            url = Uri.parse('https://faceid.snut.edu.cn/cflms-opencas/cas/v1/collection/');
                            launchURL();
                          },
                          style: ElevatedButton.styleFrom(
                            shadowColor: Theme.of(context).colorScheme.onPrimary,
                            backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(21),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/face.png'):AssetImage('assets/icons/darktheme/face.png'),height: 36,),
                              SizedBox(width: 10,),
                              Expanded(child: Text('人脸信息采集系统',style: TextStyle(fontSize: GlobalVars.genericFunctionsButtonTitle),overflow: TextOverflow.ellipsis,maxLines: 2,textAlign: TextAlign.center,))
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(0, 5, 0, 10),
                  child: Row(
                      children: [
                        Container(
                          width: (MediaQuery.of(context).size.width)/2 - 25,
                          padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                          height: 100,
                          child: ElevatedButton(
                            onPressed: (){
                              url = Uri.parse('https://sec.snut.edu.cn/');
                              launchURL();
                            },
                            style: ElevatedButton.styleFrom(
                              shadowColor: Theme.of(context).colorScheme.onPrimary,
                              backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(21),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/vpn.png'):AssetImage('assets/icons/darktheme/vpn.png'),height: 36,),
                                SizedBox(width: 10,),
                                Expanded(child: Text('WebVPN',style: TextStyle(fontSize: GlobalVars.genericFunctionsButtonTitle),overflow: TextOverflow.ellipsis,maxLines: 2,textAlign: TextAlign.center,))
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 5), // 按钮之间的间距
                        Container(
                          width: (MediaQuery.of(context).size.width)/2 - 25,
                          padding: EdgeInsets.fromLTRB(5, 0, 10, 0),
                          height: 100,
                          child: ElevatedButton(
                            onPressed: (){
                              url = Uri.parse('https://newehall.snut.edu.cn/');
                              launchURL();
                            },
                            style: ElevatedButton.styleFrom(
                              shadowColor: Theme.of(context).colorScheme.onPrimary,
                              backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(21),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/museum.png'):AssetImage('assets/icons/darktheme/museum.png'),height: 36,),
                                SizedBox(width: 10,),
                                Expanded(child: Text('一网通办',style: TextStyle(fontSize: GlobalVars.genericFunctionsButtonTitle),overflow: TextOverflow.ellipsis,maxLines: 2,textAlign: TextAlign.center,))
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  loginstatecheck() async {
    String loginstatepath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/loginstate.txt';
    File loginstatefile = File(loginstatepath);
    if(await loginstatefile.exists() == true){
      if(mounted){
        setState(() {
          loginstate = true;
        });
      }
    }if(await loginstatefile.exists() == false){
      if(mounted){
        setState(() {
          loginstate = false;
        });
      }
    }
  }

  //打开链接
  void launchURL() async{
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
        title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
        content: Text('是否要使用系统默认浏览器打开外部链接？\n\n$url',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await launchUrl(url);
              if(context.mounted){
                Navigator.pop(context, 'OK');
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}