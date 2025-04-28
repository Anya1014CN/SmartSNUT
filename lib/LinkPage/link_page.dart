import 'package:flutter/material.dart';
import 'package:smartsnut/globalvars.dart';
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

class LinkPage extends StatefulWidget {
  const LinkPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _LinkPageState();
  }
}

class _LinkPageState extends State<LinkPage> {

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (hour >= 0 && hour <= 5) {
      greeting = '晚上好';
    }
    if (hour >= 6 && hour <= 11) {
      greeting = '早上好';
    }
    if (hour >= 12 && hour <= 13) {
      greeting = '中午好';
    }
    if (hour >= 14 && hour <= 18) {
      greeting = '下午好';
    }
    if (hour >= 19 && hour <= 23) {
      greeting = '晚上好';
    }
    return ListView(
      children: [
        // 问候语区域
        Container(
          padding: EdgeInsets.fromLTRB(16, 40, 16, 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withAlpha(179),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Text(
            '$greeting，${GlobalVars.realName}',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: GlobalVars.genericGreetingTitle,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        SizedBox(height: 10),
        // 校内链接标题
        Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                width: 4,
                height: 18,
                margin: EdgeInsets.only(right: 8),
              ),
              Text(
                '校内链接',
                style: TextStyle(
                    fontSize: GlobalVars.dividerTitle,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
        // 校内链接卡片
        Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
            color: Theme.of(context).colorScheme.surfaceDim,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '图书检索',
                          'library',
                          () {
                            url = Uri.parse('https://findsnut.libsp.com/');
                            launchURL();
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '人脸信息采集系统',
                          'face',
                          () {
                            url = Uri.parse(
                                'https://faceid.snut.edu.cn/cflms-opencas/cas/v1/collection/');
                            launchURL();
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          'WebVPN',
                          'vpn',
                          () {
                            url = Uri.parse('https://sec.snut.edu.cn/');
                            launchURL();
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '一网通办',
                          'museum',
                          () {
                            url = Uri.parse('https://newehall.snut.edu.cn/');
                            launchURL();
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '南区全景',
                          'city',
                          () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                scrollable: true,
                                title: Row(
                                  children: [
                                    Icon(Icons.info),
                                    SizedBox(width: 8,),
                                    Text('提示：',
                                    style: TextStyle(
                                        fontSize: GlobalVars.alertdialogTitle))
                                  ],
                                ),
                                content: Text(
                                    '此页面可能包含背景音乐\n如果您正在公共场所，请注意控制设备声音',
                                    style: TextStyle(
                                        fontSize: GlobalVars.alertdialogTitle)),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    child: Text('取消'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      url = Uri.parse(
                                          'http://720yun.com/t/728jOreO5n0?scene_id=2641644');
                                      launchURL();
                                    },
                                    child: Text('确定'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '北区全景',
                          'mountain-city',
                          () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                scrollable: true,
                                title: Row(
                                  children: [
                                    Icon(Icons.info),
                                    SizedBox(width: 8,),
                                    Text('提示：',
                                    style: TextStyle(
                                        fontSize: GlobalVars.alertdialogTitle))
                                  ],
                                ),
                                content: Text(
                                    '此页面可能包含背景音乐\n如果您正在公共场所，请注意控制设备声音',
                                    style: TextStyle(
                                        fontSize: GlobalVars.alertdialogTitle)),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    child: Text('取消'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      url = Uri.parse(
                                          'http://720yun.com/t/271jO0uyOv2?scene_id=2712476');
                                      launchURL();
                                    },
                                    child: Text('确定'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '陕西理工大学校报',
                          'newspaper',
                          () {
                            url = Uri.parse('https://sxlgxyb.ihwrm.com/?userId=1859970247021375490&tag=wzxy&school=%E9%99%95%E8%A5%BF%E7%90%86%E5%B7%A5%E5%A4%A7%E5%AD%A6');
                            launchURL();
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 10),

        //考证链接标题
        Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                width: 4,
                height: 18,
                margin: EdgeInsets.only(right: 8),
              ),
              Text(
                '考证链接',
                style: TextStyle(
                    fontSize: GlobalVars.dividerTitle,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
        //考证链接卡片
        Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
            color: Theme.of(context).colorScheme.surfaceDim,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '英语四、六级考试',
                          'english',
                          () {
                            url = Uri.parse('https://cet-bm.neea.edu.cn/');
                            launchURL();
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '教师资格考试',
                          'teacher',
                          () {
                            url = Uri.parse('https://ntce.neea.edu.cn/');
                            launchURL();
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '计算机等级考试',
                          'computer',
                          () {
                            url = Uri.parse('https://ncre.neea.edu.cn/');
                            launchURL();
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: buildFunctionButton(
                          context,
                          '普通话水平测试',
                          'speak',
                          () {
                            url = Uri.parse('https://bm.cltt.org/');
                            launchURL();
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
        
        // 竞赛链接标题
        Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                width: 4,
                height: 18,
                margin: EdgeInsets.only(right: 8),
              ),
              Text(
                '竞赛链接',
                style: TextStyle(
                  fontSize: GlobalVars.dividerTitle,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary
                ),
              ),
            ],
          ),
        ),
        
        // 竞赛链接卡片
        Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Theme.of(context).colorScheme.surfaceDim,
            shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
            child: Container(
              padding: EdgeInsets.all(8),
              child: Column(
                children: [
                  buildCompItem(context, '中国国际大学生创新大赛', '原中国国际 “互联网+” 大学生创新创业大赛','https://cy.ncss.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '“挑战杯” 全国大学生课外学术科技作品竞赛', 'https://www.tiaozhanbei.net/','https://www.tiaozhanbei.net/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '“挑战杯” 中国大学生创业计划大赛', 'https://www.tiaozhanbei.net/','https://www.tiaozhanbei.net/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, 'ACM-ICPC 国际大学生程序设计竞赛', 'https://icpc.global/','https://icpc.global/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生数学建模竞赛', 'http://www.mcm.edu.cn/','http://www.mcm.edu.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生电子设计竞赛', 'http://nuedc.xjtu.edu.cn/','http://nuedc.xjtu.edu.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '中国大学生医学技术技能大赛', '暂未收录该竞赛的官方网站',''),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生机械创新设计大赛', 'http://11umic.hust.edu.cn/index.htm','http://11umic.hust.edu.cn/index.htm'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生结构设计竞赛', 'http://www.structurecontest.com/','http://www.structurecontest.com/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生广告艺术大赛', 'http://www.sun-ada.net/','http://www.sun-ada.net/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生智能汽车竞赛', 'http://www.smartcarrace.com/','http://www.smartcarrace.com/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生电子商务 “创新、创意及创业” 挑战赛', 'http://www.3chuang.net/','http://www.3chuang.net/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '中国大学生工程实践与创新能力大赛', 'http://www.gcxl.edu.cn/new/index.html','http://www.gcxl.edu.cn/new/index.html'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生物流设计大赛', 'http://www.clpp.org.cn/html/competition/','http://www.clpp.org.cn/html/competition/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '“外研社·国才杯” “理解当代中国” 全国大学生外语能力大赛 （1.英语演讲 2.英语辩论 3.英语写作 4.英语阅读）', '原外研社全国大学生英语系列赛 （1.英语演讲 2.英语辩论 3.英语写作 4.英语阅读）','https://ucc.fltrp.com/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '两岸新锐设计竞赛 · 华灿奖', 'http://www.huacanjiang.com/home','http://www.huacanjiang.com/home'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生创新创业训练计划年会展示', 'http://gjcxcy.bjtu.edu.cn/Index.aspx','http://gjcxcy.bjtu.edu.cn/Index.aspx'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生化工设计竞赛', 'http://iche.zju.edu.cn/','http://iche.zju.edu.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生机器人大赛 （CURC)', '原全国大学生机器人大赛 （1.RoboMaster 2.RoboCon）','https://www.cnrobocon.net/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生市场调查与分析大赛', 'http://www.china-cssc.org/list-57-1.html','http://www.china-cssc.org/list-57-1.html'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生先进成图技术与产品信息建模创新大赛', 'http://chengtudasai.com/','http://chengtudasai.com/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国三维数字化创新设计大赛', 'https://3dds.3ddl.net/','https://3dds.3ddl.net/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '“西门子杯” 中国智能制造挑战赛', 'http://www.siemenscup-cimc.org.cn/','http://www.siemenscup-cimc.org.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '中国大学生服务外包创新创业大赛', 'http://www.fwwb.org.cn/','http://www.fwwb.org.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '中国大学生计算机设计大赛', 'http://jsjds.blcu.edu.cn/','http://jsjds.blcu.edu.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '中国高校计算机大赛', '1.大数据挑战赛 2.团体程序设计天梯赛 3.移动应用创新赛 4.网络技术挑战赛 5.人工智能创意赛','http://www.c4best.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '蓝桥杯全国软件和信息技术专业人才大赛', 'https://dasai.lanqiao.cn/','https://dasai.lanqiao.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '米兰设计周 -- 中国高校设计学科师生优秀作品展', 'https://milan-aap.org.cn/ ','https://milan-aap.org.cn/ '),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生地质技能竞赛', 'https://yuanxi.cugb.edu.cn/competition/','https://yuanxi.cugb.edu.cn/competition/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生光电设计竞赛', 'http://gd.p.moocollege.com/','http://gd.p.moocollege.com/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生集成电路创新创业大赛', 'http://univ.ciciec.com/','http://univ.ciciec.com/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生金相技能大赛', 'http://www.jxds.tech/#/','http://www.jxds.tech/#/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生信息安全竞赛', 'http://www.ciscn.cn/','http://www.ciscn.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '未来设计师·全国高校数字艺术设计大赛', '（含未来设计师·国际创新设计大赛）','http://www.ncda.org.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国周培源大学生力学竞赛', 'http://zpy.cstam.org.cn/index.aspx','http://zpy.cstam.org.cn/index.aspx'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '中国大学生机械工程创新创意大赛', 'http://meicc.cmes.org','http://meicc.cmes.org'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '中国机器人大赛暨 RoboCup 机器人世界杯中国赛', 'http://crc.drct-caa.org.cn/','http://crc.drct-caa.org.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '“中国软件杯” 大学生软件设计大赛', 'https://www.cnsoftbei.com/','https://www.cnsoftbei.com/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '中美青年创客大赛', 'https://chinaus-maker.cscse.edu.cn/','https://chinaus-maker.cscse.edu.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '睿抗机器人开发者大赛 (RAICOM)', 'https://www.raicom.com.cn/','https://www.raicom.com.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '“大唐杯” 全国大学生新一代信息通信技术大赛', 'https://dtcup.dtxiaotangren.com/HomePage','https://dtcup.dtxiaotangren.com/HomePage'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '华为 ICT 大赛', 'https://e.huawei.com/cn/talent/ict-academy/#/ict-contest?compId=85131998','https://e.huawei.com/cn/talent/ict-academy/#/ict-contest?compId=85131998'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生嵌入式芯片与系统设计竞赛', 'http://www.socchina.net/','http://www.socchina.net/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生生命科学竞赛 （CULSC)', 'https://culsc.cn/#/','https://culsc.cn/#/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生物理实验竞赛', 'http://wlsycx.moocollege.com/','http://wlsycx.moocollege.com/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国高校 BIM 毕业设计创新大赛', 'https://gxbsxs.glodonedu.com/#/home','https://gxbsxs.glodonedu.com/#/home'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国高校商业精英挑战赛', '（1.品牌策划竞赛 2.文旅与会展创新创业实践竞赛 3.国际贸易竞赛 4.创新创业竞赛 5.会计与商业管理案例竞赛）','http://cubec.org.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '“学创杯” 全国大学生创业综合模拟大赛', 'http://www.xcbds.cn/cyds/index','http://www.xcbds.cn/cyds/index'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '中国高校智能机器人创意大赛', 'http://www.robotcontest.cn/','http://www.robotcontest.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '中国好创意暨全国数字艺术设计大赛', 'https://www.cdec.org.cn/','https://www.cdec.org.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '中国机器人及人工智能大赛', 'https://www.caairobot.com/','https://www.caairobot.com/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生节能减排社会实践与科技竞赛', 'http://www.jienengjianpai.org/','http://www.jienengjianpai.org/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '“21世纪杯” 全国英语演讲比赛', 'https://contest.i21st.cn/','https://contest.i21st.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, 'iCAN 大学生创新创业大赛', 'http://www.g-ican.com/','http://www.g-ican.com/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '“工行杯” 全国大学生金融科技创新大赛', 'https://www.gonghangbei.com/','https://www.gonghangbei.com/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '中华经典诵写讲大赛', 'https://www.jingdiansxj.cn/home','https://www.jingdiansxj.cn/home'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '“外教社杯” 全国高校学生跨文化能力大赛', 'https://ict.sflep.com/index.php?m=content&c=index&a=lists&catid=51','https://ict.sflep.com/index.php?m=content&c=index&a=lists&catid=51'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '百度之星 · 程序设计大赛', 'https://star.baidu.com/#/','https://star.baidu.com/#/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生工业设计大赛', 'https://www.cuidc.net/#/','https://www.cuidc.net/#/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生水利创新设计大赛', 'https://sljzw.hhu.edu.cn/fenhui/main.psp','https://sljzw.hhu.edu.cn/fenhui/main.psp'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生化工实验大赛', 'http://www.cteic.com/higherEducation-199.html','http://www.cteic.com/higherEducation-199.html'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生化学实验创新设计大赛', 'https://cid.nju.edu.cn/','https://cid.nju.edu.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生计算机系统能力大赛', 'https://compiler.educg.net/#/','https://compiler.educg.net/#/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生花园设计建造竞赛', 'http://www.lalavision.com/','http://www.lalavision.com/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生物联网设计竞赛', 'https://iot.sjtu.edu.cn/Default.aspx','https://iot.sjtu.edu.cn/Default.aspx'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生信息安全与对抗技术竞赛', 'https://www.isclab.org.cn/','https://www.isclab.org.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生测绘学科创新创业智能大赛', 'https://smt.whu.edu.cn/','https://smt.whu.edu.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生统计建模大赛', 'http://tjjmds.ai-learning.net/','http://tjjmds.ai-learning.net/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生能源经济学术创意大赛', 'http://energy.qibebt.ac.cn/eneco/contribution/index.html#/index','http://energy.qibebt.ac.cn/eneco/contribution/index.html#/index'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生基础医学创新研究暨实验设计论坛（大赛）', 'http://www.jcyxds.com/','http://www.jcyxds.com/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生数字媒体科技作品及创意竞赛', 'http://mit.caai.cn/','http://mit.caai.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国本科院校税收风险管控案例大赛', 'http://ssfkds.moocollege.com/','http://ssfkds.moocollege.com/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国企业竞争模拟大赛', 'http://www.ibizsim.com.cn/','http://www.ibizsim.com.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国高等院校数智化企业经营沙盘大赛', 'https://www.seentao.com/','https://www.seentao.com/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国数字建筑创新应用大赛', 'http://bisai.ccen.com.cn/index','http://bisai.ccen.com.cn/index'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全球校园人工智能算法精英大赛', 'http://www.digix.org.cn','http://www.digix.org.cn'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '国际大学生智能农业装备创新大赛', 'https://uiaec.ujs.edu.cn/','https://uiaec.ujs.edu.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '“科云杯” 全国大学生财会职业能力大赛', 'http://match.xmkeyun.com.cn/nc/','http://match.xmkeyun.com.cn/nc/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  buildCompItem(context, '全国大学生机器人大赛 - RoboTac', 'https://www.robotac.cn/','https://www.robotac.cn/'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  Container(
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '备注',
                              style: TextStyle(
                                fontSize: GlobalVars.genericTextSmall,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '· 数据来源：《2023 全国普通高校大学生竞赛分析报告》',
                          style: TextStyle(
                            fontSize: GlobalVars.genericTextSmall,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '· 按照竞赛入榜年份、竞赛名称首字笔画从小到大进行排序',
                          style: TextStyle(
                            fontSize: GlobalVars.genericTextSmall,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '· 系列赛入榜年份按照第一个子赛入榜年份计算',
                          style: TextStyle(
                            fontSize: GlobalVars.genericTextSmall,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '· 暂不包含高职赛',
                          style: TextStyle(
                            fontSize: GlobalVars.genericTextSmall,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              )
            ),
          ),
        ),

        // 底部间隔
        SizedBox(height: 20),
      ],
    );
  }

  // 功能按钮构建辅助方法
  Widget buildFunctionButton(
      BuildContext context, String title, String iconName, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: Theme.of(context).brightness == Brightness.light
                  ? AssetImage('assets/icons/lighttheme/$iconName.png')
                  : AssetImage('assets/icons/darktheme/$iconName.png'),
              height: 40,
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: GlobalVars.genericFunctionsButtonTitle,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }

  // 竞赛列表按钮构建辅助方法
  
  // 新闻项目构建辅助方法
  Widget buildCompItem(BuildContext context, String title, String describe, String compUrl) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: GlobalVars.listTileTitle,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                describe,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: GlobalVars.listTileSubtitle,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '官方网站',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: GlobalVars.listTileSubtitle,
              ),
            ),
          ],
        ),
      ),
      trailing: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha(26),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      onTap: () {
        if(compUrl == ''){
          if(mounted){
            showDialog(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                scrollable: true,
                title: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 8,),
                    Text('提示：', style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
                  ],
                ),
                content: Text('$title\n\n暂未收录该竞赛的官方网站',
                    style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('确定'),
                  ),
                ],
              ),
            );
            return;
          }
        }
        url = Uri.parse(compUrl);
        launchURL();
      },
    );
  }

  //打开链接
  void launchURL() async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
        title: Row(
          children: [
            Icon(Icons.help),
            SizedBox(width: 8,),
            Text('询问：', style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
          ],
        ),
        content: Text('是否要使用系统默认浏览器打开外部链接？\n\n$url',
            style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await launchUrl(url);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
  }
}