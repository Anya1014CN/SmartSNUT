import 'dart:convert';
import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:smartsnut/main.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:url_launcher/url_launcher.dart';

//用于存储要打开的URL
Uri url = Uri.parse("uri");

//定义登录按钮标题
String loginButtonTitle = '登录智慧陕理';

class LoginPage extends StatefulWidget{
  const LoginPage ({super.key});

  @override
  State<StatefulWidget> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage>{
  
  //创建 TextEditingController
  final textUsernameController = TextEditingController();
  final textPasswordController = TextEditingController();
  //登录状态
  bool loggingin = false;

  //读取设置并保存在变量中
  readSettings() async {
    String settingstpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/settings.json';
    File settingstfile = File(settingstpath);
    if(await settingstfile.exists()){
      GlobalVars.settingsTotal = jsonDecode(await settingstfile.readAsString());
      setState(() {
        GlobalVars.fontsizeint = GlobalVars.settingsTotal[0]['fontSize'];
        GlobalVars.darkModeint = GlobalVars.settingsTotal[0]['DarkMode'];
        GlobalVars.themeColor = GlobalVars.settingsTotal[0]['ThemeColor'];
      });
    }else{
      setState(() {
        GlobalVars.fontsizeint = 3;
        GlobalVars.darkModeint = 0;
        GlobalVars.themeColor = 1;
      });
    }
    setfontsize();
  }

  //设置字体大小
  setfontsize() {
    double changevalue = 0;
    if(GlobalVars.fontsizeint == 0){
      changevalue = -6;
      GlobalVars.fontSize_name = '极小';
    }
    if(GlobalVars.fontsizeint == 1){
      changevalue = -4;
      GlobalVars.fontSize_name = '超小';
    }
    if(GlobalVars.fontsizeint == 2){
      changevalue = -2;
      GlobalVars.fontSize_name = '较小';
    }
    if(GlobalVars.fontsizeint == 3){
      changevalue = 0;
      GlobalVars.fontSize_name = '适中';
    }
    if(GlobalVars.fontsizeint == 4){
      changevalue = 2;
      GlobalVars.fontSize_name = '较大';
    }
    if(GlobalVars.fontsizeint == 5){
      changevalue = 4;
      GlobalVars.fontSize_name = '超大';
    }
    if(GlobalVars.fontsizeint == 6){
      changevalue = 6;
      GlobalVars.fontSize_name = '极大';
    }

      //弹出对话框字体
      GlobalVars.alertdialog_title_title = DefaultfontSize.alertdialog_title_title_default + changevalue;
      GlobalVars.alertdialog_content_title = DefaultfontSize.alertdialog_content_title_default + changevalue;
      
      //主页底栏/侧栏字体
      GlobalVars.bottonbar_appname_title = DefaultfontSize.bottonbar_appname_title_default + changevalue;
      GlobalVars.bottonbar_selected_title = DefaultfontSize.bottonbar_selected_title_default + changevalue;
      GlobalVars.bottonbar_unselected_title = DefaultfontSize.bottonbar_unselected_title_default + changevalue;

      //闪屏页字体
      GlobalVars.smartsnut_text_title = DefaultfontSize.smartsnut_text_title_default + changevalue;

      //登录页字体
      GlobalVars.welcome_page_title = DefaultfontSize.welcome_page_title_default + changevalue;
      GlobalVars.login_hint_title = DefaultfontSize.login_hint_title_default + changevalue;
      GlobalVars.login_button_title = DefaultfontSize.login_button_title_default + changevalue;

      //首页字体
      GlobalVars.homegreeting_text_title = DefaultfontSize.homegreeting_text_title_default + changevalue;

      GlobalVars.homecoursetable_divider_title = DefaultfontSize.homecoursetable_divider_title_default + changevalue;
      GlobalVars.homecoursetable_datetime_title = DefaultfontSize.homecoursetable_datetime_title_default + changevalue;
      GlobalVars.homecoursetable_nocourse_title = DefaultfontSize.homecoursetable_nocourse_title_default + changevalue;
      GlobalVars.homecoursetable_coursename_title = DefaultfontSize.homecoursetable_coursename_title_default + changevalue;
      GlobalVars.homecoursetable_coursedetail_title = DefaultfontSize.homecoursetable_coursedetail_title_default + changevalue;
      GlobalVars.homecoursetable_morehint_title = DefaultfontSize.homecoursetable_morehint_title_default + changevalue;

      GlobalVars.frefunc_divider_title = DefaultfontSize.frefunc_divider_title_default + changevalue;
      //按钮字体在 应用页字体中//

      GlobalVars.tzgg_divider_title = DefaultfontSize.tzgg_divider_title_default + changevalue;
      GlobalVars.tzgg_newstitle_title = DefaultfontSize.tzgg_newstitle_title_default + changevalue;
      GlobalVars.tzgg_newsdate_title = DefaultfontSize.tzgg_newsdate_title_default + changevalue;

      //应用页字体
      GlobalVars.apppagegreeting_text_title = DefaultfontSize.apppagegreeting_text_title_default + changevalue;
      GlobalVars.jwgl_divider_title = DefaultfontSize.jwgl_divider_title_default + changevalue;
      GlobalVars.coursetable_button_title = DefaultfontSize.coursetable_button_title_default + changevalue;
      GlobalVars.stddetail_button_title = DefaultfontSize.stddetail_button_title_default + changevalue;
      GlobalVars.stdexam_button_title = DefaultfontSize.stdexam_button_title_default + changevalue;
      GlobalVars.stdgrade_button_title = DefaultfontSize.stdgrade_button_title_default + changevalue;

      GlobalVars.hqb_divider_title = DefaultfontSize.hqb_divider_title_default + changevalue;
      GlobalVars.networkque_button_title = DefaultfontSize.networkque_button_title_default + changevalue;
      GlobalVars.emque_button_title = DefaultfontSize.emque_button_title_default + changevalue;


      GlobalVars.external_divider_title = DefaultfontSize.external_divider_title_default + changevalue;
      GlobalVars.library_button_title = DefaultfontSize.library_button_title_default + changevalue;
      GlobalVars.face_button_title = DefaultfontSize.face_button_title_default + changevalue;
      GlobalVars.webvpn_button_title = DefaultfontSize.webvpn_button_title_default + changevalue;
      GlobalVars.newhall_button_title = DefaultfontSize.newhall_button_title_default + changevalue;

      //我的页字体
      GlobalVars.person_text_title = DefaultfontSize.person_text_title_default + changevalue;
      GlobalVars.personday_text_title = DefaultfontSize.personday_text_title_default + changevalue;

      GlobalVars.hint_text_title = DefaultfontSize.hint_text_title_default + changevalue;
      
      GlobalVars.embind_button_title = DefaultfontSize.embind_button_title_default + changevalue;
      GlobalVars.settings_button_title = DefaultfontSize.settings_button_title_default + changevalue;
      GlobalVars.guide_button_title = DefaultfontSize.guide_button_title_default + changevalue;
      GlobalVars.logout_button_title = DefaultfontSize.logout_button_title_default + changevalue;

      //课表页字体
      GlobalVars.coursetable_page_title = DefaultfontSize.coursetable_page_title_default + changevalue;
      GlobalVars.refreshcoursetable_button_title = DefaultfontSize.refreshcoursetable_button_title_default + changevalue;
      GlobalVars.coursetableswitchterm_title_title = DefaultfontSize.coursetableswitchterm_title_title_default + changevalue;
      GlobalVars.coursetableswitchterm_year_title = DefaultfontSize.coursetableswitchterm_year_title_default + changevalue;
      GlobalVars.coursetableswitchterm_term_title = DefaultfontSize.coursetableswitchterm_term_title_default + changevalue;
      GlobalVars.coursetableweek_text_title = DefaultfontSize.coursetableweek_text_title_default + changevalue;
      GlobalVars.nocoursetable_hint_title = DefaultfontSize.nocoursetable_hint_title_default + changevalue;
      GlobalVars.nocoursetable_hint_subtitle = DefaultfontSize.nocoursetable_hint_subtitle_default + changevalue;
      GlobalVars.coursetable_tablehead_title = DefaultfontSize.coursetable_tablehead_title_default + changevalue;
      GlobalVars.coursetable_coursename_title = DefaultfontSize.coursetable_coursename_title_default + changevalue;
      GlobalVars.coursetable_courselocation_title = DefaultfontSize.coursetable_courselocation_title_default + changevalue;
      GlobalVars.coursetable_coursedetailsheet_title = DefaultfontSize.coursetable_coursedetailsheet_title_default + changevalue;
      GlobalVars.coursetable_coursedetailsheet_coursecontent  = DefaultfontSize.coursetable_coursedetailsheet_coursecontent_default  + changevalue;
      GlobalVars.coursetable_coursedetailsheet_coursetitle  = DefaultfontSize.coursetable_coursedetailsheet_coursetitle_default  + changevalue;

      //学籍信息页字体
      GlobalVars.stddetail_page_title = DefaultfontSize.stddetail_page_title_default + changevalue;
      GlobalVars.stddetail_title_title = DefaultfontSize.stddetail_title_title_default + changevalue;
      GlobalVars.stddetail_content_title = DefaultfontSize.stddetail_content_title_default + changevalue;

      //考试页字体
      GlobalVars.stdexam_page_title = DefaultfontSize.stdexam_page_title_default + changevalue;
      GlobalVars.refreshstdexam_button_title = DefaultfontSize.refreshstdexam_button_title_default + changevalue;
      GlobalVars.stdexamswitchterm_title_title = DefaultfontSize.stdexamswitchterm_title_title_default + changevalue;
      GlobalVars.stdexamswitchterm_year_title = DefaultfontSize.stdexamswitchterm_year_title_default + changevalue;
      GlobalVars.stdexamswitchterm_term_title = DefaultfontSize.stdexamswitchterm_term_title_default + changevalue;
      GlobalVars.stdexam_type_title = DefaultfontSize.stdexam_type_title_default + changevalue;
      GlobalVars.nostdexam_hint_title = DefaultfontSize.nostdexam_hint_title_default + changevalue;
      GlobalVars.nostdexam_hint_subtitle = DefaultfontSize.nostdexam_hint_subtitle_default + changevalue;
      GlobalVars.stdexam_courseexamname_title = DefaultfontSize.stdexam_courseexamname_title_default + changevalue;
      GlobalVars.stdexam_courseexamdate_title = DefaultfontSize.stdexam_courseexamdate_title_default + changevalue;
      GlobalVars.stdexam_courseexamtime_title = DefaultfontSize.stdexam_courseexamtime_title_default + changevalue;
      GlobalVars.stdexam_courseexamseatno_title = DefaultfontSize.stdexam_courseexamseatno_title_default + changevalue;
      GlobalVars.stdexam_courseexamtype_title = DefaultfontSize.stdexam_courseexamtype_title_default + changevalue;

      //成绩页字体
      GlobalVars.stdgrade_page_title = DefaultfontSize.stdgrade_page_title_default + changevalue;
      GlobalVars.refreshstdgrade_button_title = DefaultfontSize.refreshstdgrade_button_title_default + changevalue;
      GlobalVars.stdgradeswitchterm_title_title = DefaultfontSize.stdgradeswitchterm_title_title_default + changevalue;
      GlobalVars.stdgradeswitchterm_year_title = DefaultfontSize.stdgradeswitchterm_year_title_default + changevalue;
      GlobalVars.stdgradeswitchterm_term_title = DefaultfontSize.stdgradeswitchterm_term_title_default + changevalue;
      GlobalVars.nostdgrade_hint_title = DefaultfontSize.nostdgrade_hint_title_default + changevalue;
      GlobalVars.nostdgrade_hint_subtitle = DefaultfontSize.nostdgrade_hint_subtitle_default + changevalue;
      GlobalVars.stdgrade_coursename_title = DefaultfontSize.stdgrade_coursename_title_default + changevalue;
      GlobalVars.stdgrade_coursecredit_title = DefaultfontSize.stdgrade_coursecredit_title_default + changevalue;
      GlobalVars.stdgrade_coursegradetotal_title = DefaultfontSize.stdgrade_coursegradetotal_title_default + changevalue;
      GlobalVars.stdgrade_coursegradefinal_title = DefaultfontSize.stdgrade_coursegradefinal_title_default + changevalue;
      GlobalVars.stdgrade_coursegradegpa_title = DefaultfontSize.stdgrade_coursegradegpa_title_default + changevalue;
      GlobalVars.stdgrade_coursetype_title = DefaultfontSize.stdgrade_coursetype_title_default + changevalue;

      //绩点计算器页字体
      GlobalVars.gpacalculator_page_title = DefaultfontSize.gpacalculator_page_title_default + changevalue;
      GlobalVars.gpacalculator_GPAtitle_title = DefaultfontSize.gpacalculator_GPAtitle_title_default + changevalue;
      GlobalVars.gpacalculator_GPAcontent_title = DefaultfontSize.gpacalculator_GPAcontent_title_default + changevalue;
      GlobalVars.gpacalculator_coursename_title = DefaultfontSize.gpacalculator_coursename_title_default + changevalue;
      GlobalVars.gpacalculator_coursename_content = DefaultfontSize.gpacalculator_coursename_content_default + changevalue;

      //网费查询页字体
      GlobalVars.networkquery_page_title = DefaultfontSize.networkquery_page_title_default + changevalue;
      GlobalVars.networkquery_button_title = DefaultfontSize.networkquery_button_title_default + changevalue;
      GlobalVars.networktopup_button_title = DefaultfontSize.networktopup_button_title_default + changevalue;
      GlobalVars.networkdetail_account_title = DefaultfontSize.networkdetail_account_title_default + changevalue;
      GlobalVars.networkdetail_realname_title = DefaultfontSize.networkdetail_realname_title_default + changevalue;
      GlobalVars.networkdetail_balance_title = DefaultfontSize.networkdetail_balance_title_default + changevalue;
      GlobalVars.networkdetail_state_title = DefaultfontSize.networkdetail_state_title_default + changevalue;
      GlobalVars.networkdetail_expire_title = DefaultfontSize.networkdetail_expire_title_default + changevalue;
      GlobalVars.networkquery_hint_title = DefaultfontSize.networkquery_hint_title_default + changevalue;
      GlobalVars.networkquery_hint_subtitle = DefaultfontSize.networkquery_hint_subtitle_default + changevalue;

      //电费查询页字体
      GlobalVars.emquery_page_title = DefaultfontSize.emquery_page_title_default + changevalue;
      GlobalVars.emdetail_emid_title = DefaultfontSize.emdetail_emid_title_default + changevalue;
      GlobalVars.emdetail_emleft_title = DefaultfontSize.emdetail_emleft_title_default + changevalue;
      GlobalVars.emdetail_emtotal_title = DefaultfontSize.emdetail_emtotal_title_default + changevalue;
      GlobalVars.emdetail_emstate_title = DefaultfontSize.emdetail_emstate_title_default + changevalue;
      GlobalVars.emdetail_emaddress_title = DefaultfontSize.emdetail_emaddress_title_default + changevalue;
      GlobalVars.emquery_nonetwork_title = DefaultfontSize.emquery_nonetwork_title_default + changevalue;
      GlobalVars.emquery_querying_title = DefaultfontSize.emquery_querying_title_default + changevalue;

      //电费账号绑定页字体
      GlobalVars.embind_page_title = DefaultfontSize.embind_page_title_default + changevalue;
      GlobalVars.embind_wechatname_title = DefaultfontSize.embind_wechatname_title_default + changevalue;
      GlobalVars.embind_emnum_title = DefaultfontSize.embind_emnum_title_default + changevalue;
      GlobalVars.embindrefresh_button_title = DefaultfontSize.embindrefresh_button_title_default + changevalue;
      GlobalVars.embindunbind_button_title = DefaultfontSize.embindunbind_button_title_default + changevalue;
      GlobalVars.embind_binding_title = DefaultfontSize.embind_binding_title_default + changevalue;
      GlobalVars.embind_hint_title = DefaultfontSize.embind_hint_title_default + changevalue;
      GlobalVars.embind_hint_subtitle = DefaultfontSize.embind_hint_subtitle_default + changevalue;

      //应用设置页字体
      GlobalVars.settings_page_title = DefaultfontSize.settings_page_title_default + changevalue;
      
      GlobalVars.generalsettings_divider_title = DefaultfontSize.generalsettings_divider_title_default + changevalue;
      GlobalVars.generalsettings_fontsize_title = DefaultfontSize.generalsettings_fontsize_title_default + changevalue;
      GlobalVars.generalsettings_fontsize_subtitle = DefaultfontSize.generalsettings_fontsize_subtitle_default + changevalue;
      GlobalVars.generalsettings_themecolor_title = DefaultfontSize.generalsettings_themecolor_title_default + changevalue;
      GlobalVars.generalsettings_themecolor_subtitle = DefaultfontSize.generalsettings_themecolor_subtitle_default + changevalue;
      GlobalVars.generalsettings_darkmode_title = DefaultfontSize.generalsettings_darkmode_title_default + changevalue;
      GlobalVars.generalsettings_darkmode_subtitle = DefaultfontSize.generalsettings_darkmode_subtitle_default + changevalue;
      
      GlobalVars.accountsettings_divider_title = DefaultfontSize.accountsettings_divider_title_default + changevalue;
      GlobalVars.accountsettings_emaccount_title = DefaultfontSize.accountsettings_emaccount_title_default + changevalue;
      GlobalVars.accountsettings_emaccount_subtitle = DefaultfontSize.accountsettings_emaccount_subtitle_default + changevalue;
      GlobalVars.accountsettings_authserveraccount_title = DefaultfontSize.accountsettings_authserveraccount_title_default + changevalue;
      GlobalVars.accountsettings_authserveraccount_subtitle = DefaultfontSize.accountsettings_authserveraccount_subtitle_default + changevalue;

      GlobalVars.aboutsnutsettings_divider_title = DefaultfontSize.aboutsnutsettings_divider_title_default + changevalue;
      GlobalVars.aboutsnutsettings_currentversion_title = DefaultfontSize.aboutsnutsettings_divider_title_default + changevalue;
      
      GlobalVars.disclamier_divider_title = DefaultfontSize.disclamier_divider_title_default + changevalue;
      GlobalVars.disclamier_title_title = DefaultfontSize.disclamier_title_title_default + changevalue;
      
      GlobalVars.lincense_divider_title = DefaultfontSize.lincense_divider_title_default + changevalue;
      GlobalVars.lincense_name_title = DefaultfontSize.lincense_name_title_default + changevalue;
      GlobalVars.lincense_describ_title = DefaultfontSize.lincense_describ_title_default + changevalue;
  }

  @override
  void initState() {
    readSettings();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      body: ListView(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(15, 10, 15, 30),
            child: Row(
              children: [
                Image(image: Theme.of(context).brightness == Brightness.light? AssetImage('assets/icons/lighttheme/hand.png'):AssetImage('assets/icons/darktheme/hand.png'),height: 40,),
                SizedBox(width: 10,),
                Text('欢迎',style: TextStyle(fontSize: GlobalVars.welcome_page_title),)
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('登录智慧陕理',style: TextStyle(fontSize: GlobalVars.login_hint_title,color: Theme.of(context).colorScheme.primary),),
                Divider(height: 5,indent: 20,endIndent: 20,color: Theme.of(context).colorScheme.primary,),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(15, 0, 15, 10),
            child: Card(
              shadowColor: Theme.of(context).colorScheme.onPrimary,
              color: Theme.of(context).colorScheme.surfaceDim,
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(21),
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Center(child: Text('请使用陕西理工大学统一身份认证账号登录'),),
                    SizedBox(height: 15,),
                    TextField(
                      controller: textUsernameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '用户名',
                        hintText: '请输入您的学号/工号',
                        filled: false
                      ),
                    ),
                    SizedBox(height: 10,),
                    TextField(
                      controller: textPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '密码',
                        hintText: '请输入您的密码',
                        filled: false
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(0, 60, 0, 0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () {
                      if (textUsernameController.text == '' ) {
                      showDialog(
                        context: context, 
                        builder: (BuildContext context)=>AlertDialog(
                          title: Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
                          content: Text('用户名不能为空，请输入您的学号/工号',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
                          actions: [TextButton(onPressed:  () => Navigator.pop(context, 'Cancel'), child: Text('确认'))],
                        ));
                      return;
                      }if (textPasswordController.text == '') {
                        showDialog(
                        context: context, 
                        builder: (BuildContext context)=>AlertDialog(
                          title: Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
                          content: Text('密码不能为空，请输入您的密码',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
                          actions: [TextButton(onPressed:  () => Navigator.pop(context, 'Cancel'), child: Text('确认'))],
                        ));
                        return;
                      }else{
                        loggingin ? null : loginjwgl();
                      }
                    },
                    child: loggingin ? FittedBox(
                      child: Row(
                        children: [
                          CircularProgressIndicator(color: Colors.white,),
                          SizedBox(width: 10,),
                          Text('\n$loginButtonTitle\n')
                        ],
                      ),
                    ):FittedBox(
                      child: Row(
                        children: [
                          Icon(Icons.login),
                          SizedBox(width: 10,),
                          Text('登录智慧陕理',style: TextStyle(fontSize: GlobalVars.login_button_title),)
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20,),
                  FilledButton(
                    onPressed: () {
                      url = Uri.parse('https://authserver.snut.edu.cn/retrieve-password/retrievePassword/index.html');
                      launchURL();
                    },
                    child: FittedBox(
                      child: Row(
                        children: [
                          Icon(Icons.question_mark),
                          SizedBox(width: 10,),
                          Text('忘记密码？',style: TextStyle(fontSize: GlobalVars.login_button_title),)
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ),
          ),
        ],
      ),
    );
  }
  //登录教务系统
  loginjwgl() async {
    if(mounted){
      setState(() {
        loggingin = true;
        loginButtonTitle = '正在登录教务系统';
      });
    }

    //数据目录
    Directory smartSNUTdirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT');
    if(await smartSNUTdirectory.exists() == false){
      await smartSNUTdirectory.create();
    }

    //存储用户名、密码
    String userName = textUsernameController.text;
    String password = textPasswordController.text;

    String realName = '';

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
        clearTempLogindata();
        setState(() {
          loggingin = false;
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
    var combinedpassword = utf8.encode('$passwordhash-$password');
    var digest = sha1.convert(combinedpassword);
    encryptedpassword = digest.toString();

    //等待一秒，防止教务系统判定为过快点击
    await Future.delayed(Duration(seconds: 1));

    //第二次请求，尝试登录
    final formData = FormData.fromMap({
      "username": userName,
      "password": encryptedpassword,
      "session_locale": "zh_CN"
    });


  var response2;
  try{
        response2 = await dio.post(
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
    }catch(e){
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
        clearTempLogindata();
        setState(() {
          loggingin = false;
        });
      }
      return;
    }

    String response2string = response2.data.toString();
    if(response2string.contains('账户不存在')){
    if(mounted){
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          scrollable: true,
          title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
          content: Text('登录失败，账户不存在',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      clearTempLogindata();
      setState(() {
        loggingin = false;
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
          content: Text('登录失败，密码错误',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      clearTempLogindata();
      setState(() {
        loggingin = false;
      });
    }
    return;
    }

    if(mounted){
      setState(() {
        loginButtonTitle = '正在获取个人信息';
      });
    }

    //登录成功，获取个人信息
    List<Map<String, String>> stdAccount = [];
    
    Directory datadirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver');
    if(await datadirectory.exists() == false){
      await datadirectory.create();
    }

    //真实姓名
    var myactionresponse;
    try{
      myactionresponse = await dio.get('http://jwgl.snut.edu.cn/eams/security/my.action');
    }catch(e){
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
        clearTempLogindata();
        setState(() {
          loggingin = false;
        });
      }
      return;
    }
    RegExp regExpRealname = RegExp(r'title="(.*?)"', caseSensitive: false);
    Match? matchRealname = regExpRealname.firstMatch(myactionresponse.data);
    if(matchRealname != null){
      realName = matchRealname.group(1).toString();
    }

    //保存上述信息
    stdAccount.add({
      'UserRealName': realName,
      'UserName': userName,
      'PassWord': password
    });
    String stdAccountJson = jsonEncode(stdAccount);
    String stdAccountpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdAccount.json';
    File stdAccountfile = File(stdAccountpath);
    stdAccountfile.writeAsString(stdAccountJson);

    if(mounted){
      setState(() {
        loginButtonTitle = '正在获取学籍信息';
      });
    }

  //学籍信息保存
  var stdDetailresponse;
  try{
    stdDetailresponse = await dio.get('http://jwgl.snut.edu.cn/eams/stdDetail.action');
  }catch(e){
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
      clearTempLogindata();
      setState(() {
        loggingin = false;
      });
    }
    return;
  }
  // 解析 HTML
  var document = html_parser.parse(stdDetailresponse.data);
  List<html_dom.Element> tableRows = document.querySelectorAll("table#studentInfoTb tr");

  // 存储解析后的数据
  Map<String, String> studentInfo = {};

  for (var row in tableRows) {
    List<html_dom.Element> columns = row.querySelectorAll("td"); 

    for (int i = 0; i < columns.length - 1; i += 2) {
      String key = columns[i].text.trim();
      String value = columns[i + 1].text.trim();

      if (key.isNotEmpty) {
        studentInfo[key] = value;
      }
    }
  }

  // 转换为 JSON 并保存到本地
  String jsonOutput = jsonEncode(studentInfo);
  String stdDetailpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdDetail.json';
  File stdDetailfile = File(stdDetailpath);
  stdDetailfile.writeAsString(jsonOutput);

    if(mounted){
      setState(() {
        loginButtonTitle = '正在获取最新课表';
      });
    }

  //课表数据目录
  Directory courseTableStddirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/courseTableStd');
  if(await courseTableStddirectory.exists() == false){
    await courseTableStddirectory.create();
  }

  
    //等待半秒，防止教务系统判定为过快点击
    await Future.delayed(Duration(milliseconds: 500));

    //请求课表初始信息
    var courseresponse1;
    try{
      courseresponse1 = await dio.get('http://jwgl.snut.edu.cn/eams/courseTableForStd.action');
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
        clearTempLogindata();
        setState(() {
          loggingin = false;
        });
      }
      return;
    }
    //提取相关数据
    String semesterId = '';
    String tagId = '';
    String idsMe = '';
    String idsClass = '';

    RegExp semesterExp = RegExp(r'semester\.id=(\d+)');
    Match? semesteridmatch = semesterExp.firstMatch(courseresponse1.headers['Set-Cookie'][0].toString());
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
      idsClass = idsmatch.elementAt(1).group(1)!;
    }

    //获取所有学期的 semester.id，学年名称，学期名称
    final courseTableformData = FormData.fromMap({
      "tagId": 'semesterBar${tagId}Semester',
      "dataType": 'semesterCalendar',
      "value": semesterId.toString(),
      "empty": 'false'
    });
    var courseresponse2;
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
        clearTempLogindata();
        setState(() {
          loggingin = false;
        });
      }
      return;
    }
    
    String rawdata = courseresponse2.data.toString();
    var semesters;

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
  
  //成绩数据目录
  Directory stdGradesdirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdGrades');
  if(await stdGradesdirectory.exists() == false){
    await stdGradesdirectory.create();
  }
  
  //考试数据目录
  Directory stdExamdirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/stdExam');
  if(await stdExamdirectory.exists() == false){
    await stdExamdirectory.create();
  }

  //电费数据目录
  Directory emdatadirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata');
  if(await emdatadirectory.exists() == false){
    await emdatadirectory.create();
  }

  //绩点计算器数据目录
  Directory gpaCalculatordirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/GPACalculator');
  if(await gpaCalculatordirectory.exists() == false){
    await gpaCalculatordirectory.create();
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
       content: Text('登录成功'),
    ),
  );

  //登录流程完成，刷新用户信息，创建一个占位文件
  readStdAccount();
  String loginsuccesspath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/LoginSuccess';
  File loginsuccessfile = File(loginsuccesspath);
  loginsuccessfile.writeAsString('');
  

  Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext ctx) => HomePage()));
  }
  
  //读取用户信息并保存在变量中
  readStdAccount() async {
    String stdAccountpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdAccount.json';
    File stdAccountfile = File(stdAccountpath);
    GlobalVars.stdAccount = jsonDecode(await stdAccountfile.readAsString());
    if(mounted){
      setState(() {
        GlobalVars.realName = GlobalVars.stdAccount[0]['UserRealName'];
        GlobalVars.userName = GlobalVars.stdAccount[0]['UserName'];
        GlobalVars.passWord = GlobalVars.stdAccount[0]['PassWord'];
      });
    }
    String stdDetailpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/authserver/stdDetail.json';
    File stdDetailfile = File(stdDetailpath);
    String stdDetailString = await stdDetailfile.readAsString();
    Map<String, dynamic> jsonData = json.decode(stdDetailString);
    GlobalVars.stdDetail = jsonData.map((key, value) => MapEntry(key, value.toString()));
    if(mounted){
      setState(() {
        GlobalVars.enrollTime = GlobalVars.stdDetail['入校时间：']!;
        GlobalVars.graduationTime = GlobalVars.stdDetail['毕业时间：']!;
      });
    }
    emBindCheck();
  }

  //判断用户是否绑定电表账号
  emBindCheck() async {
    String openidtxtpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/embinddata/wechatUserOpenid.txt';
    File openidtxtfile = File(openidtxtpath);
    if(await openidtxtfile.exists() == true){
      if(mounted){
        setState(() {
          GlobalVars.emBinded = true;
        });
      }else{
        setState(() {
          GlobalVars.emBinded = false;
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
        title: Text('提示',style: TextStyle(fontSize: GlobalVars.alertdialog_title_title)),
        content: Text('是否要使用系统默认浏览器打开外部链接？\n\n$url',style: TextStyle(fontSize: GlobalVars.alertdialog_content_title)),
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

  //清空数据文件夹（登录未完全成功时调用，防止残缺数据影响下次登录）
  void clearTempLogindata() async {
    //清空并重新创建数据目录
    Directory smartSNUTdirectory = Directory('${(await getApplicationDocumentsDirectory()).path}/SmartSNUT');
    if(await smartSNUTdirectory.exists() == true){
      await smartSNUTdirectory.delete(recursive: true);
      await smartSNUTdirectory.create();
    }
  }
}