import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartsnut/function_modules.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:url_launcher/url_launcher.dart';

//验证码输入框控制器
TextEditingController textCaptchaController = TextEditingController();

//班级列表
String selectedClassName = '';
int selectedClass = -1;

//班级成员列表

class ClasscontactsPage extends StatefulWidget {
  const ClasscontactsPage({super.key});

  @override
  State<ClasscontactsPage> createState() => _ClasscontactsPageState();
}

class _ClasscontactsPageState extends State<ClasscontactsPage> {
  bool _showAppBarTitle = false;

  //读取班级信息
  readClassList() async {
    GlobalVars.classMemberList = [];//清空班级成员列表
    selectedClass = -1;
    String classListpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/wzxyData/classList.json';
    File classListfile = File(classListpath);
    GlobalVars.classList = [];//清空班级列表
    if(await classListfile.exists()){
      GlobalVars.classList = jsonDecode(await classListfile.readAsString());
    }
    if(mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await readClassList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (){getClassList();},
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 2,
        label: Row(
          children: [
            Icon(Icons.refresh),
            SizedBox(width: 10,),
            Text(
              '刷新信息',
              style: TextStyle(
                fontSize: GlobalVars.genericFloationActionButtonTitle,
                fontWeight: FontWeight.w500,
              ),
            )
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
                pinned: true,
                expandedHeight: 0,
                title: _showAppBarTitle ? Text("班级通讯录") : null,
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
                          ? AssetImage('assets/icons/lighttheme/contacts.png')
                          : AssetImage('assets/icons/darktheme/contacts.png'),
                        height: 32,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '班级通讯录',
                      style: TextStyle(
                        fontSize: GlobalVars.genericPageTitle,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    )
                  ],
                ),
              ),
              
              // 通讯录内容区域
              Container(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Card(
                  shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                  color: Theme.of(context).colorScheme.surfaceDim,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 12),
                            Text(
                              '班级列表',
                              style: TextStyle(
                                fontSize: GlobalVars.genericTextLarge,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 24),
                        (GlobalVars.classList.isEmpty)?
                        Center(
                          child: Text(
                            '暂无班级信息，请尝试在下方刷新信息',
                            style: TextStyle(
                              fontSize: GlobalVars.genericTextMedium,
                            ),
                          ),
                        ):
                        Column(
                          children: GlobalVars.classList.map((classItem) {
                            return ListTile(
                              title: Text(
                                '${classItem['name']} （${classItem['count']} 人） ',
                                style: TextStyle(
                                  fontSize: GlobalVars.genericTextMedium,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                '${classItem['area']} ${classItem['degree']} ${classItem['college']} ${classItem['major']}',
                                style: TextStyle(
                                  fontSize: GlobalVars.genericTextSmall,
                                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                                ),
                              ),
                              onTap: () {
                                getClassMemberList(classItem['id']);
                                setState(() {
                                  selectedClass = GlobalVars.classList.indexOf(classItem);
                                  selectedClassName = classItem['name'];
                                });
                              },
                            );
                          }).toList(),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              
              // 示例功能区域
              Container(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Card(
                  shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                  color: Theme.of(context).colorScheme.surfaceDim,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 12),
                            Text(
                              (selectedClass == -1)? '人员列表':'人员列表 - $selectedClassName',
                              style: TextStyle(
                                fontSize: GlobalVars.genericTextLarge,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 24),
                        (selectedClass == -1)?
                        Center(
                          child: Text(
                            '请先在上方选择一个班级',
                            style: TextStyle(
                              fontSize: GlobalVars.genericTextMedium,
                            ),
                          ),
                        ):
                        Column(
                          children: GlobalVars.classMemberList.map((classMember) {
                            return ListTile(
                              trailing: IconButton.filledTonal(
                                onPressed: () {
                                  callPhone(classMember['name'], classMember['phone']);
                                },
                                icon: Icon(Icons.call),
                              ),
                              title: Text(
                                '${classMember['name']}（${classMember['userTypeName']}）',
                                style: TextStyle(
                                  fontSize: GlobalVars.genericTextMedium,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                '学/工号：${classMember['number']}\n电话号码：${classMember['phone']}',
                                style: TextStyle(
                                  fontSize: GlobalVars.genericTextSmall,
                                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              
              // 底部间隔
              Container(padding: EdgeInsets.fromLTRB(0, 80, 0, 0),)
            ],
          ),
        ),
      ),
    );
  }

  //获取班级列表
  getClassList() async {
    GlobalVars.operationCanceled = false;
    GlobalVars.loadingHint = '正在加载...';
    if(mounted){
      showDialog<String>(
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
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    GlobalVars.operationCanceled = true;
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
    
    if(GlobalVars.operationCanceled) return;
    List initialData = await Modules.initialLoginAuth('wzxy');
    if(initialData[0]['statue'] == false){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text(initialData[0]['message'],style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed:  () => Navigator.pop(context, 'Cancel'), child: Text('确认'))],
          ));
      }
      return;
    }

    //输入验证码
    String userCaptchaCode = '';
    textCaptchaController.clear();
    Uint8List? captchaBytes;
    
    Future<List> getCaptchaCode() async {
      GlobalVars.loadingHint = '正在获取验证码...';
      //存储返回的信息
      List message = [];

      late Response captchaResponse;
      try{
        if(GlobalVars.operationCanceled) {
          message.clear();
          message.add({
            'statue': false,
            'message': '操作已取消',
          });
          return message;
        }
        if(GlobalVars.operationCanceled){
          message.clear();
          message.add({
            'statue': false,
            'message': '操作已取消',
          });
          return message;
        }
        var response = await GlobalVars.globalDio.get(
          'https://authserver.snut.edu.cn/authserver/getCaptcha.htl',
          options: Options(
            responseType: ResponseType.bytes, // 指定响应类型为字节数组
          ),
        );
        captchaResponse = response;
      }catch (e) {
        message.clear();
        message.add({
          'statue': false,
          'message': '无法连接服务器，请稍后再试',
        });
        return message;
      }
        
      // 确保响应数据是 Uint8List 类型
      if (captchaResponse.data is Uint8List) {
        if(mounted){
          setState(() {
            captchaBytes = captchaResponse.data;
          });
        }
        message.clear();
        message.add({
          'statue': true,
          'message': '',
        });
        return message;
      }
      if(mounted){
        setState(() {
          captchaBytes = Uint8List.fromList(captchaResponse.data as List<int>);
        });
      }
      message.clear();
      message.add({
        'statue': true,
        'message': '',
      });
      return message;
    }
    
    List getCaptchaCodeResponse = await getCaptchaCode();
    if(getCaptchaCodeResponse[0]['statue'] == false){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text(getCaptchaCodeResponse[0]['message'],style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed:  () => Navigator.pop(context, 'Cancel'), child: Text('确认'))],
          ));
      }
      return;
    }
    
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
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            height: 40,
                            child: Image.memory(captchaBytes!),
                          ),
                          SizedBox(height: 4),
                          IconButton(
                            icon: Icon(Icons.refresh, size: 18),
                            onPressed: () {
                              getCaptchaCode();
                            },
                            tooltip: '刷新验证码',
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                              foregroundColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  SizedBox(height: 10,),
                  Divider(height: 15,indent: 20,endIndent: 20,),
                  Text('验证码不区分大小写',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
                  Divider(height: 15,indent: 20,endIndent: 20,),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    GlobalVars.operationCanceled = true;
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
                    userCaptchaCode = textCaptchaController.text;
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
    
    if(GlobalVars.operationCanceled) return;
    if(mounted){
      showDialog<String>(
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
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    GlobalVars.operationCanceled = true;
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

    if(GlobalVars.operationCanceled) return;
    List loginAuthResponse = await Modules.loginAuth(GlobalVars.userName, GlobalVars.passWord,initialData[0]['pwdEncryptSalt'], userCaptchaCode, initialData[0]['authexecution'],'wzxy');
    if(loginAuthResponse[0]['statue'] == false){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text(loginAuthResponse[0]['message'],style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed:  () => Navigator.pop(context, 'Cancel'), child: Text('确认'))],
          ));
      }
      return;
    }

    //获取班级列表
    if(GlobalVars.operationCanceled) return;
    List getClassListResponse = await Modules.getClassList();
    if(getClassListResponse[0]['statue'] == false){
      if(mounted){
        Navigator.pop(context);
        showDialog<String>(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Text('错误：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text(getClassListResponse[0]['message'],style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [TextButton(onPressed:  () => Navigator.pop(context, 'Cancel'), child: Text('确认'))],
          ));
      }
      return;
    }
    GlobalVars.classList = getClassListResponse[0]['classList'];

    //获取班级成员
    if(GlobalVars.operationCanceled) return;
    for(int i = 1;i <= GlobalVars.classList.length;i++){
      if(GlobalVars.operationCanceled) return;
      await Future.delayed(Duration(milliseconds: 100));
      if(GlobalVars.operationCanceled) return;
      await Modules.getClassMemberList(GlobalVars.classList[i-1]['id']);
    }
    if(mounted){
      setState(() {
        GlobalVars.classList = getClassListResponse[0]['classList'];
      });
      Navigator.pop(context);
    }
  }

  //读取班级信息
  getClassMemberList(String classId) async {
    String classMemberpath = '${(await getApplicationDocumentsDirectory()).path}/SmartSNUT/wzxyData/ClassMembersList-$classId.json';
    File classMemberfile = File(classMemberpath);
    GlobalVars.classMemberList = [];//清空班级成员列表
    GlobalVars.classMemberList = jsonDecode(await classMemberfile.readAsString());
    if(mounted) setState(() {});
  }

  //调用系统电话拨号功能
  callPhone(String name,String phoneNumber) async {
    GlobalVars.operationCanceled = false;
    if(!Platform.isAndroid){
      if(mounted){
        await showDialog<String>(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Text('提示：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
            content: Text('当前系统可能不支持拨打电话，您确定要继续尝试拨打 $name 的电话？\n\n$phoneNumber',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
            actions: [
              TextButton(
                onPressed:  () {
                  Navigator.pop(context);
                  GlobalVars.operationCanceled = true;
                  return;
                }, 
                child: Text('取消')
              ),
              TextButton(onPressed:  () => Navigator.pop(context), child: Text('确认'))
            ],
          )
        );
      }
    }

    if(GlobalVars.operationCanceled) return;
    if(mounted){
      await showDialog<String>(
        context: context, 
        builder: (BuildContext context)=>AlertDialog(
          title: Text('询问：',style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
          content: Text('是否给 $name 拨打电话？\n\n $phoneNumber',style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
          actions: [
            TextButton(
              child: Text('取消'),
              onPressed:  () {
                Navigator.pop(context);
                GlobalVars.operationCanceled = true;
                return;
              }, 
            ),
            TextButton(onPressed:  () => Navigator.pop(context), child: Text('拨打')),
          ],
        )
      );
    }

    if(GlobalVars.operationCanceled) return;
    Uri callUri = Uri.parse('tel:$phoneNumber');
    await launchUrl(callUri);
  }
}