import 'dart:convert';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' as parser;
import 'package:intl/intl.dart';
import 'package:smartsnut/globalvars.dart';

//判断是否需要联网下载课表
bool needRefresh = false;

//存储本周每一天的日期
List<String> weekDates = [];
int weekDiff = 0;//存储用户的周数与当前周数的差异

//学期信息
String termStart = '';
String termEnd = '';
int termWeeks = 0;
bool termEnded = false;

//周信息
int currentDOW = 0;

//课表滚动控制器
final ScrollController tableVerticalController = ScrollController();
final ScrollController tableHorizontalController = ScrollController();
double horizontalDragStart = 0.0;//支持鼠标直接拖拽课表

//定义课表的行高和列宽
double tableWidth = 0;
double tableHeadWidth = 0;
double tableHeight = 0;

//课表的色块
List<Color> courseBlockColors = [];
//莫兰迪色系
final List<Color> courseBlockMoLandiColors = [
  Color(0xffd89c7a),
  Color(0xffd6c38b),
  Color(0xffcfc3a9),
  Color(0xff849b91),
  Color(0xffe1ccb1),
  Color(0xffd4baad),
  Color(0xffc2cedc),
  Color(0xffb0b1b6),
  Color(0xff979771),
  Color(0xff91ad9e),
  Color(0xff686789),
  Color(0xffb77f70),
  Color(0xffbeb1a8),
  Color(0xffa79a89),
  Color(0xff8a95a9),
  Color(0xff9fabb9),
  Color(0xff9aa690),
  Color(0xff91a0a5),
  Color(0xff99857e),
  Color(0xff7d7465),
  Color(0xff88878d),
  Color(0xffb4746b),
  Color(0xff676662),
  Color(0xffab545a),
  Color(0xff724e52),
  Color(0xffbca295),
  Color(0xffaea9a6),
  Color(0xffceb797),
  Color(0xff9a7549),
  Color(0xffbca289),
  Color(0xffb57c82),
];
//马卡龙色系
final List<Color> courseBlockMakalongColors = [
  Color(0xfff1707d),
  Color(0xff155369),
  Color(0xffef5767),
  Color(0xffae716e),
  Color(0xffcb8e85),
  Color(0xffcf8878),
  Color(0xffc86f67),
  Color(0xfff1ccb8),
  Color(0xfff2debd),
  Color(0xffb8d38f),
  Color(0xffddff95),
  Color(0xffff9b6a),
  Color(0xfff1b8f1),
  Color(0xffd9b8f1),
  Color(0xfff1ccb8),
  Color(0xfff1f1b8),
  Color(0xffb8f1ed),
  Color(0xffb8f1cc),
  Color(0xffe7dbca),
  Color(0xffe26538),
  Color(0xfff3d751),
  Color(0xfffd803a),
  Color(0xfffe997b),
  Color(0xffc490a0),
  Color(0xfff28a63),
  Color(0xffdf7a30),
];

//全年课表数据
List courseTableFull = [];//一学期的完整课表
List<List> courseMonTotal = [[],[],[],[],[],[],[],[],[],[]];//周一课程（第一节到第十节）
List<List> courseTueTotal = [[],[],[],[],[],[],[],[],[],[]];//周二课程
List<List> courseWedTotal = [[],[],[],[],[],[],[],[],[],[]];//周三课程
List<List> courseThuTotal = [[],[],[],[],[],[],[],[],[],[]];//周四课程
List<List> courseFriTotal = [[],[],[],[],[],[],[],[],[],[]];//周五课程
List<List> courseSatTotal = [[],[],[],[],[],[],[],[],[],[]];//周六课程
List<List> courseSunTotal = [[],[],[],[],[],[],[],[],[],[]];//周日课程

//单周课表数据
List<List> courseMonWeek = [[],[],[],[],[],[],[],[],[],[]];//周一课程（第一节到第十节）
List<List> courseTueWeek = [[],[],[],[],[],[],[],[],[],[]];//周二课程
List<List> courseWedWeek = [[],[],[],[],[],[],[],[],[],[]];//周三课程
List<List> courseThuWeek = [[],[],[],[],[],[],[],[],[],[]];//周四课程
List<List> courseFriWeek = [[],[],[],[],[],[],[],[],[],[]];//周五课程
List<List> courseSatWeek = [[],[],[],[],[],[],[],[],[],[]];//周六课程
List<List> courseSunWeek = [[],[],[],[],[],[],[],[],[],[]];//周日课程

//课程详情
String sheetcourseName = '';
String sheetcourseWeeks = '';
String sheetcourseTeacher = '';
String sheetcourseLocation = '';

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
final menuWeekController = MenuController();

//当前课表学年
int currentYearInt = 1;
String currentYearName = '';

//当前课表学期
int currentTermInt = 1;
String currentTermName = '';
bool noCourseTable = false;//用于判断该学期是否有课表

//当前课表信息
int currentWeekInt = 1;
late DateTime termStartDateTime;
late DateTime termEndDateTime;

//判断课表加载状态
bool isReading = true;

class CourseTablePage extends StatefulWidget{
  const CourseTablePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CourseTablePage();
  }
}

class _CourseTablePage extends State<CourseTablePage>{

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

  //读取课表的选中状态
  readSelectState() async {
    String selectedTYpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/courseTableStd/selectedTY.json';
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
      getCourseTable();
    }else{
      readSchoolCalendarInfo();
    }
  }

  //读取校历相关信息
  readSchoolCalendarInfo() async {
    String semesterId = '';
    //使用本地选中的 semetserid 来读取对应的课表
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();
    String schoolCalendarpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/schoolCalendar/schoolCalendar$semesterId.json';
    File schoolCalendarfile = File(schoolCalendarpath);
    if(await schoolCalendarfile.exists()){
      var termTimejson = jsonDecode(await schoolCalendarfile.readAsString());
      termStart = termTimejson[0]['termStart'];
      termEnd = termTimejson[0]['termEnd'];

      final dateFormat = DateFormat(r"yyyy'-'MM'-'dd");
      termStartDateTime = dateFormat.parse(termStart);
      termEndDateTime = dateFormat.parse(termEnd);
      termWeeks = termTimejson[0]['termWeeks'];
      int currentDay = DateTime.now().difference(termStartDateTime).inDays + 1;
      if(currentDay % 7 != 0){
        if(mounted){
          if((currentDay ~/ 7) + 1 > termWeeks){
            if(mounted){
              setState(() {
                termEnded = true;
                currentDOW = currentDay % 7;
              });
            }
          }else{
            if(mounted){
              setState(() {
                termEnded = false;
                currentWeekInt = (currentDay ~/ 7) + 1;
                currentDOW = currentDay % 7;
              });
            }
          }
        }
        saveSelectedTY();
      }if(currentDay % 7 == 0){
        if(mounted){
          if(currentDay ~/ 7 > termWeeks){
            if(mounted){
              setState(() {
                termEnded = true;
                currentDOW =  7;
              });
            }
          }else{
            if(mounted){
              setState(() {
                termEnded = false;
                currentWeekInt = currentDay ~/ 7;
                currentDOW =  7;
              });
            }
          }
        }
        saveSelectedTY();
      }
    }
    readCourseTabDetail();
  }

  ///保存选中的课表学期状态
  saveSelectedTY() async {
    String selectedTYpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/courseTableStd/selectedTY.json';
    File selectedTYfile = File(selectedTYpath);
    List selectedTY = [];
    selectedTY.remove('selectedYear');
    selectedTY.remove('selectedTerm');
    selectedTY.remove('selectedWeek');
    selectedTY.add({
      'selectedYear': currentYearInt,
    });
    selectedTY.add({
      'selectedTerm': currentTermInt,
    });
    selectedTYfile.writeAsString(jsonEncode(selectedTY));
  }

  //读取学期课表信息
  readCourseTabDetail() async {
    String semesterId = '';
    //使用本地选中的 semetserid 来读取对应的课表
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();
    String courseTablepath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/courseTableStd/courseTable$semesterId.json';
    File courseTablefile = File(courseTablepath);
    if(await courseTablefile.exists()){
      courseTableFull = jsonDecode(await courseTablefile.readAsString());
      if(mounted){
        setState(() {
          noCourseTable = false;
        });
      }
    }else{
      if(mounted){
        setState(() {
          noCourseTable = true;
        });
      }
    }
    //请求刷新课表之前先初始化课表
    courseMonTotal = [[],[],[],[],[],[],[],[],[],[]];//周一课程（第一节到第十节）
    courseTueTotal = [[],[],[],[],[],[],[],[],[],[]];//周二课程
    courseWedTotal = [[],[],[],[],[],[],[],[],[],[]];//周三课程
    courseThuTotal = [[],[],[],[],[],[],[],[],[],[]];//周四课程
    courseFriTotal = [[],[],[],[],[],[],[],[],[],[]];//周五课程
    courseSatTotal = [[],[],[],[],[],[],[],[],[],[]];//周六课程
    courseSunTotal = [[],[],[],[],[],[],[],[],[],[]];//周日课程
    for(int courseint = 0; courseint < courseTableFull.length; courseint++){

      //处理课程的周数数据
        List<int> onePositions = [];

        // 记录所有 '1' 的索引
        for (int index = 0; index < courseTableFull[courseint]['CourseWeeks'].length; index++) {
          if (courseTableFull[courseint]['CourseWeeks'][index] == '1') {
            onePositions.add(index);
          }
        }

        // 处理相邻 '1' 的索引
        List<String> formattedResult = [];
        int rangeStart = onePositions[0];
        int rangeEnd = rangeStart;

        for (int position = 1; position < onePositions.length; position++) {
          if (onePositions[position] == onePositions[position - 1] + 1) {
            rangeEnd = onePositions[position];
          } else {
            formattedResult.add(rangeStart == rangeEnd ? "$rangeStart" : "$rangeStart-$rangeEnd");
            rangeStart = onePositions[position];
            rangeEnd = rangeStart;
          }
        }
        //最终的处理结果
        formattedResult.add(rangeStart == rangeEnd ? "$rangeStart" : "$rangeStart-$rangeEnd");

      //先判断课程在每一天的第几节
      for(int timesint = 1; timesint <= courseTableFull[courseint]['CourseTimes'].length; timesint++){
        //如果是每一天的第一节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 0){
          //如果是周一的第一节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[0].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周二的第一节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[0].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周三的第一节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[0].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周四的第一节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[0].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周五的第一节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[0].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周六的第一节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[0].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周日的第一节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[0].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
        }
        //如果是每一天的第二节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 1){
          //如果是周一的第二节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[1].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周二的第二节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[1].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周三的第二节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[1].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周四的第二节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[1].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周五的第二节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[1].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周六的第二节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[1].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周日的第二节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[1].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
        }
        //如果是每一天的第三节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 2){
          //如果是周一的第三节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[2].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周二的第三节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[2].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周三的第三节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[2].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周四的第三节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[2].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周五的第三节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[2].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周六的第三节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[2].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周日的第三节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[2].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
        }
        //如果是每一天的第四节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 3){
          //如果是周一的第四节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[3].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周二的第四节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[3].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周三的第四节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[3].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周四的第四节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[3].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周五的第四节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[3].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周六的第四节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[3].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周日的第四节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[3].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
        }
        //如果是每一天的第五节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 4){
          //如果是周一的第五节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[4].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周二的第五节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[4].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周三的第五节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[4].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周四的第五节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[4].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周五的第五节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[4].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周六的第五节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[4].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周日的第五节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[4].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
        }
        //如果是每一天的第六节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 5){
          //如果是周一的第六节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[5].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周二的第六节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[5].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周三的第六节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[5].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周四的第六节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[5].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周五的第六节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[5].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周六的第六节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[5].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周日的第六节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[5].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
        }
        //如果是每一天的第七节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 6){
          //如果是周一的第七节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[6].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周二的第七节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[6].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周三的第七节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[6].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周四的第七节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[6].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周五的第七节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[6].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周六的第七节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[6].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周日的第七节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[6].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
        }
        //如果是每一天的第八节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 7){
          //如果是周一的第八节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[7].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周二的第八节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[7].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周三的第八节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[7].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周四的第八节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[7].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周五的第八节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[7].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周六的第八节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[7].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周日的第八节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[7].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
        }
        //如果是每一天的第九节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 8){
          //如果是周一的第九节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[8].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周二的第九节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[8].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周三的第九节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[8].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周四的第九节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[8].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周五的第九节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[8].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周六的第九节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[8].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周日的第九节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[8].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
        }
        //如果是每一天的第十节课
        if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['TimeOfDay'] == 9){
          //如果是周一的第十节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 0){
            courseMonTotal[9].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周二的第十节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 1){
            courseTueTotal[9].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周三的第十节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 2){
            courseWedTotal[9].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周四的第十节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 3){
            courseThuTotal[9].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周五的第十节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 4){
            courseFriTotal[9].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周六的第十节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 5){
            courseSatTotal[9].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
          //如果是周日的第十节课
          if(courseTableFull[courseint]['CourseTimes'][timesint - 1]['DayOfWeek'] == 6){
            courseSunTotal[9].add({
              'CourseName': courseTableFull[courseint]['CourseName'],
              'CourseLocation': courseTableFull[courseint]['CourseLocation'],
              'CourseTeacher': courseTableFull[courseint]['CourseTeacher'],
              'CourseWeeks': courseTableFull[courseint]['CourseWeeks'],
              'FormattedWeeks': formattedResult.join(" 周, "),
            });
          }
        }
      }
    }
    readWeeklyCourseTableDetail();
  }

  //读取单周课表信息
  readWeeklyCourseTableDetail() async {
    String semesterId = '';
    //使用本地选中的 semetserid 来读取对应的课表
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1 ]['id'].toString();
    String courseTablepath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/courseTableStd/courseTable$semesterId.json';
    File courseTablefile = File(courseTablepath);
    if(await courseTablefile.exists()){
      courseTableFull = jsonDecode(await courseTablefile.readAsString());
      if(mounted){setState(() {});}
    }
    //请求刷新课表之前先初始化课表
    courseMonWeek = [[],[],[],[],[],[],[],[],[],[]];//周一课程（第一节到第十节）
    courseTueWeek = [[],[],[],[],[],[],[],[],[],[]];//周二课程
    courseWedWeek = [[],[],[],[],[],[],[],[],[],[]];//周三课程
    courseThuWeek = [[],[],[],[],[],[],[],[],[],[]];//周四课程
    courseFriWeek = [[],[],[],[],[],[],[],[],[],[]];//周五课程
    courseSatWeek = [[],[],[],[],[],[],[],[],[],[]];//周六课程
    courseSunWeek = [[],[],[],[],[],[],[],[],[],[]];//周日课程

    //加载本周周一课程
    for(int courseTODInt = 0; courseTODInt <= 9;courseTODInt++){
      for(int courseInt = 0;courseInt < courseMonTotal[courseTODInt].length;courseInt++){
        if(courseMonTotal[courseTODInt][courseInt]['CourseWeeks'][currentWeekInt] == '1'){
          courseMonWeek[courseTODInt].add({
              'CourseName': courseMonTotal[courseTODInt][courseInt]['CourseName'],
              'CourseLocation': courseMonTotal[courseTODInt][courseInt]['CourseLocation'],
              'CourseTeacher': courseMonTotal[courseTODInt][courseInt]['CourseTeacher'],
              'FormattedWeeks': courseMonTotal[courseTODInt][courseInt]['FormattedWeeks']
          });
        }
      }
    }

    //加载本周周二课程
    for(int courseTODInt = 0; courseTODInt <= 9;courseTODInt++){
      for(int courseInt = 0;courseInt < courseTueTotal[courseTODInt].length;courseInt++){
        if(courseTueTotal[courseTODInt][courseInt]['CourseWeeks'][currentWeekInt] == '1'){
          courseTueWeek[courseTODInt].add({
              'CourseName': courseTueTotal[courseTODInt][courseInt]['CourseName'],
              'CourseLocation': courseTueTotal[courseTODInt][courseInt]['CourseLocation'],
              'CourseTeacher': courseTueTotal[courseTODInt][courseInt]['CourseTeacher'],
              'FormattedWeeks': courseTueTotal[courseTODInt][courseInt]['FormattedWeeks']
          });
        }
      }
    }

    //加载本周周三课程
    for(int courseTODInt = 0; courseTODInt <= 9;courseTODInt++){
      for(int courseInt = 0;courseInt < courseWedTotal[courseTODInt].length;courseInt++){
        if(courseWedTotal[courseTODInt][courseInt]['CourseWeeks'][currentWeekInt] == '1'){
          courseWedWeek[courseTODInt].add({
              'CourseName': courseWedTotal[courseTODInt][courseInt]['CourseName'],
              'CourseLocation': courseWedTotal[courseTODInt][courseInt]['CourseLocation'],
              'CourseTeacher': courseWedTotal[courseTODInt][courseInt]['CourseTeacher'],
              'FormattedWeeks': courseWedTotal[courseTODInt][courseInt]['FormattedWeeks']
          });
        }
      }
    }

    //加载本周周四课程
    for(int courseTODInt = 0; courseTODInt <= 9;courseTODInt++){
      for(int courseInt = 0;courseInt < courseThuTotal[courseTODInt].length;courseInt++){
        if(courseThuTotal[courseTODInt][courseInt]['CourseWeeks'][currentWeekInt] == '1'){
          courseThuWeek[courseTODInt].add({
              'CourseName': courseThuTotal[courseTODInt][courseInt]['CourseName'],
              'CourseLocation': courseThuTotal[courseTODInt][courseInt]['CourseLocation'],
              'CourseTeacher': courseThuTotal[courseTODInt][courseInt]['CourseTeacher'],
              'FormattedWeeks': courseThuTotal[courseTODInt][courseInt]['FormattedWeeks']
          });
        }
      }
    }

    //加载本周周五课程
    for(int courseTODInt = 0; courseTODInt <= 9;courseTODInt++){
      for(int courseInt = 0;courseInt < courseFriTotal[courseTODInt].length;courseInt++){
        if(courseFriTotal[courseTODInt][courseInt]['CourseWeeks'][currentWeekInt] == '1'){
          courseFriWeek[courseTODInt].add({
              'CourseName': courseFriTotal[courseTODInt][courseInt]['CourseName'],
              'CourseLocation': courseFriTotal[courseTODInt][courseInt]['CourseLocation'],
              'CourseTeacher': courseFriTotal[courseTODInt][courseInt]['CourseTeacher'],
              'FormattedWeeks': courseFriTotal[courseTODInt][courseInt]['FormattedWeeks']
          });
        }
      }
    }

    //加载本周周六课程
    for(int courseTODInt = 0; courseTODInt <= 9;courseTODInt++){
      for(int courseInt = 0;courseInt < courseSatTotal[courseTODInt].length;courseInt++){
        if(courseSatTotal[courseTODInt][courseInt]['CourseWeeks'][currentWeekInt] == '1'){
          courseSatWeek[courseTODInt].add({
              'CourseName': courseSatTotal[courseTODInt][courseInt]['CourseName'],
              'CourseLocation': courseSatTotal[courseTODInt][courseInt]['CourseLocation'],
              'CourseTeacher': courseSatTotal[courseTODInt][courseInt]['CourseTeacher'],
              'FormattedWeeks': courseSatTotal[courseTODInt][courseInt]['FormattedWeeks']
          });
        }
      }
    }

    //加载本周周日课程
    for(int courseTODInt = 0; courseTODInt <= 9;courseTODInt++){
      for(int courseInt = 0;courseInt < courseSunTotal[courseTODInt].length;courseInt++){
        if(courseSunTotal[courseTODInt][courseInt]['CourseWeeks'][currentWeekInt] == '1'){
          courseSunWeek[courseTODInt].add({
              'CourseName': courseSunTotal[courseTODInt][courseInt]['CourseName'],
              'CourseLocation': courseSunTotal[courseTODInt][courseInt]['CourseLocation'],
              'CourseTeacher': courseSunTotal[courseTODInt][courseInt]['CourseTeacher'],
              'FormattedWeeks': courseSunTotal[courseTODInt][courseInt]['FormattedWeeks']
          });
        }
      }
    }
    if(mounted){
      setState(() {
        isReading = false;
      });//全部解析完成之后刷新
    }
  }

  //切换课表学期
  switchTerm() async {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('切换课表时间',style: TextStyle(fontSize: GlobalVars.alertdialogTitle),),
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
                        readSchoolCalendarInfo();
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
                      child: Text('当前学年：$currentYearName',style: TextStyle(fontSize: GlobalVars.genericSwitchMenuTitle),),
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
                        readSchoolCalendarInfo();
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
                        readSchoolCalendarInfo();
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
                      child: Text('当前学期：$currentTermName',style: TextStyle(fontSize: GlobalVars.genericSwitchMenuTitle),),
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
    //加载课表色块的颜色列表
    if(GlobalVars.courseBlockColorsInt == 0){
      courseBlockColors = courseBlockMoLandiColors;
    }if(GlobalVars.courseBlockColorsInt == 1){
      courseBlockColors = courseBlockMakalongColors;
    }
    //清空学期列表
    semestersData = {};
    semestersName = [];
    super.initState();
    getWeekDates();
    readStdAccount();
    readSemesterInfo();
  }

  @override
  Widget build(BuildContext context) {
    
    //获取长宽并保存
    tableWidth = (MediaQuery.of(context).size.width /7) - 3;
    tableHeight = ((MediaQuery.of(context).size.height) / 12) - 2;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => switchTerm(),
            icon: Icon(Icons.date_range),
          )
        ],
        title: Text('我的课表',style: TextStyle(fontSize: GlobalVars.genericPageTitleSmall),),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        leading: IconButton(
          onPressed: (){Navigator.pop(context);},
          icon: Icon(Icons.arrow_back),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (){getCourseTable();},
        backgroundColor: Theme.of(context).colorScheme.primary,
        label: Row(
          children: [
            Icon(Icons.refresh),
            SizedBox(width: 10,),
            Text('刷新课表',style: TextStyle(fontSize: GlobalVars.genericFloationActionButtonTitle),)
          ],
        ),
      ),
      body: isReading? Center(child: CircularProgressIndicator(),):ListView(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(21),
              ),
              shadowColor: Theme.of(context).colorScheme.onPrimary,
              color: Theme.of(context).colorScheme.surfaceDim,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: (currentWeekInt == 1)? null:(){
                      if(mounted){
                        setState(() {
                          currentWeekInt --;
                          weekDiff --;
                        });
                      }
                      getWeekDates();
                      readWeeklyCourseTableDetail();
                      saveSelectedTY();
                    },
                    icon: Icon(Icons.arrow_back),
                  ),
                  termEnded? Text('第 $currentWeekInt 周\n（本学期已结束）',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.genericSwitchContainerTitle),):Text('第 $currentWeekInt 周',style: TextStyle(fontSize: GlobalVars.genericSwitchContainerTitle),),
                  IconButton(
                    onPressed: (currentWeekInt == termWeeks)? null:(){
                      if(mounted){
                        setState(() {
                          currentWeekInt ++;
                          weekDiff ++;
                        });
                      }
                      getWeekDates();
                      readWeeklyCourseTableDetail();
                      saveSelectedTY();
                    },
                    icon: Icon(Icons.arrow_forward),
                  ),
                ],
              )
            ),
          ),
          noCourseTable? 
          Center(
            child: Container(
              padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
              child: Card(
                shadowColor: Theme.of(context).colorScheme.onPrimary,
                color: Theme.of(context).colorScheme.surfaceDim,
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/empty.png'):AssetImage('assets/icons/darktheme/empty.png'),height: MediaQuery.of(context).size.height / 4,),
                    Divider(height: 5,indent: 20,endIndent: 20,),
                    SizedBox(height: 10,),
                    Text('暂无 $currentYearName $currentTermName 的 课表 信息\n请尝试在右上角切换学期或在右下角刷新',style: TextStyle(fontSize: GlobalVars.listTileTitle,fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
                    SizedBox(height: 10,),
                  ],
                ),
              ),
            ),
          ):
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                //表头 - 节次 + 星期几
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text('节\n次',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.genericTextSmall),),
                    ),
                    Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                      shadowColor: Theme.of(context).colorScheme.onPrimary,
                      child: SizedBox(
                        width: tableWidth,
                        child: Text('一\n${weekDates[0]}',textAlign: TextAlign.center,style: TextStyle(fontWeight: (currentDOW == 1)? FontWeight.w900:FontWeight.normal,fontSize: GlobalVars.genericTextSmall),),
                      )
                    ),
                    Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                      shadowColor: Theme.of(context).colorScheme.onPrimary,
                      child: SizedBox(
                        width: tableWidth,
                        child: Text('二\n${weekDates[1]}',textAlign: TextAlign.center,style: TextStyle(fontWeight: (currentDOW == 2)? FontWeight.w900:FontWeight.normal,fontSize: GlobalVars.genericTextSmall),),
                      )
                    ),
                    Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,  
                      shadowColor: Theme.of(context).colorScheme.onPrimary,
                      child: SizedBox(
                        width: tableWidth,
                        child: Text('三\n${weekDates[2]}',textAlign: TextAlign.center,style: TextStyle(fontWeight: (currentDOW == 3)? FontWeight.w900:FontWeight.normal,fontSize: GlobalVars.genericTextSmall),),
                      )
                    ),
                    Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                      shadowColor: Theme.of(context).colorScheme.onPrimary,
                      child: SizedBox(
                        width: tableWidth,
                        child: Text('四\n${weekDates[3]}',textAlign: TextAlign.center,style: TextStyle(fontWeight: (currentDOW == 4)? FontWeight.w900:FontWeight.normal,fontSize: GlobalVars.genericTextSmall),),
                      )
                    ),
                    Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,  
                      shadowColor: Theme.of(context).colorScheme.onPrimary,
                      child: SizedBox(
                        width: tableWidth,
                        child: Text('五\n${weekDates[4]}',textAlign: TextAlign.center,style: TextStyle(fontWeight: (currentDOW == 5)? FontWeight.w900:FontWeight.normal,fontSize: GlobalVars.genericTextSmall),),
                      )
                    ),
                    GlobalVars.showSatCourse? Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                      shadowColor: Theme.of(context).colorScheme.onPrimary,
                      child: SizedBox(
                        width: tableWidth,
                        child: Text('六\n${weekDates[5]}',textAlign: TextAlign.center,style: TextStyle(fontWeight: (currentDOW == 6)? FontWeight.w900:FontWeight.normal,fontSize: GlobalVars.genericTextSmall),),
                      )
                    ):SizedBox(),
                    GlobalVars.showSunCourse? Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                      shadowColor: Theme.of(context).colorScheme.onPrimary,
                      child: SizedBox(
                        width: tableWidth,
                        child: Text('日\n${weekDates[6]}',textAlign: TextAlign.center,style: TextStyle(fontWeight: (currentDOW == 7)? FontWeight.w900:FontWeight.normal,fontSize: GlobalVars.genericTextSmall),),
                      )
                    ):SizedBox(),
                  ],
                ),
                Divider(height: 5,indent: 20,endIndent: 20,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    //表头 - 第几节课
                    Column(
                      children: [
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('1',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.genericTextSmall),),),
                        ),
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('2',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.genericTextSmall),),),
                        ),
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('3',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.genericTextSmall),),),
                        ),
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('4',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.genericTextSmall),),),
                        ),
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('5',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.genericTextSmall),),),
                        ),
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('6',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.genericTextSmall),),),
                        ),
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('7',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.genericTextSmall),),),
                        ),
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('8',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.genericTextSmall),),),
                        ),
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('9',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.genericTextSmall),),),
                        ),
                        SizedBox(
                          width: 50,
                          height: tableHeight,
                          child: Center(child: Text('10',textAlign: TextAlign.center,style: TextStyle(fontSize: GlobalVars.genericTextSmall),),),
                        ),
                      ],
                    ),
                    //周一课程
                    Column(
                      children: courseMonWeek.asMap().entries.map((entry){
                        int index = entry.key;
                        var item = entry.value;
                        return (item.isEmpty)? ((index == 0 || index == 2 || index == 4 || index == 6 || index == 8)? false:((courseMonWeek[index].isEmpty == true) && (courseMonWeek[index - 1].isEmpty == true)))? 
                        SizedBox(width: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: ((index == 0 || index == 2 || index == 4 || index == 6 || index == 8)? (courseMonWeek[index].isEmpty == true) && (courseMonWeek[index + 1].isEmpty == true):false)? tableHeight * 2:tableHeight,
                          ),
                        ):
                        ((index == 0)? false:((courseMonWeek[index - 1].isEmpty)? false:(courseMonWeek[index][0]['CourseName'] == courseMonWeek[index - 1][0]['CourseName'])? true:false))?
                        SizedBox(height: 0,width: 0,):
                        Builder(
                          builder: (context) => InkWell(
                            onTap: (){
                              sheetcourseName = item[0]['CourseName'];
                              sheetcourseWeeks = item[0]['FormattedWeeks'];
                              sheetcourseTeacher = item[0]['CourseTeacher'];
                              sheetcourseLocation = item[0]['CourseLocation'];
                              showCourseDetail(context);
                            },
                            child: Card(
                              color: courseBlockColors[item[0]['CourseName'].hashCode % courseBlockColors.length],
                              child: SizedBox(
                                width: tableWidth,
                                height: ((index + 3 <= courseMonWeek.length - 1)? ((courseMonWeek[index + 3].isEmpty)? false:(courseMonWeek[index][0]['CourseName'] == courseMonWeek[index + 3][0]['CourseName'])? true:false):false)?
                                  tableHeight * 4:((index + 2 <= courseMonWeek.length - 1)? ((courseMonWeek[index + 2].isEmpty)? false:(courseMonWeek[index][0]['CourseName'] == courseMonWeek[index + 2][0]['CourseName'])? true:false):false)?
                                  tableHeight * 3:((index + 1 <= courseMonWeek.length - 1)? ((courseMonWeek[index + 1].isEmpty)? false:(courseMonWeek[index][0]['CourseName'] == courseMonWeek[index + 1][0]['CourseName'])? true:false):false)?
                                  tableHeight * 2:tableHeight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${item[0]['CourseName']}',style: TextStyle(fontSize: GlobalVars.genericTextSmall),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                    SizedBox(height: 10,),
                                    Text((item[0]['CourseLocation'] == '')? '${item[0]['CourseTeacher']}':'${item[0]['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.genericTextSmall),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    //周二课程
                    Column(
                      children: courseTueWeek.asMap().entries.map((entry){
                        int index = entry.key;
                        var item = entry.value;
                        return (item.isEmpty)? ((index == 0 || index == 2 || index == 4 || index == 6 || index == 8)? false:((courseTueWeek[index].isEmpty == true) && (courseTueWeek[index - 1].isEmpty == true)))? 
                        SizedBox(width: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: ((index == 0 || index == 2 || index == 4 || index == 6 || index == 8)? (courseTueWeek[index].isEmpty == true) && (courseTueWeek[index + 1].isEmpty == true):false)? tableHeight * 2:tableHeight,
                          ),
                        ):
                        ((index == 0)? false:((courseTueWeek[index - 1].isEmpty)? false:(courseTueWeek[index][0]['CourseName'] == courseTueWeek[index - 1][0]['CourseName'])? true:false))?
                        SizedBox(height: 0,width: 0,):
                        Builder(
                          builder: (context) => InkWell(
                            onTap: (){
                              sheetcourseName = item[0]['CourseName'];
                              sheetcourseWeeks = item[0]['FormattedWeeks'];
                              sheetcourseTeacher = item[0]['CourseTeacher'];
                              sheetcourseLocation = item[0]['CourseLocation'];
                              showCourseDetail(context);
                            },
                            child: Card(
                              color: courseBlockColors[item[0]['CourseName'].hashCode % courseBlockColors.length],
                              child: SizedBox(
                                width: tableWidth,
                                height: ((index + 3 <= courseTueWeek.length - 1)? ((courseTueWeek[index + 3].isEmpty)? false:(courseTueWeek[index][0]['CourseName'] == courseTueWeek[index + 3][0]['CourseName'])? true:false):false)?
                                  tableHeight * 4:((index + 2 <= courseTueWeek.length - 1)? ((courseTueWeek[index + 2].isEmpty)? false:(courseTueWeek[index][0]['CourseName'] == courseTueWeek[index + 2][0]['CourseName'])? true:false):false)?
                                  tableHeight * 3:((index + 1 <= courseTueWeek.length - 1)? ((courseTueWeek[index + 1].isEmpty)? false:(courseTueWeek[index][0]['CourseName'] == courseTueWeek[index + 1][0]['CourseName'])? true:false):false)?
                                  tableHeight * 2:tableHeight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${item[0]['CourseName']}',style: TextStyle(fontSize: GlobalVars.genericTextSmall),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                    SizedBox(height: 10,),
                                    Text((item[0]['CourseLocation'] == '')? '${item[0]['CourseTeacher']}':'${item[0]['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.genericTextSmall),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    //周三课程
                    Column(
                      children: courseWedWeek.asMap().entries.map((entry){
                        int index = entry.key;
                        var item = entry.value;
                        return (item.isEmpty)? ((index == 0 || index == 2 || index == 4 || index == 6 || index == 8)? false:((courseWedWeek[index].isEmpty == true) && (courseWedWeek[index - 1].isEmpty == true)))? 
                        SizedBox(width: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: ((index == 0 || index == 2 || index == 4 || index == 6 || index == 8)? (courseWedWeek[index].isEmpty == true) && (courseWedWeek[index + 1].isEmpty == true):false)? tableHeight * 2:tableHeight,
                          ),
                        ):
                        ((index == 0)? false:((courseWedWeek[index - 1].isEmpty)? false:(courseWedWeek[index][0]['CourseName'] == courseWedWeek[index - 1][0]['CourseName'])? true:false))?
                        SizedBox(height: 0,width: 0,):
                        Builder(
                          builder: (context) => InkWell(
                            onTap: () {
                              sheetcourseName = item[0]['CourseName'];
                              sheetcourseWeeks = item[0]['FormattedWeeks'];
                              sheetcourseTeacher = item[0]['CourseTeacher'];
                              sheetcourseLocation = item[0]['CourseLocation'];
                              showCourseDetail(context);
                            },
                            child: Card(
                              color: courseBlockColors[item[0]['CourseName'].hashCode % courseBlockColors.length],
                              child: SizedBox(
                                width: tableWidth,
                                height: ((index + 3 <= courseWedWeek.length - 1)? ((courseWedWeek[index + 3].isEmpty)? false:(courseWedWeek[index][0]['CourseName'] == courseWedWeek[index + 3][0]['CourseName'])? true:false):false)?
                                  tableHeight * 4:((index + 2 <= courseWedWeek.length - 1)? ((courseWedWeek[index + 2].isEmpty)? false:(courseWedWeek[index][0]['CourseName'] == courseWedWeek[index + 2][0]['CourseName'])? true:false):false)?
                                  tableHeight * 3:((index + 1 <= courseWedWeek.length - 1)? ((courseWedWeek[index + 1].isEmpty)? false:(courseWedWeek[index][0]['CourseName'] == courseWedWeek[index + 1][0]['CourseName'])? true:false):false)?
                                  tableHeight * 2:tableHeight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${item[0]['CourseName']}',style: TextStyle(fontSize: GlobalVars.genericTextSmall),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                    SizedBox(height: 10,),
                                    Text((item[0]['CourseLocation'] == '')? '${item[0]['CourseTeacher']}':'${item[0]['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.genericTextSmall),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    //周四课程
                    Column(
                      children: courseThuWeek.asMap().entries.map((entry){
                        int index = entry.key;
                        var item = entry.value;
                        return (item.isEmpty)? ((index == 0 || index == 2 || index == 4 || index == 6 || index == 8)? false:((courseThuWeek[index].isEmpty == true) && (courseThuWeek[index - 1].isEmpty == true)))? 
                        SizedBox(width: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: ((index == 0 || index == 2 || index == 4 || index == 6 || index == 8)? (courseThuWeek[index].isEmpty == true) && (courseThuWeek[index + 1].isEmpty == true):false)? tableHeight * 2:tableHeight,
                          ),
                        ):
                        ((index == 0)? false:((courseThuWeek[index - 1].isEmpty)? false:(courseThuWeek[index][0]['CourseName'] == courseThuWeek[index - 1][0]['CourseName'])? true:false))?
                        SizedBox(height: 0,width: 0,):
                        Builder(
                          builder: (context) => InkWell(
                            onTap: (){
                              sheetcourseName = item[0]['CourseName'];
                              sheetcourseWeeks = item[0]['FormattedWeeks'];
                              sheetcourseTeacher = item[0]['CourseTeacher'];
                              sheetcourseLocation = item[0]['CourseLocation'];
                              showCourseDetail(context);
                            },
                            child: Card(
                              color: courseBlockColors[item[0]['CourseName'].hashCode % courseBlockColors.length],
                              child: SizedBox(
                                width: tableWidth,
                                height: ((index + 3 <= courseThuWeek.length - 1)? ((courseThuWeek[index + 3].isEmpty)? false:(courseThuWeek[index][0]['CourseName'] == courseThuWeek[index + 3][0]['CourseName'])? true:false):false)?
                                  tableHeight * 4:((index + 2 <= courseThuWeek.length - 1)? ((courseThuWeek[index + 2].isEmpty)? false:(courseThuWeek[index][0]['CourseName'] == courseThuWeek[index + 2][0]['CourseName'])? true:false):false)?
                                  tableHeight * 3:((index + 1 <= courseThuWeek.length - 1)? ((courseThuWeek[index + 1].isEmpty)? false:(courseThuWeek[index][0]['CourseName'] == courseThuWeek[index + 1][0]['CourseName'])? true:false):false)?
                                  tableHeight * 2:tableHeight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${item[0]['CourseName']}',style: TextStyle(fontSize: GlobalVars.genericTextSmall),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                    SizedBox(height: 10,),
                                    Text((item[0]['CourseLocation'] == '')? '${item[0]['CourseTeacher']}':'${item[0]['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.genericTextSmall),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    //周五课程
                    Column(
                      children: courseFriWeek.asMap().entries.map((entry){
                        int index = entry.key;
                        var item = entry.value;
                        return (item.isEmpty)? ((index == 0 || index == 2 || index == 4 || index == 6 || index == 8)? false:((courseFriWeek[index].isEmpty == true) && (courseFriWeek[index - 1].isEmpty == true)))? 
                        SizedBox(width: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: ((index == 0 || index == 2 || index == 4 || index == 6 || index == 8)? (courseFriWeek[index].isEmpty == true) && (courseFriWeek[index + 1].isEmpty == true):false)? tableHeight * 2:tableHeight,
                          ),
                        ):
                        ((index == 0)? false:((courseFriWeek[index - 1].isEmpty)? false:(courseFriWeek[index][0]['CourseName'] == courseFriWeek[index - 1][0]['CourseName'])? true:false))?
                        SizedBox(height: 0,width: 0,):
                        Builder(
                          builder: (context) => InkWell(
                            onTap: (){
                              sheetcourseName = item[0]['CourseName'];
                              sheetcourseWeeks = item[0]['FormattedWeeks'];
                              sheetcourseTeacher = item[0]['CourseTeacher'];
                              sheetcourseLocation = item[0]['CourseLocation'];
                              showCourseDetail(context);
                            },
                            child: Card(
                              color: courseBlockColors[item[0]['CourseName'].hashCode % courseBlockColors.length],
                              child: SizedBox(
                                width: tableWidth,
                                height: ((index + 3 <= courseFriWeek.length - 1)? ((courseFriWeek[index + 3].isEmpty)? false:(courseFriWeek[index][0]['CourseName'] == courseFriWeek[index + 3][0]['CourseName'])? true:false):false)?
                                  tableHeight * 4:((index + 2 <= courseFriWeek.length - 1)? ((courseFriWeek[index + 2].isEmpty)? false:(courseFriWeek[index][0]['CourseName'] == courseFriWeek[index + 2][0]['CourseName'])? true:false):false)?
                                  tableHeight * 3:((index + 1 <= courseFriWeek.length - 1)? ((courseFriWeek[index + 1].isEmpty)? false:(courseFriWeek[index][0]['CourseName'] == courseFriWeek[index + 1][0]['CourseName'])? true:false):false)?
                                  tableHeight * 2:tableHeight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${item[0]['CourseName']}',style: TextStyle(fontSize: GlobalVars.genericTextSmall),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                    SizedBox(height: 10,),
                                    Text((item[0]['CourseLocation'] == '')? '${item[0]['CourseTeacher']}':'${item[0]['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.genericTextSmall),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    //周六课程
                    GlobalVars.showSatCourse? Column(
                      children: courseSatWeek.asMap().entries.map((entry){
                        int index = entry.key;
                        var item = entry.value;
                        return (item.isEmpty)? ((index == 0 || index == 2 || index == 4 || index == 6 || index == 8)? false:((courseSatWeek[index].isEmpty == true) && (courseSatWeek[index - 1].isEmpty == true)))? 
                        SizedBox(width: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: ((index == 0 || index == 2 || index == 4 || index == 6 || index == 8)? (courseSatWeek[index].isEmpty == true) && (courseSatWeek[index + 1].isEmpty == true):false)? tableHeight * 2:tableHeight,
                          ),
                        ):
                        ((index == 0)? false:((courseSatWeek[index - 1].isEmpty)? false:(courseSatWeek[index][0]['CourseName'] == courseSatWeek[index - 1][0]['CourseName'])? true:false))?
                        SizedBox(height: 0,width: 0,):
                        Builder(
                          builder: (context) => InkWell(
                            onTap: (){
                              sheetcourseName = item[0]['CourseName'];
                              sheetcourseWeeks = item[0]['FormattedWeeks'];
                              sheetcourseTeacher = item[0]['CourseTeacher'];
                              sheetcourseLocation = item[0]['CourseLocation'];
                              showCourseDetail(context);
                            },
                            child: Card(
                              color: courseBlockColors[item[0]['CourseName'].hashCode % courseBlockColors.length],
                              child: SizedBox(
                                width: tableWidth,
                                height: ((index + 3 <= courseSatWeek.length - 1)? ((courseSatWeek[index + 3].isEmpty)? false:(courseSatWeek[index][0]['CourseName'] == courseSatWeek[index + 3][0]['CourseName'])? true:false):false)?
                                  tableHeight * 4:((index + 2 <= courseSatWeek.length - 1)? ((courseSatWeek[index + 2].isEmpty)? false:(courseSatWeek[index][0]['CourseName'] == courseSatWeek[index + 2][0]['CourseName'])? true:false):false)?
                                  tableHeight * 3:((index + 1 <= courseSatWeek.length - 1)? ((courseSatWeek[index + 1].isEmpty)? false:(courseSatWeek[index][0]['CourseName'] == courseSatWeek[index + 1][0]['CourseName'])? true:false):false)?
                                  tableHeight * 2:tableHeight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${item[0]['CourseName']}',style: TextStyle(fontSize: GlobalVars.genericTextSmall),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                    SizedBox(height: 10,),
                                    Text((item[0]['CourseLocation'] == '')? '${item[0]['CourseTeacher']}':'${item[0]['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.genericTextSmall),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ):SizedBox(),
                    //周日课程
                    GlobalVars.showSunCourse? Column(
                      children: courseSunWeek.asMap().entries.map((entry){
                        int index = entry.key;
                        var item = entry.value;
                        return (item.isEmpty)? ((index == 0 || index == 2 || index == 4 || index == 6 || index == 8)? false:((courseSunWeek[index].isEmpty == true) && (courseSunWeek[index - 1].isEmpty == true)))? 
                        SizedBox(width: 0,):
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh, 
                          shadowColor: Theme.of(context).colorScheme.onPrimary,
                          child: SizedBox(
                            width: tableWidth,
                            height: ((index == 0 || index == 2 || index == 4 || index == 6 || index == 8)? (courseSunWeek[index].isEmpty == true) && (courseSunWeek[index + 1].isEmpty == true):false)? tableHeight * 2:tableHeight,
                          ),
                        ):
                        ((index == 0)? false:((courseSunWeek[index - 1].isEmpty)? false:(courseSunWeek[index][0]['CourseName'] == courseSunWeek[index - 1][0]['CourseName'])? true:false))?
                        SizedBox(height: 0,width: 0,):
                        Builder(
                          builder: (context) => InkWell(
                            onTap: (){
                              sheetcourseName = item[0]['CourseName'];
                              sheetcourseWeeks = item[0]['FormattedWeeks'];
                              sheetcourseTeacher = item[0]['CourseTeacher'];
                              sheetcourseLocation = item[0]['CourseLocation'];
                              showCourseDetail(context);
                            },
                            child: Card(
                              color: courseBlockColors[item[0]['CourseName'].hashCode % courseBlockColors.length],
                              child: SizedBox(
                                width: tableWidth,
                                height: ((index + 3 <= courseSunWeek.length - 1)? ((courseSunWeek[index + 3].isEmpty)? false:(courseSunWeek[index][0]['CourseName'] == courseSunWeek[index + 3][0]['CourseName'])? true:false):false)?
                                  tableHeight * 4:((index + 2 <= courseSunWeek.length - 1)? ((courseSunWeek[index + 2].isEmpty)? false:(courseSunWeek[index][0]['CourseName'] == courseSunWeek[index + 2][0]['CourseName'])? true:false):false)?
                                  tableHeight * 3:((index + 1 <= courseSunWeek.length - 1)? ((courseSunWeek[index + 1].isEmpty)? false:(courseSunWeek[index][0]['CourseName'] == courseSunWeek[index + 1][0]['CourseName'])? true:false):false)?
                                  tableHeight * 2:tableHeight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${item[0]['CourseName']}',style: TextStyle(fontSize: GlobalVars.genericTextSmall),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis,),
                                    SizedBox(height: 10,),
                                    Text((item[0]['CourseLocation'] == '')? '${item[0]['CourseTeacher']}':'${item[0]['CourseLocation']}',style: TextStyle(fontSize: GlobalVars.genericTextSmall),textAlign: TextAlign.center,softWrap: true,maxLines: 2,overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ):SizedBox(),
                  ],
                ),
              ],
            ),
          ),
          Container(padding: EdgeInsets.fromLTRB(0, 80, 0, 0),)
         ],
      ),
    );
  }

  getCourseTable() async {
    bool getCourseTableCanceled = false;
    if(mounted){
      showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          scrollable: true,
          title: Text('正在刷新...',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
          content: Column(
            children: [
              SizedBox(height: 10,),
              CircularProgressIndicator(),
              SizedBox(height: 10,)
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                getCourseTableCanceled = true;
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
          ],
        ),
      );
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
    if(getCourseTableCanceled) return;
    late Response response1;
    try{
      response1 = await dio.get('http://jwgl.snut.edu.cn/eams/loginExt.action');
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
    if(getCourseTableCanceled) return;
    await Future.delayed(Duration(milliseconds: 500));

    //第二次请求，尝试登录
    if(getCourseTableCanceled) return;
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
      Navigator.pop(context);
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
    }
    return;
    }if(response2string.contains('密码错误')){
    if(mounted){
      Navigator.pop(context);
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          scrollable: true,
          title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
          content: Text('登录失败，密码错误\n您是否在学校官网修改过密码？\n如果是，请退出智慧陕理工并重新登录',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    return;
    }
    
    //等待半秒，防止教务系统判定为过快点击
    if(getCourseTableCanceled) return;
    await Future.delayed(Duration(milliseconds: 500));

    //请求课表初始信息
    if(getCourseTableCanceled) return;
    late Response courseresponse1;
    try{
      courseresponse1 = await dio.get('http://jwgl.snut.edu.cn/eams/courseTableForStd.action');
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
      }
      return;
    }
    //提取相关数据
    String semesterId = '';
    String tagId = '';
    String idsMe = '';
    //String idsClass = ''; 班级课表 id

    RegExp semesterExp = RegExp(r'semester\.id=(\d+)');
    Match? semesteridmatch = semesterExp.firstMatch(courseresponse1.headers['Set-Cookie']!.first);
    if(semesteridmatch != null){
      semesterId = semesteridmatch.group(1)!;
    }

    RegExp tagIdExp = RegExp(r'semesterBar(\d+)Semester');
    Match? tagIdmatch = tagIdExp.firstMatch(courseresponse1.data.toString());
    if(tagIdmatch != null){
      tagId = tagIdmatch.group(1)!;
    }

    RegExp idsExp = RegExp(r'bg\.form\.addInput\(form,"ids","(\d+)"\)');
    Iterable<Match> idsmatch = idsExp.allMatches(courseresponse1.data);
    if(idsmatch.length >=2 ){
      idsMe = idsmatch.elementAt(0).group(1)!;
      //idsClass = idsmatch.elementAt(1).group(1)!; 班级课表
    }

    //获取所有学期的 semester.id，学年名称，学期名称
    final courseTableformData = FormData.fromMap({
      "tagId": 'semesterBar${tagId}Semester',
      "dataType": 'semesterCalendar',
      "value": semesterId.toString(),
      "empty": 'false'
    });
    late Response courseresponse2;
    try{
      courseresponse2 = await dio.post(
      'http://jwgl.snut.edu.cn/eams/dataQuery.action',
      options: Options(
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "User-Agent": "PostmanRuntime/7.43.0",
        }
      ),
      data: courseTableformData,
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
      }
      return;
    }

    String rawdata = courseresponse2.data.toString();
    late String semesters;

    //处理教务系统的非标准 json
    rawdata = rawdata.replaceAllMapped(
      RegExp(r'(\w+):'), (match) => '"${match[1]}":');
    rawdata = rawdata.replaceAll("'", "\""); // 替换单引号为双引号
    // 去除 HTML 代码
    rawdata = rawdata.replaceAll(RegExp(r'\"<tr>.*?</tr>\"', dotAll: true), '""');
    // 解析 JSON
    Map<String, dynamic> proceeddata = json.decode(rawdata);
      if (proceeddata.containsKey("semesters")) {
        Map<String, dynamic> semestersMap = proceeddata["semesters"];
        // 转换为标准 JSON 格式的字符串
        String jsonSemesters = json.encode(semestersMap);
        semesters = jsonSemesters;
      }
    
    String semesterspath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/semesters.json';
    File semestersfile = File(semesterspath);
    semestersfile.writeAsString(semesters);

    //获取课表
    //使用本地选中的 semetserid 来覆盖教务系统返回的 semetserid ，用于请求对应的课表
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1]['id'].toString();
    
    //等待半秒，防止教务系统判定为过快点击
    if(getCourseTableCanceled) return;
    await Future.delayed(Duration(milliseconds: 500));

    if(getCourseTableCanceled) return;
    final courseTablegetformData = FormData.fromMap({
      "ignoreHead": '1',
      "setting.kind": 'std',
      "startWeek": '',
      "semester.id": semesterId,
      'ids': idsMe,
    });
    late Response courseresponse3;
    try{
      courseresponse3 = await dio.post(
        'http://jwgl.snut.edu.cn/eams/courseTableForStd!courseTable.action',
        options: Options(
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "PostmanRuntime/7.43.0",
          }
        ),
        data: courseTablegetformData,
      );
    }catch (e){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法连接服务器1，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }


  //解析并保存课表到本地
  List courseTableList = [];
  RegExp courseBlockPattern = RegExp(
    r'activity\s*=\s*new\s*TaskActivity\(.*?,.*?,"(.*?)","(.*?)"\+periodInfo\+.*?","(.*?)","(.*?)","(.*?)",',
    dotAll: true
  );

  RegExp teacherPattern = RegExp(
    r'var teachers = \[(.*?)\];',
    dotAll: true
  );

  List<Match> courseBlocks = courseBlockPattern.allMatches(courseresponse3.data).toList();
  List<Match> teacherBlocks = teacherPattern.allMatches(courseresponse3.data).toList();
  List<String> rawTimeBlocks = courseresponse3.data.split(RegExp(r'activity\s*=\s*new\s*TaskActivity\(.*?\);', dotAll: true));


  List<List<String>> extractedTeachers = teacherBlocks.map((teacherMatch) {
    return extractTeacherNames(teacherMatch.group(1)!);
  }).toList();

  List<String> finalTeachers = List.filled(courseBlocks.length, "未知");

  for (int i = 0; i < courseBlocks.length; i++) {
    if (i < extractedTeachers.length) {
      finalTeachers[i] = extractedTeachers[i].join(', ');
    }
  }

  List<List<Map<String, int>>> extractedTimes = [];
  for (int i = 0; i < courseBlocks.length; i++) {
    if (i < rawTimeBlocks.length - 1) {
      String timeSection = rawTimeBlocks[i + 1].split(RegExp(r'var teachers =')).first;
      extractedTimes.add(extractCourseTimes(timeSection));
    } else {
      extractedTimes.add([]);
    }
  }

  for (int i = 0; i < courseBlocks.length; i++) {
    String courseName = courseBlocks[i].group(2)!;
    String courseLocation = courseBlocks[i].group(4)!;
    String weeksBinary = courseBlocks[i].group(5)!;

    List<Map<String, int>> times = extractedTimes[i];

    courseTableList.add(
      {
        'CourseName': courseName,
        'CourseLocation': courseLocation,
        'CourseWeeks': weeksBinary,
        'CourseTimes': times,
        'CourseTeacher': finalTeachers[i],
      }
    );
  }

  String courseTablepath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/courseTableStd/courseTable$semesterId.json';
  File courseTablefile = File(courseTablepath);
  courseTablefile.writeAsString(jsonEncode(courseTableList));

  //获取学期的开始时间、结束时间以及周数
    //校历数据目录
    Directory schoolCalendardirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/schoolCalendar');
    if(await schoolCalendardirectory.exists() == false){
      await schoolCalendardirectory.create();
    }

    //使用本地选中的 semetserid 来覆盖教务系统返回的 semetserid ，用于请求对应的校历
    semesterId = semestersData['y$currentYearInt'][currentTermInt -1]['id'].toString();
    
    //等待半秒，防止教务系统判定为过快点击
    if(getCourseTableCanceled) return;
    await Future.delayed(Duration(milliseconds: 500));

    if(getCourseTableCanceled) return;
    final schoolCalendarformData = FormData.fromMap({
      "semester.id": semesterId,
      '_': '1740564686472',
    });
    late Response schoolCalendarresponse;
    try{
      schoolCalendarresponse = await dio.post(
        'http://jwgl.snut.edu.cn/eams/schoolCalendar!search.action',
        options: Options(
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "PostmanRuntime/7.43.0",
          }
        ),
        data: schoolCalendarformData,
      );
    }catch (e){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('无法连接服务器0，请稍后再试',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }
    
    List schoolCalendarList = [];
    var schoolCalendardocument = parser.parse(schoolCalendarresponse.data);
    var contentCells = schoolCalendardocument.querySelectorAll("td.content");

      if (contentCells.length > 1) {
      String dateRange = contentCells[1].text.trim();
      RegExp regExp = RegExp(r"(\d{4}-\d{1,2}-\d{1,2})~(\d{4}-\d{1,2}-\d{1,2}) \((\d+)\)");
      var match = regExp.firstMatch(dateRange);
      
      if (match != null) {
        termStart = match.group(1)!;
        termEnd = match.group(2)!;
        termWeeks = int.parse(match.group(3)!);
        schoolCalendarList.add({
          'termStart': termStart,
          'termEnd': termEnd,
          'termWeeks': termWeeks,
        });
      }
    }
    String schoolCalendarpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/schoolCalendar/schoolCalendar$semesterId.json';
    File schoolCalendarfile = File(schoolCalendarpath);
    schoolCalendarfile.writeAsString(jsonEncode(schoolCalendarList));

    readSchoolCalendarInfo();
    if(mounted){
      setState(() {
        needRefresh = false;
      });
      Navigator.pop(context);
    }
  }

  List<String> extractTeacherNames(String teacherData) {
    RegExp singleTeacherPattern = RegExp(r'name:"([^"]+)"');
    Iterable<Match> matches = singleTeacherPattern.allMatches(teacherData);
    return matches.map((match) => match.group(1)!).toList();
  }

  List<Map<String, int>> extractCourseTimes(String timeData) {
    RegExp timePattern = RegExp(r'index\s*=\s*(\d+)\s*\*\s*unitCount\s*\+\s*(\d+);');
    Iterable<Match> matches = timePattern.allMatches(timeData);

    return matches.map((match) {
      return {
        "DayOfWeek": int.parse(match.group(1)!),
        "TimeOfDay": int.parse(match.group(2)!)
      };
    }).toList();
  }

  //展示每个课程的详细信息
  showCourseDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(10, 20, 10, 0),
          child: Center(
            child: ListView(
              children: [
                Center(
                  child: Text('课程详情',style: TextStyle(fontSize: GlobalVars.genericTextLarge),),
                ),
                SizedBox(height: 5,),
                Divider(height: 5,indent: 20,endIndent: 20,),
                ListTile(
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                  ),
                  title: Text(sheetcourseName,style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                  subtitle: Text('课程名称',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                ),
                Divider(height: 5,indent: 20,endIndent: 20,),
                ListTile(
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                  ),
                  title: Text("$sheetcourseWeeks 周",style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                  subtitle: Text('上课周次',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                ),
                Divider(height: 5,indent: 20,endIndent: 20,),
                ListTile(
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                  ),
                  title: Text(sheetcourseTeacher,style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                  subtitle: Text('课程教师',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                ),
                Divider(height: 5,indent: 20,endIndent: 20,),
                ListTile(
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                  ),
                  title: Text((sheetcourseLocation == '')? '无':sheetcourseLocation,style: TextStyle(fontSize: GlobalVars.listTileTitle),),
                  subtitle: Text('上课地点',style: TextStyle(fontSize: GlobalVars.listTileSubtitle),),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //获取本周每一天的日期
  getWeekDates() {
    weekDates = [];
    DateTime now = DateTime.now();
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    monday = monday.add(Duration(days: 7 * weekDiff));

    for (int i = 0; i < 7; i++) {
      DateTime day = monday.add(Duration(days: i));
      String month = day.month.toString().padLeft(2, '0');
      String date = day.day.toString().padLeft(2, '0');
      weekDates.add('$month-$date');
    }
    print(weekDiff);
    setState(() {});
  }

}