import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:smartsnut/globalvars.dart';

//验证码输入框
final TextEditingController textCaptchaController = TextEditingController();

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
bool noGrades = true;//用于判断该学期是否有成绩
double gpaTotal = 0.00;//存储每门课的绩点
int validGradesNum = 0;//存储有效成绩的数量
double gradeTotal = 0.00;//存储每门课的总评成绩

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
    readstdGrades();
  }

  //读取成绩信息
  readstdGrades() async  {
    //使用本地选中的 semetserid 来读取对应的成绩
    String semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();

    String stdGradespath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdGrades/stdGrades$semesterId.json';
    File stdGradesfile = File(stdGradespath);
    if(await stdGradesfile.exists()){
      gpaTotal = 0.00;
      var readGradesTotal = jsonDecode(await stdGradesfile.readAsString());
      if(readGradesTotal.isEmpty){
        if(mounted){
          setState(() {
            noGrades = true;
          });
        }
      }else{
        stdGradesTotal = readGradesTotal;
        noGrades = false;
        for(int i = 0; i < stdGradesTotal.length; i++){
          double gpa = double.parse(stdGradesTotal[i]['CourseGradeGPA']!);
          gpaTotal += gpa;
          try {
            double grade = double.parse(stdGradesTotal[i]['CourseGradeTotal']!);
            gradeTotal += grade;
            validGradesNum++; // 只有成功解析为数字的成绩才计入有效成绩数
          } catch (e) {
            // 如果解析失败，说明成绩不是数字（可能是"优秀"/"良好"等），跳过统计
            continue;
          }
        }
        if(mounted){
          setState(() {});
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


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      readStdAccount();
      readSemesterInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (){getStdGrades();},
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        label: Row(
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
                    tooltip: '切换成绩时间',
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
                padding: EdgeInsets.fromLTRB(16, 20, 16, 30),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image(
                        image: Theme.of(context).brightness == Brightness.light
                          ? AssetImage('assets/icons/lighttheme/grade.png')
                          : AssetImage('assets/icons/darktheme/grade.png'),
                        height: 32,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '我的成绩',
                      style: TextStyle(
                        fontSize: GlobalVars.genericPageTitle,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    )
                  ],
                ),
              ),
              
              noGrades? 
              // 无成绩信息显示
              Center(
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 20),
                  child: Card(
                    shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                    color: Theme.of(context).colorScheme.surfaceDim,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image(
                            image: Theme.of(context).brightness == Brightness.light? 
                              AssetImage('assets/icons/lighttheme/empty.png'):
                              AssetImage('assets/icons/darktheme/empty.png'),
                            height: MediaQuery.of(context).size.height / 4,
                          ),
                          Divider(height: 24, indent: 20, endIndent: 20,),
                          Text(
                            '暂无 $currentYearName $currentTermName 的 成绩 信息',
                            style: TextStyle(
                              fontSize: GlobalVars.listTileTitle,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '请尝试在右上角切换学期或在右下角刷新',
                            style: TextStyle(
                              fontSize: GlobalVars.listTileSubtitle,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ):
              // 有成绩信息显示
              Column(
                children: [
                  // 成绩统计卡片
                  Container(
                    padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Card(
                      shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                      color: Theme.of(context).colorScheme.surfaceDim,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calculate, color: Theme.of(context).colorScheme.primary),
                                SizedBox(width: 12),
                                Text(
                                  '成绩统计',
                                  style: TextStyle(
                                    fontSize: GlobalVars.genericTextLarge,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 24),
                            Row(
                              children: [
                                Icon(Icons.trending_up, size: 18, color: Theme.of(context).colorScheme.secondary),
                                SizedBox(width: 8),
                                Text(
                                  '算术平均绩点：',
                                  style: TextStyle(fontSize: GlobalVars.genericTextMedium),
                                ),
                                Expanded(
                                  child: Text(
                                    (gpaTotal / stdGradesTotal.length).toStringAsFixed(2),
                                    style: TextStyle(
                                      fontSize: GlobalVars.genericTextMedium,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.score, size: 18, color: Theme.of(context).colorScheme.secondary),
                                SizedBox(width: 8),
                                Text(
                                  '算术平均成绩：',
                                  style: TextStyle(fontSize: GlobalVars.genericTextMedium),
                                ),
                                Expanded(
                                  child: Text(
                                    (gradeTotal / validGradesNum).toStringAsFixed(2),
                                    style: TextStyle(
                                      fontSize: GlobalVars.genericTextMedium,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.school, size: 18, color: Theme.of(context).colorScheme.secondary),
                                SizedBox(width: 8),
                                Text(
                                  '本学期课程数：',
                                  style: TextStyle(fontSize: GlobalVars.genericTextMedium),
                                ),
                                Expanded(
                                  child: Text(
                                    '${stdGradesTotal.length} 门',
                                    style: TextStyle(
                                      fontSize: GlobalVars.genericTextMedium,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // 成绩详细信息卡片
                  Container(
                    padding: EdgeInsets.fromLTRB(16, 10, 16, 20),
                    child: Card(
                      shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                      color: Theme.of(context).colorScheme.surfaceDim,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.list_alt,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '成绩详情',
                                    style: TextStyle(
                                      fontSize: GlobalVars.listTileTitle,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 24, indent: 16, endIndent: 16),
                            Column(
                              children: stdGradesTotal.map((grades) {
                                return buildGradeItem(context, grades);
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
              // 底部间隔
              Container(padding: EdgeInsets.fromLTRB(0, 80, 0, 0),)
            ],
          ),
        ),
      ),
    );
  }

  // 新增帮助方法 - 构建成绩项
  Widget buildGradeItem(BuildContext context, Map grades) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${grades['CourseName']}', 
              style: TextStyle(
                fontSize: GlobalVars.listTileTitle, 
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.score, 
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                SizedBox(width: 8),
                Text(
                  '总评成绩：${grades['CourseGradeTotal']}',
                  style: TextStyle(
                    fontSize: GlobalVars.genericTextMedium,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.grade,
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                SizedBox(width: 8),
                Text(
                  '绩点：${grades['CourseGradeGPA']}',
                  style: TextStyle(
                    fontSize: GlobalVars.genericTextMedium,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline, 
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                SizedBox(width: 8),
                Text(
                  '最终：${grades['CourseGradeFinal']}',
                  style: TextStyle(
                    fontSize: GlobalVars.genericTextMedium,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.credit_card, 
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                SizedBox(width: 8),
                Text(
                  '学分：${grades['CourseCredit']}',
                  style: TextStyle(
                    fontSize: GlobalVars.genericTextMedium,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.category, 
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '课程类别：${grades['CourseType']}',
                    style: TextStyle(
                      fontSize: GlobalVars.genericTextMedium,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 切换考试学期
  switchTerm() async {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('切换成绩时间',style: TextStyle(fontSize: GlobalVars.alertdialogTitle),),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 学年选择
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: MenuAnchor(
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          if (menuYearController.isOpen) {
                            menuYearController.close();
                          } else {
                            menuYearController.open();
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '学年：$currentYearName',
                              style: TextStyle(
                                fontSize: GlobalVars.genericSwitchMenuTitle,
                                fontWeight: FontWeight.w500,
                              ),
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis
                            ),
                            Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 学期选择
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: MenuAnchor(
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          if (menuTermController.isOpen) {
                            menuTermController.close();
                          } else {
                            menuTermController.open();
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '学期：$currentTermName', 
                              style: TextStyle(
                                fontSize: GlobalVars.genericSwitchMenuTitle,
                                fontWeight: FontWeight.w500,
                              ),
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis
                            ),
                            Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      },
    );
  }

  getStdGrades() async {
    String loadStateString = '请稍后...';
    bool getStdGradesCanceled = false;
    if(mounted){
      showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              scrollable: true,
              title: Text('正在刷新...',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
              content: Column(
                children: [
                  SizedBox(height: 10,),
                  CircularProgressIndicator(),
                  SizedBox(height: 10,),
                  Text(loadStateString,style: TextStyle(fontSize: GlobalVars.alertdialogContent))
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    getStdGradesCanceled = true;
                    Navigator.pop(context);
                  },
                  child: const Text('取消'),
                ),
              ],
            ),
          );
        },
      );
    }
    
    //课表数据目录
    Directory courseTableStddirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/courseTableStd');
    if(await courseTableStddirectory.exists() == false){
      await courseTableStddirectory.create();
    }

    String encryptedpassword = '';//加密后的密码
    String authexecution = '';//存储获取到的 execution
    String pwdEncryptSalt = '';//存储获取到的 pwdEncryptSalt

    //初始化 Dio
    CookieJar authservercookie = CookieJar();
    Dio dio = Dio();
    dio.interceptors.add(CookieManager(authservercookie));

    //第一次请求，提取 execution
    if(mounted){
      setState(() {
        loadStateString = '正在获取登录信息...';
      });
    }
    if(getStdGradesCanceled) return;
    late Response authresponse1;
    try{
      authresponse1 = await dio.get('https://authserver.snut.edu.cn/authserver/login?service=http%3A%2F%2Fjwgl.snut.edu.cn%2Feams%2FssoLogin.action');
    }catch (e){
      if(mounted){
        Navigator.pop(context);
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
        loadStateString = '请稍后...';
        return;
      }
    }   
    // 提取 execution 值// 定义正则表达式查找带有 "execution" 名称的隐藏输入字段
    final RegExp executionRegExp = RegExp(
      r'<input\s+type="hidden"\s+id="execution"\s+name="execution"\s+value="([^"]+)"',
      caseSensitive: false,
    );
    // 在响应中查找匹配
    final Match? match = executionRegExp.firstMatch(authresponse1.data.toString());
    // 如果找到匹配项，则返回提取的值
    if (match != null && match.groupCount >= 1) {
      authexecution = match.group(1)!;
    }

    // 提取 pwdEncryptSalt 值
    final RegExp pwdEncryptSaltRegExp = RegExp(
      r'<input\s+type="hidden"\s+id="pwdEncryptSalt"\s+value="([^"]+)"',
      caseSensitive: false,
    );
    // 在响应中查找匹配
    final Match? saltMatch = pwdEncryptSaltRegExp.firstMatch(authresponse1.data.toString());
    // 如果找到匹配项，则提取值
    if (saltMatch != null && saltMatch.groupCount >= 1) {
      pwdEncryptSalt = saltMatch.group(1)!;
    }

    //AES 加密密码// 使用提取到的 pwdEncryptSalt 作为密钥
    encryptedpassword = encryptAES(passWord,pwdEncryptSalt);

    //请求验证码
    if(mounted){
      setState(() {
        loadStateString = '正在获取验证码...';
      });
    }
    
    String captchaCode = '';
    Uint8List? captchaBytes;
    bool isLoadingCaptcha = false;

    getAuthCaptcha() async {
      if(mounted){
        setState(() {
          isLoadingCaptcha = true;
        });
      }
      textCaptchaController.clear();
      // 请求验证码图片
      if(getStdGradesCanceled) return;
      Response captchaResponse = await dio.get(
        'https://authserver.snut.edu.cn/authserver/getCaptcha.htl',
        options: Options(
          responseType: ResponseType.bytes, // 指定响应类型为字节数组
        ),
      );
      
      // 确保响应数据是 Uint8List 类型
      if (captchaResponse.data is Uint8List) {
        captchaBytes = captchaResponse.data;
      } else {
        // 如果不是，尝试转换
        captchaBytes = Uint8List.fromList(captchaResponse.data as List<int>);
      }
      if(mounted){
        setState(() {
          isLoadingCaptcha = false;
        });
      }
    }

    await getAuthCaptcha();
    if(mounted) {
      Navigator.pop(context);
      await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('请输入验证码',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textCaptchaController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '验证码',
                          hintText: '请输入验证码',
                          filled: false
                        ),
                      ),
                    ),
                    SizedBox(width: 10,),
                    isLoadingCaptcha? 
                    FittedBox(
                      child: CircularProgressIndicator(),
                    )
                    :Expanded(
                      child: FittedBox(
                        child: Image.memory(captchaBytes!),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 10,),
                Divider(height: 15,indent: 20,endIndent: 20,),
                Text('验证码不区分大小写',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                Divider(height: 15,indent: 20,endIndent: 20,),
                SizedBox(height: 10,),
                Column(
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size(double.infinity, 50), // 确保按钮宽度填满父容器
                    ),
                    onPressed: isLoadingCaptcha? null:() {
                      getAuthCaptcha();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '刷新验证码',
                          style: TextStyle(
                            fontSize: GlobalVars.genericTextMedium,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  getStdGradesCanceled = true;
                  Navigator.pop(context);
                  return;
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  if(textCaptchaController.text.isEmpty){
                    showDialog<String>(
                      context: context, 
                      builder: (BuildContext context)=>AlertDialog(
                        title: Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
                        content: Text('验证码不能为空，请输入验证码',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                        actions: [TextButton(onPressed:  () => Navigator.pop(context, 'Cancel'), child: Text('确认'))],
                      ));
                    return;
                  }
                  captchaCode = textCaptchaController.text;
                  Navigator.pop(context);
                },
                child: const Text('确定'),
              ),
            ],
          ),
          );
        },
      );
    }

    if(getStdGradesCanceled) return;
    if(mounted){
      showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              scrollable: true,
              title: Text('正在刷新...',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
              content: Column(
                children: [
                  SizedBox(height: 10,),
                  CircularProgressIndicator(),
                  SizedBox(height: 10,),
                  Text(loadStateString,style: TextStyle(fontSize: GlobalVars.alertdialogContent))
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    getStdGradesCanceled = true;
                    Navigator.pop(context);
                  },
                  child: const Text('取消'),
                ),
              ],
            ),
          );
        },
      );
    }

    //开始登录
    if(mounted){
      setState(() {
        loadStateString = '正在登录...';
      });
    }
    late Response authresponse2;
    final loginParams = {
      "username": userName,
      "password": encryptedpassword,
      "captcha": captchaCode,
      "_eventId": "submit",
      "cllt": "userNameLogin",
      "dllt": "generalLogin",
      "lt": "",
      "execution": authexecution,
    };
    try{
      if(getStdGradesCanceled) return;
      authresponse2 = await  dio.post(
        'https://authserver.snut.edu.cn/authserver/login?service=http%3A%2F%2Fjwgl.snut.edu.cn%2Feams%2FssoLogin.action',
        data: loginParams,
        options: Options(
          followRedirects: false,
          validateStatus: (status) {
            return status! <= 401;
          },
          contentType: Headers.formUrlEncodedContentType,
        )
      );
    }catch(e){
      if(mounted){
        Navigator.pop(context);
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
        loadStateString = '请稍后...';
      }
      return;
    }
    if(authresponse2.data.toString().contains('您提供的用户名或者密码有误')){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('用户名或密码错误',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        loadStateString = '请稍后...';
        return;
      }
    }
    if(authresponse2.data.toString().contains('图形动态码错误')){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('验证码错误',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        loadStateString = '请稍后...';
        return;
      }
    }

    //手动跟随重定向
    try{
      //跟随第一步重定向 (ssologin 的 ticket)
      if(getStdGradesCanceled) return;
      var authresponse21 = await dio.get(
        authresponse2.headers['location']![0],
        data: loginParams,
        options: Options(
          followRedirects: false,
          validateStatus: (status) {
            return status! <= 302;
          },
          contentType: Headers.formUrlEncodedContentType,
        )
      );
      //跟随第二步重定向 (ssologin 的 ticket)
      if(getStdGradesCanceled) return;
      var authresponse22 = await dio.get(
        authresponse21.headers['location']![0],
        data: loginParams,
        options: Options(
          followRedirects: false,
          validateStatus: (status) {
            return status! <= 307;
          },
          contentType: Headers.formUrlEncodedContentType,
        )
      );
      //跟随第三步重定向 (ssologin 的 jsessionid)
      if(getStdGradesCanceled) return;
      await dio.get(
        'http://jwgl.snut.edu.cn${authresponse22.headers['location']![0]}',
        data: loginParams,
        options: Options(
          followRedirects: false,
          contentType: Headers.formUrlEncodedContentType,
        )
      );
    }catch(e){
      if(mounted){
        Navigator.pop(context);
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
        loadStateString = '请稍后...';
      }
      return;
    }

    //请求成绩页面
    if(mounted){
      setState(() {
        loadStateString = '正在获取成绩...';
      });
    }
    //等待半秒，防止教务系统判定为过快点击
    if(getStdGradesCanceled) return;
    await Future.delayed(Duration(milliseconds: 500));

    if(getStdGradesCanceled) return;
    late Response stdGradesresponse1;
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
        Navigator.pop(context);
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
        loadStateString = '请稍后...';
        return;
      }
    }

    //提取相关数据
    String semesterId = '';

    RegExp semesterExp = RegExp(r'semester\.id=(\d+)');
    Match? semesteridmatch = semesterExp.firstMatch(stdGradesresponse1.headers['Set-Cookie']!.first);
    if(semesteridmatch != null){
      semesterId = semesteridmatch.group(1)!;
    }

    //使用本地选中的 semetserid
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();

    //开始下载成绩
    if(getStdGradesCanceled) return;
    late Response stdGradesresponse2;
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
        Navigator.pop(context);
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
        loadStateString = '请稍后...';
        return;
      }
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
        Navigator.pop(context);
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('当前学期暂无考试成绩',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        loadStateString = '请稍后...';
        return;
      }
    }
    if(mounted){
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成绩数据刷新成功'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
        ),
      );
      Navigator.pop(context);
    }
  }
  
  //加密密码
  String encryptAES(String data, String keyString) {
    // 字符集
    String chars = "ABCDEFGHJKMNPQRSTWXYZabcdefhijkmnprstwxyz2345678";
    var random = Random();

    // 生成随机字符串
    String randomString(int length) {
      var result = StringBuffer();
      for (var i = 0; i < length; i++) {
        result.write(chars[random.nextInt(chars.length)]);
      }
      return result.toString();
    }

    // 生成64位随机前缀和16位IV
    String randomPrefix = randomString(64);
    String iv = randomString(16);

    // 准备加密所需的key和iv
    final key = encrypt.Key.fromUtf8(keyString.trim());
    final ivObj = encrypt.IV.fromUtf8(iv);

    // 创建AES加密器
    final encrypter = encrypt.Encrypter(
      encrypt.AES(
        key,
        mode: encrypt.AESMode.cbc,
        padding: 'PKCS7',
      ),
    );

    // 加密数据(随机前缀+原始数据)
    final encrypted = encrypter.encrypt(randomPrefix + data, iv: ivObj);

    // 返回Base64编码的加密结果
    return encrypted.base64;
  }
}