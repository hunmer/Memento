import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

Future<http.Client> createClientWithSystemProxy() async {
  // 创建一个自定义的 HttpClient 来明确应用代理设置
  final httpClient = HttpClient();

  // 获取系统代理设置
  final httpProxy =
      Platform.environment['HTTP_PROXY'] ?? Platform.environment['http_proxy'];
  final httpsProxy =
      Platform.environment['HTTPS_PROXY'] ??
      Platform.environment['https_proxy'];

  // 用于调试的日志
  if (httpProxy != null && httpProxy.isNotEmpty) {
    debugPrint('System HTTP proxy detected: $httpProxy');
  }

  if (httpsProxy != null && httpsProxy.isNotEmpty) {
    debugPrint('System HTTPS proxy detected: $httpsProxy');
  }

  // 明确设置代理
  if ((httpProxy != null && httpProxy.isNotEmpty) ||
      (httpsProxy != null && httpsProxy.isNotEmpty)) {
    try {
      final proxyUrl = httpsProxy ?? httpProxy;
      if (proxyUrl != null) {
        // 解析代理URL
        Uri proxyUri = Uri.parse(proxyUrl);

        // 设置代理
        httpClient.findProxy = (uri) {
          final host = proxyUri.host;
          final port = proxyUri.port;
          debugPrint('Using proxy for $uri: $host:$port');
          return 'PROXY $host:$port';
        };

        // 如果代理需要认证
        if (proxyUri.userInfo.isNotEmpty) {
          List<String> userInfo = proxyUri.userInfo.split(':');
          if (userInfo.length == 2) {
            // 正确处理认证回调的类型
            httpClient.authenticate = (Uri url, String scheme, String? realm) {
              debugPrint('Authenticating proxy with username: ${userInfo[0]}');
              // 设置凭据并返回true表示已提供凭据
              httpClient.addCredentials(
                url,
                realm ?? '',
                HttpClientBasicCredentials(userInfo[0], userInfo[1]),
              );
              return Future.value(true);
            };
          }
        }
      }
    } catch (e) {
      debugPrint('Error setting proxy: $e');
    }
  }

  // 允许自签名证书，如果代理使用自签名证书
  httpClient.badCertificateCallback = (cert, host, port) => true;

  // 创建一个基于自定义HttpClient的http客户端
  return IOClient(httpClient);
}
