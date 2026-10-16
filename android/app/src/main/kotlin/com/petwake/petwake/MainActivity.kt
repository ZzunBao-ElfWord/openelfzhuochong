package com.petwake.petwake

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// 宿主 Activity：除承载 Flutter 外，实现 `petwake/apps` 原生桥，
/// 供桌宠枚举并唤起本机其他应用（对齐 Dart 侧 [AndroidAppLauncher]）。
class MainActivity : FlutterActivity() {

    private val channelName = "petwake/apps"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "listTargets" -> result.success(listLaunchableApps())
                    "launch" -> result.success(launchApp(call.argument<String>("id")))
                    "openUrl" -> result.success(openUrl(call.argument<String>("url")))
                    else -> result.notImplemented()
                }
            }
    }

    /// 枚举具有启动入口的应用（Android 11+ 依赖 Manifest 中的 <queries> 包可见性声明）。
    private fun listLaunchableApps(): List<Map<String, String>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val resolved = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(0L))
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(intent, 0)
        }
        return resolved
            .map { it.activityInfo.packageName to it.loadLabel(pm).toString() }
            .distinctBy { it.first }
            .filter { it.first != packageName }
            .sortedBy { it.second }
            .take(40)
            .map { mapOf("id" to it.first, "name" to it.second) }
    }

    /// 通过包名启动目标应用。
    private fun launchApp(pkg: String?): Boolean {
        if (pkg.isNullOrEmpty()) return false
        val intent = packageManager.getLaunchIntentForPackage(pkg) ?: return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    /// 通过 URL Scheme 唤起（对齐 iOS 侧能力，可选）。
    private fun openUrl(url: String?): Boolean {
        if (url.isNullOrEmpty()) return false
        return try {
            startActivity(
                Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            )
            true
        } catch (_: Exception) {
            false
        }
    }
}
