package com.anya1014.smartsnut

import android.os.Bundle
import com.umeng.commonsdk.UMConfigure
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 友盟统计SDK预初始化
        // SDK预初始化函数不会采集设备信息，也不会向友盟后台上报数据
        UMConfigure.preInit(applicationContext, "67da8acb65c707471a237c33", "official")
    }
}
