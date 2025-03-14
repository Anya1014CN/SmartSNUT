class GlobalVars {
  //用户数据
  static List stdAccount = [];
  static String realName = '';
  static String userName = '';
  static String passWord = '';
  static Map<String, String> stdDetail = {};
  var documentsDirectory = "";
  static String enrollTime = '1900-01-01';
  static String graduationTime = '1900-01-01';

  //判断用户是否绑定电表账号
  static bool emBinded = false;

  //当前日期
  static var today = DateTime.now();
  static int month = DateTime.now().month;
  static int day = DateTime.now().day;
  static int hour = DateTime.now().hour;
  static String weekDay = '';

  //用于存储不同时间段的问候语
  static String greeting = '';
  static String hint = '';

  //用户设置相关
  static List settingsTotal = [];
  static int fontsizeint = 1;//0 - 小；1 - 中；2 - 大
  static String fontSize_name = '适中';
  static int darkModeint = 0;//0 - 跟随系统；1 - 始终开启；2 - 始终关闭
  static int themeColor = 0;//对应八种颜色

  //字体大小相关
  //弹出对话框字体
  static double alertdialog_title_title = 20;
  static double alertdialog_content_title = 14;

  //主页底栏/侧栏字体
  static double bottonbar_appname_title = 20;
  static double bottonbar_selected_title = 18;
  static double bottonbar_unselected_title = 14;

  //闪屏页字体
  static double smartsnut_text_title = 30;

  //登录页字体
  static double welcome_page_title = 40;
  static double login_hint_title = 15;
  static double login_button_title = 14;

  //首页字体
  static double homegreeting_text_title = 35;

  static double homecoursetable_divider_title = 15;
  static double homecoursetable_datetime_title = 20;
  static double homecoursetable_nocourse_title = 20;
  static double homecoursetable_coursename_title = 16;
  static double homecoursetable_coursedetail_title = 14;
  static double homecoursetable_morehint_title = 14;

  static double frefunc_divider_title = 15;
  //按钮字体在 应用页字体中//

  static double tzgg_divider_title = 15;
  static double tzgg_newstitle_title = 16;
  static double tzgg_newsdate_title = 14;

  //应用页字体
  static double apppagegreeting_text_title = 35;

  static double jwgl_divider_title = 15;
  static double coursetable_button_title = 16;
  static double stddetail_button_title = 16;
  static double stdexam_button_title = 16;
  static double stdgrade_button_title = 16;

  static double hqb_divider_title = 15;
  static double networkque_button_title = 16;
  static double emque_button_title = 16;


  static double external_divider_title = 15;
  static double library_button_title = 16;
  static double face_button_title = 16;
  static double webvpn_button_title = 16;
  static double newhall_button_title = 16;

  //我的页字体
  static double person_text_title = 35;
  static double personday_text_title = 40;

  static double hint_text_title = 25;
  
  static double embind_button_title = 16;
  static double settings_button_title = 16;
  static double guide_button_title = 16;
  static double logout_button_title = 16;

  //课表页字体
  static double coursetable_page_title = 20;
  static double refreshcoursetable_button_title = 16;
  static double coursetableswitchterm_title_title = 20;
  static double coursetableswitchterm_year_title = 16;
  static double coursetableswitchterm_term_title = 16;
  static double coursetableweek_text_title = 16;
  static double nocoursetable_hint_title = 16;
  static double nocoursetable_hint_subtitle = 14;
  static double coursetable_tablehead_title = 14;
  static double coursetable_coursename_title = 14;
  static double coursetable_courselocation_title = 12;
  static double coursetable_coursedetailsheet_title = 26;
  static double coursetable_coursedetailsheet_coursecontent = 22;
  static double coursetable_coursedetailsheet_coursetitle = 18;

  //学籍信息页字体
  static double stddetail_page_title = 40;
  static double stddetail_title_title = 14;
  static double stddetail_content_title = 14;

  //考试页字体
  static double stdexam_page_title = 40;
  static double refreshstdexam_button_title = 16;
  static double stdexamswitchterm_title_title = 20;
  static double stdexamswitchterm_year_title = 16;
  static double stdexamswitchterm_term_title = 16;
  static double stdexam_type_title = 16;
  static double nostdexam_hint_title = 16;
  static double nostdexam_hint_subtitle = 14;
  static double stdexam_courseexamname_title = 16;
  static double stdexam_courseexamdate_title = 16;
  static double stdexam_courseexamtime_title = 16;
  static double stdexam_courseexamseatno_title = 16;
  static double stdexam_courseexamtype_title = 16;

  //成绩页字体
  static double stdgrade_page_title = 40;
  static double refreshstdgrade_button_title = 16;
  static double stdgradeswitchterm_title_title = 20;
  static double stdgradeswitchterm_year_title = 16;
  static double stdgradeswitchterm_term_title = 16;
  static double nostdgrade_hint_title = 16;
  static double nostdgrade_hint_subtitle = 14;
  static double stdgrade_coursename_title = 16;
  static double stdgrade_coursecredit_title = 16;
  static double stdgrade_coursegradetotal_title = 16;
  static double stdgrade_coursegradefinal_title = 16;
  static double stdgrade_coursegradegpa_title = 16;
  static double stdgrade_coursetype_title = 16;

  //网费查询页字体
  static double networkquery_page_title = 40;
  static double networkquery_button_title = 16;
  static double networktopup_button_title = 16;
  static double networkdetail_account_title = 20;
  static double networkdetail_realname_title = 20;
  static double networkdetail_balance_title = 20;
  static double networkdetail_state_title = 20;
  static double networkdetail_expire_title = 20;
  static double networkquery_hint_title = 20;
  static double networkquery_hint_subtitle = 16;

  //电费查询页字体
  static double emquery_page_title = 40;
  static double emdetail_emid_title = 18;
  static double emdetail_emleft_title = 18;
  static double emdetail_emtotal_title = 18;
  static double emdetail_emstate_title = 18;
  static double emdetail_emaddress_title = 18;
  static double emquery_nonetwork_title = 18;
  static double emquery_querying_title = 18;

  //电费账号绑定页字体
  static double embind_page_title = 40;
  static double embind_wechatname_title = 20;
  static double embind_emnum_title = 18;
  static double embindrefresh_button_title = 16;
  static double embindunbind_button_title = 16;
  static double embind_binding_title = 20;
  static double embind_hint_title = 20;
  static double embind_hint_subtitle = 16;

  //教程页字体
  static double guide_page_title = 20;
  static double guide_title_title = 18;
  static double guide_content_title = 16;

  //应用设置页字体
  static double settings_page_title = 40;
  
  static double generalsettings_divider_title = 15;
  static double generalsettings_fontsize_title = 16;
  static double generalsettings_fontsize_subtitle = 14;
  static double generalsettings_themecolor_title = 16;
  static double generalsettings_themecolor_subtitle = 14;
  static double generalsettings_darkmode_title = 16;
  static double generalsettings_darkmode_subtitle = 14;
  
  static double accountsettings_divider_title = 15;
  static double accountsettings_emaccount_title = 16;
  static double accountsettings_emaccount_subtitle = 14;
  static double accountsettings_authserveraccount_title = 16;
  static double accountsettings_authserveraccount_subtitle = 14;
  
  static double disclamier_divider_title = 15;
  static double disclamier_title_title = 14;
  
  static double lincense_divider_title = 15;
  static double lincense_name_title = 18;
  static double lincense_describ_title = 14;
  
}

//用于存储所有字体的“适中”的大小
class DefaultfontSize{
  
  //弹出对话框字体
  static double alertdialog_title_title_default = 20;
  static double alertdialog_content_title_default = 14;

  //主页底栏/侧栏字体
  static double bottonbar_appname_title_default = 20;
  static double bottonbar_selected_title_default = 18;
  static double bottonbar_unselected_title_default = 14;

  //闪屏页字体
  static double smartsnut_text_title_default = 30;

  //登录页字体
  static double welcome_page_title_default = 40;
  static double login_hint_title_default = 15;
  static double login_button_title_default = 14;

  //首页字体
  static double homegreeting_text_title_default = 35;

  static double homecoursetable_divider_title_default = 15;
  static double homecoursetable_datetime_title_default = 20;
  static double homecoursetable_nocourse_title_default = 20;
  static double homecoursetable_coursename_title_default = 16;
  static double homecoursetable_coursedetail_title_default = 14;
  static double homecoursetable_morehint_title_default = 14;

  static double frefunc_divider_title_default = 15;
  //按钮字体在 应用页字体中//

  static double tzgg_divider_title_default = 15;
  static double tzgg_newstitle_title_default = 16;
  static double tzgg_newsdate_title_default = 14;

  //应用页字体
  static double apppagegreeting_text_title_default = 35;

  static double jwgl_divider_title_default = 15;
  static double coursetable_button_title_default = 16;
  static double stddetail_button_title_default = 16;
  static double stdexam_button_title_default = 16;
  static double stdgrade_button_title_default = 16;

  static double hqb_divider_title_default = 15;
  static double networkque_button_title_default = 16;
  static double emque_button_title_default = 16;


  static double external_divider_title_default = 15;
  static double library_button_title_default = 16;
  static double face_button_title_default = 16;
  static double webvpn_button_title_default = 16;
  static double newhall_button_title_default = 16;

  //我的页字体
  static double person_text_title_default = 35;
  static double personday_text_title_default = 40;

  static double hint_text_title_default = 25;
  
  static double embind_button_title_default = 16;
  static double settings_button_title_default = 16;
  static double guide_button_title_default = 16;
  static double logout_button_title_default = 16;

  //课表页字体
  static double coursetable_page_title_default = 20;
  static double refreshcoursetable_button_title_default = 16;
  static double coursetableswitchterm_title_title_default = 20;
  static double coursetableswitchterm_year_title_default = 16;
  static double coursetableswitchterm_term_title_default = 16;
  static double coursetableweek_text_title_default = 16;
  static double nocoursetable_hint_title_default = 16;
  static double nocoursetable_hint_subtitle_default= 14;
  static double coursetable_tablehead_title_default = 14;
  static double coursetable_coursename_title_default = 14;
  static double coursetable_courselocation_title_default = 12;
  static double coursetable_coursedetailsheet_title_default = 26;
  static double coursetable_coursedetailsheet_coursecontent_default = 22;
  static double coursetable_coursedetailsheet_coursetitle_default = 18;

  //学籍信息页字体
  static double stddetail_page_title_default = 40;
  static double stddetail_title_title_default = 14;
  static double stddetail_content_title_default = 14;

  //考试页字体
  static double stdexam_page_title_default = 40;
  static double refreshstdexam_button_title_default = 16;
  static double stdexamswitchterm_title_title_default = 20;
  static double stdexamswitchterm_year_title_default = 16;
  static double stdexamswitchterm_term_title_default = 16;
  static double stdexam_type_title_default = 16;
  static double nostdexam_hint_title_default = 16;
  static double nostdexam_hint_subtitle_default= 14;
  static double stdexam_courseexamname_title_default = 16;
  static double stdexam_courseexamdate_title_default = 16;
  static double stdexam_courseexamtime_title_default = 16;
  static double stdexam_courseexamseatno_title_default = 16;
  static double stdexam_courseexamtype_title_default = 16;

  //成绩页字体
  static double stdgrade_page_title_default = 40;
  static double refreshstdgrade_button_title_default = 16;
  static double stdgradeswitchterm_title_title_default = 20;
  static double stdgradeswitchterm_year_title_default = 16;
  static double stdgradeswitchterm_term_title_default = 16;
  static double nostdgrade_hint_title_default = 16;
  static double nostdgrade_hint_subtitle_default= 14;
  static double stdgrade_coursename_title_default = 16;
  static double stdgrade_coursecredit_title_default = 16;
  static double stdgrade_coursegradetotal_title_default = 16;
  static double stdgrade_coursegradefinal_title_default = 16;
  static double stdgrade_coursegradegpa_title_default = 16;
  static double stdgrade_coursetype_title_default = 16;

  //网费查询页字体
  static double networkquery_page_title_default = 40;
  static double networkquery_button_title_default = 16;
  static double networktopup_button_title_default = 16;
  static double networkdetail_account_title_default = 20;
  static double networkdetail_realname_title_default = 20;
  static double networkdetail_balance_title_default = 20;
  static double networkdetail_state_title_default = 20;
  static double networkdetail_expire_title_default = 20;
  static double networkquery_hint_title_default = 20;
  static double networkquery_hint_subtitle_default= 16;

  //电费查询页字体
  static double emquery_page_title_default = 40;
  static double emdetail_emid_title_default = 18;
  static double emdetail_emleft_title_default = 18;
  static double emdetail_emtotal_title_default = 18;
  static double emdetail_emstate_title_default = 18;
  static double emdetail_emaddress_title_default = 18;
  static double emquery_nonetwork_title_default = 18;
  static double emquery_querying_title_default = 18;

  //电费账号绑定页字体
  static double embind_page_title_default = 40;
  static double embind_wechatname_title_default = 20;
  static double embind_emnum_title_default = 18;
  static double embindrefresh_button_title_default = 16;
  static double embindunbind_button_title_default = 16;
  static double embind_binding_title_default = 20;
  static double embind_hint_title_default = 20;
  static double embind_hint_subtitle_default= 16;

  //应用设置页字体
  static double settings_page_title_default = 40;
  
  static double generalsettings_divider_title_default = 15;
  static double generalsettings_fontsize_title_default = 16;
  static double generalsettings_fontsize_subtitle_default= 14;
  static double generalsettings_themecolor_title_default = 16;
  static double generalsettings_themecolor_subtitle_default= 14;
  static double generalsettings_darkmode_title_default = 16;
  static double generalsettings_darkmode_subtitle_default= 14;
  
  static double accountsettings_divider_title_default = 15;
  static double accountsettings_emaccount_title_default = 16;
  static double accountsettings_emaccount_subtitle_default= 14;
  static double accountsettings_authserveraccount_title_default = 16;
  static double accountsettings_authserveraccount_subtitle_default= 14;
  
  static double disclamier_divider_title_default = 15;
  static double disclamier_title_title_default = 14;
  
  static double lincense_divider_title_default = 15;
  static double lincense_name_title_default = 18;
  static double lincense_describ_title_default = 14;
}