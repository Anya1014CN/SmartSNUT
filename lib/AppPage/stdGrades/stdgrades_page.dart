import 'dart:convert';
import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:smartsnut/globalvars.dart';


//保存查询状态
bool isQuerying = false;

//判断是否需要联网下载成绩
bool needRefresh = false;

//用户数据
List stdAccount = [];
String userName = '';
String passWord = '';

//学期数据
Map semestersData = {};
int semesterTotal = 0;//学年的数量
List semestersName = [];

//菜单 Controller
final menuYearController = MenuController();
final menuTermController = MenuController();

//当前成绩学年
int currentYearInt = 1;
String currentYearName = '';

//当前成绩学期
int currentTermInt = 1;
String currentTermName = '';

//当前学期成绩信息
List stdGradesTotal = [];
bool noGrades = false;//用于判断该学期是否有成绩

class StdGradesPage extends StatefulWidget{
  const StdGradesPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _StdGradesPageState();
  }
}

class _StdGradesPageState extends State<StatefulWidget>{
  bool _showAppBarTitle = false;

  //读取用户信息并保存在变量中
  readStdAccount() async {
    String stdAccountpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdAccount.json';
    File stdAccountfile = File(stdAccountpath);
    stdAccount = jsonDecode(await stdAccountfile.readAsString());
    if(mounted){
      setState(() {
        userName = stdAccount[0]['UserName'];
        passWord = stdAccount[0]['PassWord'];
      });
    }
  }

  //读取学期相关信息
  readSemesterInfo() async {
    //清空学期列表
    semestersData = {};
    semestersName = [];
    String semesterspath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/semesters.json';
    File semestersfile = File(semesterspath);
    semestersData = jsonDecode(await semestersfile.readAsString());
    semesterTotal = semestersData.length;
    for(int i = 0; i < semesterTotal; i++){
      semestersName.add({
        'name': semestersData['y$i'][0]['schoolYear']
      });
    }
    readSelectState();
  }
   
  //读取学期的选中状态
  readSelectState() async {

    //每次读取之前进行成绩目录检查，防止后续版本升级，目录未被创建导致崩溃
    Directory stdGradesdirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdGrades');
    if(await stdGradesdirectory.exists() == false){
      await stdGradesdirectory.create();
    }

    String selectedTYpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdGrades/selectedTY.json';
    File selectedTYfile = File(selectedTYpath);
    if(await selectedTYfile.exists()){
      var selectedTYjson = jsonDecode(await selectedTYfile.readAsString());
      if(mounted){
        setState(() {
          currentYearInt = selectedTYjson[0]['selectedYear'];
          currentYearName = semestersName[currentYearInt]['name'];
          currentTermInt = selectedTYjson[1]['selectedTerm'];
          if(currentTermInt == 1){
            currentTermName = '第一学期';
          }if(currentTermInt == 2){
            currentTermName = '第二学期';
          }
        });
      }
    }else{
      if(mounted){
        setState(() {
          needRefresh = true;
          currentYearInt = semestersData.length - 1;
          currentYearName = semestersName[semestersName.length - 1]['name'];
          //获取当前月份
          int month = DateTime.now().month;
          if(month < 9){
            //如果月份小于9，则选择第二学期
            currentTermInt = 2;
            currentTermName = '第二学期';
          }else{
            //如果月份大于等于9，则选择第一学期
            currentTermInt = 1;
            currentTermName = '第一学期';
          }
        });
      }
      saveSelectedTY();
    }
    if(needRefresh){
      getStdGrades();
    }else{
      readstdGrades();
    }
  }

  //读取成绩信息
  readstdGrades() async  {
    //使用本地选中的 semetserid 来读取对应的成绩
    String semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();

    String stdGradespath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdGrades/stdGrades$semesterId.json';
    File stdGradesfile = File(stdGradespath);
    if(await stdGradesfile.exists()){
      var readGradesTotal = jsonDecode(await stdGradesfile.readAsString());
      if(readGradesTotal.isEmpty){
        if(mounted){
          setState(() {
            noGrades = true;
          });
        }
      }else{
        if(mounted){
          setState(() {
            stdGradesTotal = readGradesTotal;
            noGrades = false;
          });
        }
      }
    }else{
      if(mounted){
        setState(() {
          noGrades = true;
        });
      }
    }
  }
  
  ///保存选中的考试学期状态
  saveSelectedTY() async {
    String selectedTYpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdGrades/selectedTY.json';
    File selectedTYfile = File(selectedTYpath);
    List selectedTY = [];
    selectedTY.remove('selectedYear');
    selectedTY.remove('selectedTerm');
    selectedTY.add({
      'selectedYear': currentYearInt,
    });
    selectedTY.add({
      'selectedTerm': currentTermInt,
    });
    selectedTYfile.writeAsString(jsonEncode(selectedTY));
  }
  
  //切换考试学期
  switchTerm() async {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('切换成绩时间',style: TextStyle(fontSize: GlobalVars.stdgradeswitchterm_title_title),),
            content: Column(
              children: [
                MenuAnchor(
                  controller: menuYearController,
                  menuChildren: semestersName.map((item) {
                    return MenuItemButton(
                      onPressed: () async {
                        int yearSelectedIndex = semestersName.indexOf(item);
                        if(mounted){
                          setState(() {
                            currentYearInt = yearSelectedIndex;
                            currentYearName = item['name'];
                          });
                        }
                        saveSelectedTY();
                        readSemesterInfo();
                        menuYearController.close();
                      },
                      child: Text('${item['name']} 学年',style: TextStyle(fontSize: GlobalVars.stdgradeswitchterm_year_title),),
                    );
                  }).toList(),
                  child: SizedBox(
                    height: 50,
                    child: TextButton(
                      style: ElevatedButton.styleFrom(
                        shadowColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        if (menuYearController.isOpen) {
                          menuYearController.close();
                        } else {
                          menuYearController.open();
                        }
                      },
                      child: Text('学年：$currentYearName', style: TextStyle(fontSize: GlobalVars.stdgradeswitchterm_year_title),softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
                Divider(height: 5, indent: 20, endIndent: 20),
                MenuAnchor(
                  controller: menuTermController,
                  menuChildren: [
                    MenuItemButton(
                      child: Text('第一学期',style: TextStyle(fontSize: GlobalVars.stdgradeswitchterm_term_title),),
                      onPressed: () async {
                        if(mounted){
                          setState(() {
                            currentTermInt = 1;
                            currentTermName = '第一学期';
                          });
                        }
                        saveSelectedTY();
                        readSemesterInfo();
                        menuTermController.close();
                      },
                    ),
                    MenuItemButton(
                      child: Text('第二学期',style: TextStyle(fontSize: GlobalVars.stdgradeswitchterm_term_title),),
                      onPressed: () async {
                        if(mounted){
                          setState(() {
                            currentTermInt = 2;
                            currentTermName = '第二学期';
                          });
                        }
                        saveSelectedTY();
                        readSemesterInfo();
                        menuTermController.close();
                      },
                    ),
                  ],
                  child: SizedBox(
                    height: 50,
                    child: TextButton(
                      style: ElevatedButton.styleFrom(
                        shadowColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        if (menuTermController.isOpen) {
                          menuTermController.close();
                        } else {
                          menuTermController.open();
                        }
                      },
                      child: Text('学期：$currentTermName', style: TextStyle(fontSize: GlobalVars.stdgradeswitchterm_term_title),softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    readStdAccount();
    readSemesterInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (){getStdGrades();},
        backgroundColor: Theme.of(context).colorScheme.primary,
        label: isQuerying? Row(
          children: [
            SizedBox(
              height: 30,
              width: 30,
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary,),
            ),
            SizedBox(width: 10,),
            Text('正在刷新',style: TextStyle(fontSize: GlobalVars.refreshstdgrade_button_title),)
          ],
        ):
        Row(
          children: [
            Icon(Icons.refresh),
            SizedBox(width: 10,),
            Text('刷新数据',style: TextStyle(fontSize: GlobalVars.refreshstdgrade_button_title),)
          ],
        ),
      ),
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
                actions: [
                  IconButton(
                    onPressed: () => switchTerm(),
                    icon: Icon(Icons.date_range),
                  )
                ],
                pinned: true,
                expandedHeight: 0,
                title: _showAppBarTitle ? Text("我的成绩") : null,
              ),
            ];
          },
          body: ListView(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 30),
                child: Row(
                  children: [
                    Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/grade.png'):AssetImage('assets/icons/darktheme/grade.png'),height: 40,),
                    SizedBox(width: 10,),
                    Text('我的成绩',style: TextStyle(fontSize: GlobalVars.stdgrade_page_title),)
                  ],
                ),
              ),
              noGrades? 
              Center(
                child: Container(
                  padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                  child: Card(
                    shadowColor: Theme.of(context).colorScheme.onPrimary,
                    color: Theme.of(context).colorScheme.surfaceDim,
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.error),
                      title: Text('暂无 成绩 信息',style: TextStyle(fontSize: GlobalVars.nostdgrade_hint_title,fontWeight: FontWeight.bold),),
                      subtitle: Text('当前学期：$currentYearName $currentTermName\n请尝试在右上角切换学期或在右下角刷新',style: TextStyle(fontSize: GlobalVars.nostdgrade_hint_subtitle),),
                    ),
                  ),
                ),
              ):
              Container(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                child: Card(
                  shadowColor: Theme.of(context).colorScheme.onPrimary,
                  color: Theme.of(context).colorScheme.surfaceDim,
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    children: stdGradesTotal.map((grades) {
                    return Container(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //Text('序号：${i + 1}',style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                          Text('课程名称：${grades['CourseName']}',style: TextStyle(fontSize: GlobalVars.stdgrade_coursename_title,fontWeight: FontWeight.bold),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                          SizedBox(height: 10,),
                          Text('学分：${grades['CourseCredit']}',style: TextStyle(fontSize: GlobalVars.stdgrade_coursecredit_title,fontWeight: FontWeight.bold),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                          Text('总评成绩：${grades['CourseGradeTotal']}',style: TextStyle(fontSize: GlobalVars.stdgrade_coursegradetotal_title,fontWeight: FontWeight.bold),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                          Text('最终：${grades['CourseGradeFinal']}',style: TextStyle(fontSize: GlobalVars.stdgrade_coursegradefinal_title,fontWeight: FontWeight.bold),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                          Text('绩点：${grades['CourseGradeGPA']}',style: TextStyle(fontSize: GlobalVars.stdgrade_coursegradegpa_title,fontWeight: FontWeight.bold),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                          SizedBox(height: 10,),
                          Text('课程类别：${grades['CourseType']}',style: TextStyle(fontSize: GlobalVars.stdgrade_coursetype_title),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                          SizedBox(height: 20,),
                          Divider(height: 5,indent: 20,endIndent: 20,),
                        ],
                      ),
                    );
                  }).toList(),
                  )
                ),
              ),
              Container(padding: EdgeInsets.fromLTRB(0, 80, 0, 0),)
            ],
          ),
        ),
      ),
    );
  }

  getStdGrades() async {
    if(mounted){
      setState(() {
        isQuerying = true;
      });
    }
    
    //课表数据目录
    Directory courseTableStddirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/courseTableStd');
    if(await courseTableStddirectory.exists() == false){
      await courseTableStddirectory.create();
    }

    String? passwordhash = '';//存储 Hash
    String encryptedpassword = '';//加密后的密码

    //初始化 Dio
    CookieJar jwglcookie = CookieJar();
    Dio dio = Dio();
    dio.interceptors.add(CookieManager(jwglcookie));

    //第一次请求，获取 hash
    var response1;
    try{
      response1 = await dio.get('http://jwgl.snut.edu.cn/eams/loginExt.action');
    }catch (e){
      if(mounted){
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        setState(() {
          isQuerying = false;
        });
      }
      return;
    }

    String jwglcode = response1.data.toString();
    RegExp regExp = RegExp(r"SHA1\('([0-9a-fA-F\-]+)-");
    Match? match = regExp.firstMatch(jwglcode);
      
    if (match != null) {
      passwordhash = match.group(1);
    } else {
      return;
    }

    // **对密码进行加密**
    var combinedpassword = utf8.encode('$passwordhash-$passWord');
    var digest = sha1.convert(combinedpassword);
    encryptedpassword = digest.toString();

    //等待半秒，防止教务系统判定为过快点击
    await Future.delayed(Duration(milliseconds: 500));

    //第二次请求，尝试登录
    final formData = FormData.fromMap({
      "username": userName,
      "password": encryptedpassword,
      "session_locale": "zh_CN"
    });

    Response response2 = await dio.post(
      'http://jwgl.snut.edu.cn/eams/loginExt.action',
      options: Options(
        followRedirects: true,
        validateStatus: (status){
          return status != null && status <= 302;
        },
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "User-Agent": "PostmanRuntime/7.43.0",
        }
      ),
      data: formData,
    );
    String response2string = response2.data.toString();
    if(response2string.contains('账户不存在')){
      if(mounted){
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
            content: Text('登录失败，账户不存在\n您的账户是否因毕业等原因被校方注销？',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        setState(() {
          isQuerying = false;
        });
      }
    return;
    }if(response2string.contains('密码错误')){
      if(mounted){
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
            content: Text('登录失败，密码错误\n您是否在学校官网修改过密码？\n如果是，请退出智慧陕理并重新登录',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        setState(() {
          isQuerying = false;
        });
      }
    return;
    }
    

    //请求首页，初始化数据
    var homeresponse1;
    try{
      homeresponse1 = await dio.get(
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
          }
        ),
        'http://jwgl.snut.edu.cn/eams/homeExt.action',
      );
    }catch (e){
      if(mounted){
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        setState(() {
          isQuerying = false;
        });
      }
      return;
    }

    //请求成绩页面
    
    //等待半秒，防止教务系统判定为过快点击
    await Future.delayed(Duration(milliseconds: 500));

    var stdGradesresponse1;
    try{
      stdGradesresponse1 = await dio.get(
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
          }
        ),
        'http://jwgl.snut.edu.cn/eams/teach/grade/course/person.action',
      );
    }catch (e){
      if(mounted){
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        setState(() {
          isQuerying = false;
        });
      }
      return;
    }

    //提取相关数据
    String semesterId = '';
    String tagId = '';

    RegExp semesterExp = RegExp(r'semester\.id=(\d+)');
    Match? semesteridmatch = semesterExp.firstMatch(stdGradesresponse1.headers['Set-Cookie'][0].toString());
    if(semesteridmatch != null){
      semesterId = semesteridmatch.group(1)!;
    }

    RegExp tagIdExp = RegExp(r'semesterBar(\d+)Semester');
    Match? tagIdmatch = tagIdExp.firstMatch(stdGradesresponse1.data.toString());
    if(tagIdmatch != null){
      tagId = tagIdmatch.group(1)!;
    }

    //使用本地选中的 semetserid
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();

    //开始下载成绩
    var stdGradesresponse2;
    try{
      stdGradesresponse2 = await dio.get(
        'http://jwgl.snut.edu.cn/eams/teach/grade/course/person!search.action?semesterId=$semesterId',
        options: Options(
          headers: {
            "User-Agent": "PostmanRuntime/7.43.0",
          }
        ),
      );
    }catch (e){
      if(mounted){
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        setState(() {
          isQuerying = false;
        });
      }
      return;
    }



    List<Map<String, String>> foundedGrades = [];
    dom.Document stdExmaDocument2 = parser.parse(stdGradesresponse2.data);
    
    //提取 tableid
    dom.Element? table = stdExmaDocument2.querySelector('table.gridtable');
    if (table == null) return jsonEncode([]);
    String? tableId = table.attributes['id']; // 使用attributes获取id
    if (tableId == null || tableId.isEmpty) return jsonEncode([]);

    // 查找 tbody 对应的 id
    String tbodyId = "${tableId}_data";
    stdExmaDocument2.querySelectorAll('#$tbodyId tr').forEach((tr) {
      List<dom.Element> tds = tr.querySelectorAll('td');
      if (tds.length >= 8) {
        Map<String, String> grades = {
          "CourseTY": tds[0].text.trim(),
          "CourseCode": tds[1].text.trim(),
          "CourseID": tds[2].text.trim(),
          "CourseName": tds[3].text.trim(),
          "CourseType": tds[4].text.trim(),
          "CourseCredit": tds[5].text.trim(),
          "CourseGradeTotal": tds[6].text.trim(),
          "CourseGradeFinal": tds[7].text.trim(),
          "CourseGradeGPA": tds[8].text.trim(),
        };
        foundedGrades.add(grades);
      }
    });

    if(mounted){
      setState(() {
        stdGradesTotal = foundedGrades;
      });
    }

    // 保存成绩信息到本地
    // 使用本地选中的 semetserid
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();
    String stdGradespath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdGrades/stdGrades$semesterId.json';
    File stdGradesfile = File(stdGradespath);
    stdGradesfile.writeAsString(jsonEncode(foundedGrades));

    readstdGrades();
    if(stdGradesTotal.isEmpty){
      if(mounted){
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
            content: Text('当前学期暂无考试成绩',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
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
    if(mounted){
      setState(() {
        isQuerying = false;
        needRefresh = false;
      });
    }
  }
}