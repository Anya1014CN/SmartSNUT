import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartsnut/function_modules.dart';
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
    showDialog(
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('确定'),
              ),
            ],
          ),
        );
      },
    );
  }

  getStdGrades() async {
    GlobalVars.operationCanceled = false;
    GlobalVars.loadingHint = '正在加载...';
    if(mounted){
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              scrollable: true,
              title: Text('请稍后...',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
              content: Column(
                children: [
                  SizedBox(height: 10,),
                  CircularProgressIndicator(),
                  SizedBox(height: 10,),
                  Text(GlobalVars.loadingHint,style: TextStyle(fontSize: GlobalVars.alertdialogContent))
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    GlobalVars.operationCanceled = true;
                    Navigator.pop(context);
                  },
                  child: Text('取消'),
                ),
              ],
            ),
          );
        },
      );
    }

    if(GlobalVars.operationCanceled) return;
    List loginAuthResponse = await Modules.loginAuth(userName, passWord,'jwgl');
    if(loginAuthResponse[0]['statue'] == false){
      if(mounted){
        Navigator.pop(context);
        showDialog(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error),
                SizedBox(width: 8),
                Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
              ],
            ),
            content: Text(loginAuthResponse[0]['message'],style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('确定'))],
          ));
      }
      return;
    }

    if(GlobalVars.operationCanceled) return;
    List getStdGradesResponse = await Modules.getStdGrades(currentYearInt, currentTermInt);
    if(getStdGradesResponse[0]['statue'] == false){
      if(mounted){
        Navigator.pop(context);
        showDialog(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error),
                SizedBox(width: 8),
                Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
              ],
            ),
            content: Text(getStdGradesResponse[0]['message'],style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('确定'))],
          ));
      }
      return;
    }

    if(mounted){
      setState(() {
        stdGradesTotal = getStdGradesResponse[0]['stdGradesTotal'];
      });
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
}