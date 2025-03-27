import 'dart:convert';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:smartsnut/globalvars.dart';

//保存查询状态
bool isQuerying = false;

//学期信息
String termStart = '';
String termEnd = '';
int termWeeks = 0;
bool termEnded = false;

//菜单 Controller
final menuYearController = MenuController();
final menuTermController = MenuController();
final menuExamBatchController = MenuController();

//用户数据
List stdAccount = [];
String userName = '';
String passWord = '';

//学期数据
Map semestersData = {};
int semesterTotal = 0;//学年的数量
List semestersName = [];

//当前考试学年
int currentYearInt = 1;
String currentYearName = '';

//当前考试学期
int currentTermInt = 1;
String currentTermName = '';

//当前考试批次
int currentExamBatch = 1;
int currentExamBatchid = 000;
String currentExamBatchName = '';

//当前学期考试信息
List stdExamTotal = [];
bool noExam = false;//用于判断该学期是否有考试

class StdExamPage extends StatefulWidget{
  const StdExamPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _StdExamPageState();
  }
}

class _StdExamPageState extends State<StdExamPage>{
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

    //每次读取之前进行考试数据目录检查，防止后续版本升级，目录未被创建导致崩溃
    Directory stdExamdirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam');
    if(await stdExamdirectory.exists() == false){
      await stdExamdirectory.create();
    }
    
    String selectedTYpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam/selectedTY.json';
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
          currentExamBatch = selectedTYjson[2]['examBatch'];
          if(currentExamBatch == 0){
            currentExamBatchName = '期末考试';
          }if(currentExamBatch == 1){
            currentExamBatchName = '重修考试';
          }
        });
      }
    }else{
      if(mounted){
        setState(() {
          currentYearInt = semestersData.length - 1;
          currentYearName = semestersName[semestersName.length - 1]['name'];
          currentExamBatch = 0;
          currentExamBatchName = '期末考试';
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
    readSchoolCalendarInfo();
  }

  //读取校历相关信息
  readSchoolCalendarInfo() async {
    String semesterId = '';
    //使用本地选中的 semetserid 来读取对应的成绩
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();
    String schoolCalendarpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/schoolCalendar/schoolCalendar$semesterId.json';
    File schoolCalendarfile = File(schoolCalendarpath);
    if(await schoolCalendarfile.exists()){
      var termTimejson = jsonDecode(await schoolCalendarfile.readAsString());
      termStart = termTimejson[0]['termStart'];
      termEnd = termTimejson[0]['termEnd'];
    }
    readstdExam();
  }

  //读取考试信息
  readstdExam() async  {
    //使用本地选中的 semetserid 来读取对应的课表
    var stdExamBatchInfo;
    String semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();
    String stdExamBatchpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam/stdExam$semesterId-Batch.json';
    File stdExamBatchfile = File(stdExamBatchpath);
    if(await stdExamBatchfile.exists()){
      stdExamBatchInfo = jsonDecode(await stdExamBatchfile.readAsString());
      if(currentExamBatch == 0){
        if(stdExamBatchInfo[0]['normalExam'] == ''){
          if(mounted){
            setState(() {
              noExam = true;
            });
          }
        }else{
          currentExamBatchid = int.parse(stdExamBatchInfo[0]['normalExam']);
          if(mounted){
            setState(() {
              noExam = false;
            });
          }
        }
      }if(currentExamBatch == 1){
        if(stdExamBatchInfo[0]['retakeExam'] == ''){
          if(mounted){
            setState(() {
              noExam = true;
            });
          }
        }else{
          currentExamBatchid = int.parse(stdExamBatchInfo[0]['retakeExam']);
          if(mounted){
            setState(() {
              noExam = false;
            });
          }
        }
      }
    }else{
      if(mounted){
        setState(() {
          noExam = true;
        });
      }
    }

    String stdExampath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam/stdExam$semesterId-$currentExamBatchid.json';
    File stdExamfile = File(stdExampath);
    if(await stdExamfile.exists()){
      var readexamTotal = jsonDecode(await stdExamfile.readAsString());
      if(readexamTotal.isEmpty){
        if(mounted){
          setState(() {
            noExam = true;
          });
        }
      }else{
        if(mounted){
          setState(() {
            stdExamTotal = readexamTotal;
            noExam = false;
          });
        }
      }
    }else{
      if(mounted){
        setState(() {
          noExam = true;
        });
      }
    }
  }
  
  ///保存选中的考试学期状态
  saveSelectedTY() async {
    String selectedTYpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam/selectedTY.json';
    File selectedTYfile = File(selectedTYpath);
    List selectedTY = [];
    selectedTY.remove('selectedYear');
    selectedTY.remove('selectedTerm');
    selectedTY.remove('examBatch');
    selectedTY.add({
      'selectedYear': currentYearInt,
    });
    selectedTY.add({
      'selectedTerm': currentTermInt,
    });
    selectedTY.add({
      'examBatch': currentExamBatch,
    });
    //保存完成后刷新状态，防止出现参数更新不及时的情况
    setState(() {});
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
            title: Text('切换考试时间',style: TextStyle(fontSize: GlobalVars.alertdialogTitle),),
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
                      child: Text('${item['name']} 学年',style: TextStyle(fontSize: GlobalVars.genericSwitchMenuTitle),),
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
                      child: Text('学年：$currentYearName',style: TextStyle(fontSize: GlobalVars.genericSwitchMenuTitle),softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
                Divider(height: 5, indent: 20, endIndent: 20),
                MenuAnchor(
                  controller: menuTermController,
                  menuChildren: [
                    MenuItemButton(
                      child: Text('第一学期',style: TextStyle(fontSize: GlobalVars.genericSwitchMenuTitle),),
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
                      child: Text('第二学期',style: TextStyle(fontSize: GlobalVars.genericSwitchMenuTitle),),
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
                      child: Text('学期：$currentTermName', style: TextStyle(fontSize: GlobalVars.genericSwitchMenuTitle),softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
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
        onPressed: (){getStdExam();},
        backgroundColor: Theme.of(context).colorScheme.primary,
        label: isQuerying? Row(
          children: [
            SizedBox(
              height: 30,
              width: 30,
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary,),
            ),
            SizedBox(width: 10,),
            Text('正在刷新',style: TextStyle(fontSize: GlobalVars.genericFloationActionButtonTitle),)
          ],
        ):
        Row(
          children: [
            Icon(Icons.refresh),
            SizedBox(width: 10,),
            Text('刷新数据',style: TextStyle(fontSize: GlobalVars.genericFloationActionButtonTitle),)
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
                title: _showAppBarTitle ? Text("我的考试") : null,
              ),
            ];
          },
          body: ListView(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 30),
                child: Row(
                  children: [
                    Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/exam.png'):AssetImage('assets/icons/darktheme/exam.png'),height: 40,),
                    SizedBox(width: 10,),
                    Text('我的考试',style: TextStyle(fontSize: GlobalVars.genericPageTitle),)
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(21),
                  ),
                  shadowColor: Theme.of(context).colorScheme.onPrimary,
                  color: Theme.of(context).colorScheme.surfaceDim,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MenuAnchor(
                        controller: menuExamBatchController,
                        menuChildren: [
                          MenuItemButton(
                            child: Text('期末考试',style: TextStyle(fontSize: GlobalVars.genericSwitchMenuTitle),),
                            onPressed: () async {
                              if(mounted){
                                setState(() {
                                  currentExamBatch = 0;
                                  currentExamBatchName = '期末考试';
                                });
                              }
                              saveSelectedTY();
                              readSemesterInfo();
                              menuExamBatchController.close();
                            },
                          ),
                          MenuItemButton(
                            child: Text('重修考试',style: TextStyle(fontSize: GlobalVars.genericSwitchMenuTitle),),
                            onPressed: () async {
                              if(mounted){
                                setState(() {
                                  currentExamBatch = 1;
                                  currentExamBatchName = '重修考试';
                                });
                              }
                              saveSelectedTY();
                              readSemesterInfo();
                              menuExamBatchController.close();
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
                              if (menuExamBatchController.isOpen) {
                                menuExamBatchController.close();
                              } else {
                                menuExamBatchController.open();
                              }
                            },
                            child: Text('考试类型：$currentExamBatchName', style: TextStyle(fontSize: GlobalVars.genericSwitchContainerTitle),softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    ],
                  )
                ),
              ),
              noExam? 
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
                      title: Text('暂无 $currentExamBatchName 信息',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),),
                      subtitle: Text('当前学期：$currentYearName $currentTermName\n请尝试在右上角切换学期或在右下角刷新',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
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
                    children: stdExamTotal.map((exam) {
                    return Container(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('课程名称：${exam['CourseName']}', style: TextStyle(fontSize: GlobalVars.genericTextMedium, fontWeight: FontWeight.bold)),
                          Text('考试日期：${exam['CourseExamDate']}', style: TextStyle(fontSize: GlobalVars.genericTextMedium)),
                          Text('考试时间：${exam['CourseExamTime']}', style: TextStyle(fontSize: GlobalVars.genericTextMedium)),
                          Text('座位号：${exam['CourseExamSeatNo']}', style: TextStyle(fontSize: GlobalVars.genericTextMedium)),
                          Text('考试类型：${exam['CourseExamType']}', style: TextStyle(fontSize: GlobalVars.genericTextMedium)),
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

  getStdExam() async {
    if(mounted){
      setState(() {
        isQuerying = true;
      });
    }
    
    //考试数据目录
    Directory stdExamdirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam');
    if(await stdExamdirectory.exists() == false){
      await stdExamdirectory.create();
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
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
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
        validateStatus: (Status){
          return Status != null && Status <= 302;
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
          title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
          content: Text('登录失败，账户不存在\n您的账户是否因毕业等原因被校方注销？',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
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
          title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
          content: Text('登录失败，密码错误\n您是否在学校官网修改过密码？\n如果是，请退出智慧陕理并重新登录',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
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
            'Referer': 'http://jwgl.snut.edu.cn/eams/stdExamTable.action',
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
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
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

    //请求考试页面
    
    //等待半秒，防止教务系统判定为过快点击
    await Future.delayed(Duration(milliseconds: 500));

    var stdExamresponse1;
    try{
      stdExamresponse1 = await dio.get(
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
            'Referer': 'http://jwgl.snut.edu.cn/eams/stdExamTable.action',
          }
        ),
        'http://jwgl.snut.edu.cn/eams/stdExamTable.action',
      );
    }catch (e){
      if(mounted){
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
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
    Match? semesteridmatch = semesterExp.firstMatch(stdExamresponse1.headers['Set-Cookie'][0].toString());
    if(semesteridmatch != null){
      semesterId = semesteridmatch.group(1)!;
    }

    RegExp tagIdExp = RegExp(r'semesterBar(\d+)Semester');
    Match? tagIdmatch = tagIdExp.firstMatch(stdExamresponse1.data.toString());
    if(tagIdmatch != null){
      tagId = tagIdmatch.group(1)!;
    }

    //获取 examBatchId

    //使用本地选中的 semetserid 来覆盖教务系统返回的 semetserid ，用于请求对应的考试
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1]['id'].toString();

    //等待半秒，防止教务系统判定为过快点击
    await Future.delayed(Duration(milliseconds: 500));

   final stdExamformData2 = FormData.fromMap({
      "project.id": '1',
      "semester.id": semesterId.toString(),
    });
    var stdExamresponse5;
    try{
      var headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      var data = {
        'project.id': '1',
        'semester.id': semesterId
      };
      stdExamresponse5 = await dio.request(
        'http://jwgl.snut.edu.cn/eams/stdExamTable.action',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );
    }catch (e){
      if(mounted){
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
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

    dom.Document stdExamdocument1 = parser.parse(stdExamresponse5.data);
    // 找到 <select> 标签
    dom.Element? select = stdExamdocument1.querySelector('select#examBatchId');
    if (select == null) return {};

    // 存储 examBatchId
    String normalExam = "";
    String retakeExam = "";

    // 遍历所有 <option> 选项
    select.querySelectorAll('option').forEach((option) {
      String value = option.attributes['value'] ?? "";
      String text = option.text.trim();

      if (text == "期末考试") {
        normalExam = value;
      } else if (text == "重修考试") {
        retakeExam = value;
      }
    });
    
    //保存考试批次id信息到本地
    List stdExamBatchID = [];
    //使用本地选中的 semetserid
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();
    stdExamBatchID.add({
      'normalExam': normalExam,
      'retakeExam': retakeExam
    });
    String stdExamBatchpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam/stdExam$semesterId-Batch.json';
    File stdExamBatchfile = File(stdExamBatchpath);
    stdExamBatchfile.writeAsString(jsonEncode(stdExamBatchID));
    

    //请求考试的详细信息
    if(await stdExamBatchfile.exists() && normalExam != '' && retakeExam != ''){
      if(currentExamBatch == 0){
        currentExamBatchid = int.parse(normalExam);
      }if(currentExamBatch == 1){
        currentExamBatchid = int.parse(retakeExam);
      }
    }else{
      if(mounted){
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('当前学期暂未设置考试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
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
    var stdExamresponse6;
    try{
      stdExamresponse6 = await dio.get(
        'http://jwgl.snut.edu.cn/eams/stdExamTable!examTable.action?examBatch.id=$currentExamBatchid',
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
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法连接服务器，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
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

    List<Map<String, String>> foundedExams = [];
    dom.Document stdExmaDocument2 = parser.parse(stdExamresponse6.data);
    
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
        Map<String, String> exam = {
          "CourseID": tds[0].text.trim(),
          "CourseName": tds[1].text.trim(),
          "CourseExamType": tds[2].text.trim(),
          "CourseExamDate": tds[3].text.trim(),
          "CourseExamTime": tds[4].text.trim(),
          "CourseExamLocation": tds[5].text.trim(),
          "CourseExamSeatNo": tds[6].text.trim(),
          "CourseExamState": tds[7].text.trim(),
          "CourseExamDescription": tds.length > 8 ? tds[8].text.trim() : ""
        };
        foundedExams.add(exam);
      }
    });

    if(mounted){
      setState(() {
        stdExamTotal = foundedExams;
      });
    }

    //保存考试信息到本地
    //使用本地选中的 semetserid
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();
    String stdExampath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam/stdExam$semesterId-$currentExamBatchid.json';
    File stdExamfile = File(stdExampath);
    stdExamfile.writeAsString(jsonEncode(foundedExams));

    readSchoolCalendarInfo();
    if(mounted){
      setState(() {
        isQuerying = false;
      });
    }
  }
}