import 'package:flutter/material.dart';
import 'package:smartsnut/function_modules.dart';
import 'package:smartsnut/globalvars.dart';
import 'package:intl/intl.dart';

//判断显示哪个页面（查询页面/查询结果）
bool showResultPage = false;

//存储初始化信息
List initPublicFreeDataResponse = [];

//存储查询结果
List publicFreeData = [];
int publicFreeDataPages = 0;
int currentPage = 1; // 当前页码

// 存储下拉菜单选项
String selectedClassroomType = '未选择';//教室类型
String selectedClassroomTypeId = '';
String selectedCampus = '未选择';//校区
String selectedCampusId = '';
String selectedBuilding = '未选择';//教学楼
String selectedBuildingId = '';
String selectedCycleType = '天';//时间周期
String selectedCycleTypeId = '1';
String selectedRoomApplyType = '教室使用时间';
String selectedRoomApplyTypeId = '1';//使用时间/使用小节

class PublicFreePage extends StatefulWidget {
  const PublicFreePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _PublicFreePageState();
  }
}

class _PublicFreePageState extends State<PublicFreePage> {
  bool _showAppBarTitle = false;

  // MenuAnchor控制器
  final classroomTypeMenuController = MenuController();
  final campusMenuController = MenuController();
  final buildingMenuController = MenuController();
  final roomApplyTypeMenuController = MenuController();
  final timeTypeMenuController = MenuController();

  // 文本输入控制器
  final textSeatsController = TextEditingController();//最小容纳人数
  final textClassroomNameController = TextEditingController();//教室名称
  final textCycleCountController = TextEditingController(text: '1');//时间周期
  final textTimeBeginController = TextEditingController(text: '8:00');//开始时间
  final textTimeEndController = TextEditingController(text: '10:00');//结束时间
  final textSectionBeginController = TextEditingController(text: '1');//开始时间（小节）
  final textSectionEndController = TextEditingController(text: '2');//结束时间（小节）

  // 日期选择
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 7));

  // 表单项的可见性控制
  bool showTimeRange = true;
  bool showSectionRange = false;

  @override
  void dispose() {
    textSeatsController.dispose();
    textClassroomNameController.dispose();
    textCycleCountController.dispose();
    textTimeBeginController.dispose();
    textTimeEndController.dispose();
    textSectionBeginController.dispose();
    textSectionEndController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    showResultPage = false;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      initPublicFreeData();
    });
  }

  // 日期选择器
  Future<void> selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate : endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: '请选择日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
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
                title: _showAppBarTitle ? Text("空闲教室查询") : null,
              ),
            ];
          },
          body: ListView(
            children: [
              // 页面标题区域
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
                          ? AssetImage('assets/icons/lighttheme/classroom.png')
                          : AssetImage('assets/icons/darktheme/classroom.png'),
                        height: 32,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '空闲教室查询',
                      style: TextStyle(
                        fontSize: GlobalVars.genericPageTitle,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    )
                  ],
                ),
              ),
              
              // 页面内容区域
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  shadowColor: Theme.of(context).colorScheme.onPrimary.withAlpha(77),
                  color: Theme.of(context).colorScheme.surfaceDim,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: !showResultPage? 
                  //表单区域
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        // 教室类型
                        Row(
                          children: [
                            Text(
                              '教室类型',
                              style: TextStyle(
                                fontSize: GlobalVars.listTileTitle,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 5),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error.withAlpha(26),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '选填',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        MenuAnchor(
                          controller: classroomTypeMenuController,
                          builder: (context, controller, child) {
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).colorScheme.outline),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  controller.open();
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        selectedClassroomType.isNotEmpty
                                            ? selectedClassroomType
                                            : '请选择教室类型',
                                        style: TextStyle(
                                          fontSize: GlobalVars.genericTextMedium,
                                        ),
                                      ),
                                      Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          menuChildren: initPublicFreeDataResponse.isNotEmpty
                              ? initPublicFreeDataResponse[0]['classroomTypeList']
                                  .map<Widget>((item) {
                                  return MenuItemButton(
                                    onPressed: () {
                                      setState(() {
                                        selectedClassroomType = item['name'];
                                        selectedClassroomTypeId = item['id'];
                                      });
                                    },
                                    child: Text(item['name']),
                                  );
                                }).toList()
                              : [
                                  MenuItemButton(
                                    onPressed: null,
                                    child: Text('加载中...'),
                                  ),
                                ],
                        ),
                        
                        SizedBox(height: 16),

                        // 校区选择
                        Row(
                          children: [
                            Text(
                              '校区',
                              style: TextStyle(
                                fontSize: GlobalVars.listTileTitle,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 5),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error.withAlpha(26),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '选填',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        MenuAnchor(
                          controller: campusMenuController,
                          builder: (context, controller, child) {
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).colorScheme.outline),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  controller.open();
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        selectedCampus.isNotEmpty
                                            ? selectedCampus
                                            : '请选择校区',
                                        style: TextStyle(
                                          fontSize: GlobalVars.genericTextMedium,
                                        ),
                                      ),
                                      Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          menuChildren: initPublicFreeDataResponse.isNotEmpty
                              ? initPublicFreeDataResponse[0]['campusList']
                                  .map<Widget>((item) {
                                  return MenuItemButton(
                                    onPressed: () {
                                      setState(() {
                                        selectedCampus = item['name'];
                                        selectedCampusId = item['id'];
                                      });
                                    },
                                    child: Text(item['name']),
                                  );
                                }).toList()
                              : [
                                  MenuItemButton(
                                    onPressed: null,
                                    child: Text('加载中...'),
                                  ),
                                ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // 教学楼选择
                        Row(
                          children: [
                            Text(
                              '教学楼',
                              style: TextStyle(
                                fontSize: GlobalVars.listTileTitle,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 5),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error.withAlpha(26),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '选填',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        MenuAnchor(
                          controller: buildingMenuController,
                          builder: (context, controller, child) {
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).colorScheme.outline),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  controller.open();
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        selectedBuilding.isNotEmpty
                                            ? selectedBuilding
                                            : '请选择教学楼',
                                        style: TextStyle(
                                          fontSize: GlobalVars.genericTextMedium,
                                        ),
                                      ),
                                      Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          menuChildren: initPublicFreeDataResponse.isNotEmpty
                              ? initPublicFreeDataResponse[0]['buildingList']
                                  .map<Widget>((item) {
                                  return MenuItemButton(
                                    onPressed: () {
                                      setState(() {
                                        selectedBuilding = item['name'];
                                        selectedBuildingId = item['id'];
                                      });
                                    },
                                    child: Text(item['name']),
                                  );
                                }).toList()
                              : [
                                  MenuItemButton(
                                    onPressed: null,
                                    child: Text('加载中...'),
                                  ),
                                ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // 最小容纳人数
                        Row(
                          children: [
                            Text(
                              '最小容纳人数',
                              style: TextStyle(
                                fontSize: GlobalVars.listTileTitle,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 5),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error.withAlpha(26),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '选填',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: textSeatsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '请输入最小容纳人数',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // 教室名称（选填）
                        Row(
                          children: [
                            Text(
                              '教室名称',
                              style: TextStyle(
                                fontSize: GlobalVars.listTileTitle,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 5),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error.withAlpha(26),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '选填',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: textClassroomNameController,
                          decoration: InputDecoration(
                            hintText: '请输入教室名称',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // 时间周期
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '时间周期',
                                        style: TextStyle(
                                          fontSize: GlobalVars.listTileTitle,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.error.withAlpha(26),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '必填',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.error,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  TextField(
                                    controller: textCycleCountController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: '请输入天/周数',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '周期单位',
                                        style: TextStyle(
                                          fontSize: GlobalVars.listTileTitle,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.error.withAlpha(26),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '必填',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.error,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  MenuAnchor(
                                    controller: roomApplyTypeMenuController,
                                    builder: (context, controller, child) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            controller.open();
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  selectedCycleType.isNotEmpty
                                                      ? selectedCycleType
                                                      : '请选择周期单位',
                                                  style: TextStyle(
                                                    fontSize: GlobalVars.genericTextMedium,
                                                  ),
                                                ),
                                                Icon(Icons.arrow_drop_down),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    menuChildren: <String>['天', '周']
                                        .map<Widget>((String value) {
                                      return MenuItemButton(
                                        onPressed: () {
                                          setState(() {
                                            selectedCycleType = value;
                                            selectedCycleTypeId =
                                                value == '天' ? '1' : '2';
                                          });
                                        },
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // 起始日期
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '起始日期',
                                        style: TextStyle(
                                          fontSize: GlobalVars.listTileTitle,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.error.withAlpha(26),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '必填',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.error,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => selectDate(context, true),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            DateFormat('yyyy-MM-dd').format(startDate),
                                            style: TextStyle(fontSize: GlobalVars.genericTextMedium),
                                          ),
                                          Icon(Icons.calendar_today, size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '结束日期',
                                        style: TextStyle(
                                          fontSize: GlobalVars.listTileTitle,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.error.withAlpha(26),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '必填',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.error,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => selectDate(context, false),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            DateFormat('yyyy-MM-dd').format(endDate),
                                            style: TextStyle(fontSize: GlobalVars.genericTextMedium),
                                          ),
                                          Icon(Icons.calendar_today, size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // 时间类型选择
                        Row(
                          children: [
                            Text(
                              '时间类型',
                              style: TextStyle(
                                fontSize: GlobalVars.listTileTitle,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 5),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error.withAlpha(26),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '必填',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        MenuAnchor(
                          controller: timeTypeMenuController,
                          builder: (context, controller, child) {
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).colorScheme.outline),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  controller.open();
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        selectedRoomApplyType.isNotEmpty
                                            ? selectedRoomApplyType
                                            : '请选择时间类型',
                                        style: TextStyle(
                                          fontSize: GlobalVars.genericTextMedium,
                                        ),
                                      ),
                                      Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          menuChildren: <String>['教室使用时间', '教室使用节次']
                              .map<Widget>((String value) {
                            return MenuItemButton(
                              onPressed: () {
                                setState(() {
                                  selectedRoomApplyType = value;
                                  selectedRoomApplyTypeId =
                                      value == '教室使用时间' ? '1' : '2';
                                  showTimeRange = value == '教室使用时间';
                                  showSectionRange = value == '教室使用节次';
                                });
                              },
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        
                        // 时间范围
                        if (showTimeRange) ...[
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '开始时间',
                                          style: TextStyle(
                                            fontSize: GlobalVars.listTileTitle,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.error.withAlpha(26),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '必填',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.error,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: textTimeBeginController,
                                      decoration: InputDecoration(
                                        hintText: '例如：08:00',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '结束时间',
                                          style: TextStyle(
                                            fontSize: GlobalVars.listTileTitle,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.error.withAlpha(26),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '必填',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.error,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: textTimeEndController,
                                      decoration: InputDecoration(
                                        hintText: '例如：18:00',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        // 节次范围
                        if (showSectionRange) ...[
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '开始节次',
                                          style: TextStyle(
                                            fontSize: GlobalVars.listTileTitle,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.error.withAlpha(26),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '必填',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.error,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: textSectionBeginController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: '例如：1',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '结束节次',
                                          style: TextStyle(
                                            fontSize: GlobalVars.listTileTitle,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.error.withAlpha(26),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '必填',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.error,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: textSectionEndController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: '例如：10',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        SizedBox(height: 24),
                        
                        // 提交按钮
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: Size(double.infinity, 56),
                          ),
                          onPressed: () {
                            queryPublicFreeData();
                          },
                          child: Text(
                            '查询空闲教室',
                            style: TextStyle(
                              fontSize: GlobalVars.genericTextMedium,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ):
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 返回按钮
                        OutlinedButton.icon(
                          icon: Icon(Icons.arrow_back),
                          label: Text('返回查询页面'),
                          onPressed: () {
                            setState(() {
                              showResultPage = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).colorScheme.outline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        SizedBox(height: 16,),

                        // 结果标题
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline, 
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text(
                              '查询结果',
                              style: TextStyle(
                                fontSize: GlobalVars.genericPageTitle - 4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 16),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '本页共${publicFreeData.length}个教室',
                                style: TextStyle(
                                  fontSize: GlobalVars.genericTextSmall,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16),

                        // 顶部分页功能
                        if (publicFreeDataPages > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back),
                                onPressed: currentPage > 1
                                    ? () {
                                        setState(() {
                                          currentPage--;
                                          queryPublicFreeData();
                                        });
                                      }
                                    : null,
                              ),
                              Text(
                                '第 $currentPage 页 / 共 $publicFreeDataPages 页',
                                style: TextStyle(
                                  fontSize: GlobalVars.genericTextMedium,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.arrow_forward),
                                onPressed: currentPage < publicFreeDataPages
                                    ? () {
                                        setState(() {
                                          currentPage++;
                                          queryPublicFreeData();
                                        });
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        
                        SizedBox(height: 24),
                        
                        // 显示教室列表
                        ...publicFreeData.map((classroom) {
                          return Card(
                            elevation: 0,
                            color: Theme.of(context).colorScheme.surfaceContainerLow,
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 编号标签
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${classroom['Number']}',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      // 教室名称和信息
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${classroom['Name']}',
                                              style: TextStyle(
                                                fontSize: GlobalVars.listTileTitle,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.location_on_outlined, 
                                                     size: 16, 
                                                     color: Theme.of(context).colorScheme.onSurfaceVariant),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    '${classroom['Campus']} · ${classroom['Building']}',
                                                    style: TextStyle(
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                      fontSize: GlobalVars.genericTextSmall,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 12),
                                  
                                  // 教室详细信息标签
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      // 教室类型标签
                                      if (classroom['ClassroomType'] != null && classroom['ClassroomType'].toString().isNotEmpty)
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${classroom['ClassroomType']}',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                                              fontSize: GlobalVars.genericTextSmall,
                                            ),
                                          ),
                                        ),
                                      
                                      // 容纳人数标签
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.tertiaryContainer,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.people_outline, 
                                              size: 14, 
                                              color: Theme.of(context).colorScheme.onTertiaryContainer
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '容纳: ${classroom['Capacity']}人',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onTertiaryContainer,
                                                fontSize: GlobalVars.genericTextSmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        
                        // 如果没有结果显示空状态
                        if (publicFreeData.isEmpty)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 32),
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '没有找到符合条件的教室',
                                  style: TextStyle(
                                    fontSize: GlobalVars.listTileTitle,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '请尝试调整查询条件后重试',
                                  style: TextStyle(
                                    fontSize: GlobalVars.genericTextSmall,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: 32),
                              ],
                            ),
                          ),

                          SizedBox(height: 16),
                        
                        // 底部分页功能
                        if (publicFreeDataPages > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back),
                                onPressed: currentPage > 1
                                    ? () {
                                        setState(() {
                                          currentPage--;
                                          queryPublicFreeData();
                                        });
                                      }
                                    : null,
                              ),
                              Text(
                                '第 $currentPage 页 / 共 $publicFreeDataPages 页',
                                style: TextStyle(
                                  fontSize: GlobalVars.genericTextMedium,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.arrow_forward),
                                onPressed: currentPage < publicFreeDataPages
                                    ? () {
                                        setState(() {
                                          currentPage++;
                                          queryPublicFreeData();
                                        });
                                      }
                                    : null,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  //初始化查询数据
  initPublicFreeData() async {
    GlobalVars.operationCanceled = false;
    GlobalVars.loadingHint = '正在加载...';
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              scrollable: true,
              title: Text('请稍后...', style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
              content: Column(
                children: [
                  SizedBox(height: 10),
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text(GlobalVars.loadingHint, style: TextStyle(fontSize: GlobalVars.alertdialogContent))
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
    initPublicFreeDataResponse = [];
    initPublicFreeDataResponse = await Modules.initPublicFreeData();
    if(initPublicFreeDataResponse[0]['status'] == false){
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error),
                  SizedBox(width: 8,),
                  Text('错误：', style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
                ],
              ),
              content: Text(initPublicFreeDataResponse[0]['message'], style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('确定'),
                ),
              ],
            );
          },
        );
      }
      return;
    }
    if(mounted) Navigator.pop(context);
  }

  //查询空闲教室
  queryPublicFreeData() async {
    //校验用户输入的数据
    if(textCycleCountController.text.isEmpty){
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.info),
                  SizedBox(width: 8,),
                  Text('提示：', style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
                ],
              ),
              content: Text('请输入时间周期', style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('确定'),
                ),
              ],
            );
          },
        );
      }
      return;
    }if(textTimeBeginController.text.isEmpty || textSectionBeginController.text.isEmpty){
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.info),
                  SizedBox(width: 8,),
                  Text('提示：', style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
                ],
              ),
              content: Text('请输入开始时间', style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('确定'),
                ),
              ],
            );
          },
        );
      }
      return;
    }if(textTimeEndController.text.isEmpty || textSectionEndController.text.isEmpty){
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.info),
                  SizedBox(width: 8,),
                  Text('提示：', style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
                ],
              ),
              content: Text('请输入结束时间', style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('确定'),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    GlobalVars.operationCanceled = false;
    GlobalVars.loadingHint = '正在加载...';
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              scrollable: true,
              title: Text('请稍后...', style: TextStyle(fontSize: GlobalVars.alertdialogTitle)),
              content: Column(
                children: [
                  SizedBox(height: 10),
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text(GlobalVars.loadingHint, style: TextStyle(fontSize: GlobalVars.alertdialogContent))
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

    String timeBegin = '';
    String timeEnd = '';
    if(selectedRoomApplyTypeId == '1'){
      timeBegin = textTimeBeginController.text;
      timeEnd = textTimeEndController.text;
    }if(selectedRoomApplyTypeId == '2'){
      timeBegin = textSectionBeginController.text;
      timeEnd = textSectionEndController.text;
    }
    publicFreeData = [];
    List queryPublicFreeDataResponse = await Modules.queryPublicFreeData(selectedClassroomTypeId, selectedCampusId, selectedBuildingId, textSeatsController.text, textClassroomNameController.text, textCycleCountController.text, selectedCycleTypeId, DateFormat('yyyy-MM-dd').format(startDate), DateFormat('yyyy-MM-dd').format(endDate), selectedRoomApplyTypeId, timeBegin, timeEnd, currentPage);
    if(queryPublicFreeDataResponse[0]['status'] == false){
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error),
                  SizedBox(width: 8,),
                  Text('错误：', style: TextStyle(fontSize: GlobalVars.alertdialogTitle))
                ],
              ),
              content: Text(queryPublicFreeDataResponse[0]['message'], style: TextStyle(fontSize: GlobalVars.alertdialogContent)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('确定'),
                ),
              ],
            );
          },
        );
      }
      return;
    }
    if (mounted) {
      setState(() {
        publicFreeData = queryPublicFreeDataResponse[0]['publicFreeData'];
        showResultPage = true;
        publicFreeDataPages = (queryPublicFreeDataResponse[0]['totalItems'] / queryPublicFreeDataResponse[0]['pageSize']).ceil();
      });
      Navigator.pop(context);
    }
  }
}