import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:routing/pages/sample_page.dart';

void main() {
  testWidgets('fetches API items and deletes one item', (tester) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var deleteRequests = 0;

    server.listen((request) async {
      final path = request.uri.path;
      final response = request.response;

      if (request.method == 'GET' && path == 'posts') {
        response.statusCode = 200;
        response.headers.set('Content-Type', 'application/json');
        response.write(
          jsonEncode([
            {'id': 1, 'title': 'First post', 'body': 'First body'},
            {'id': 2, 'title': 'Second post', 'body': 'Second body'},
          ]),
        );
      } else if (request.method == 'DELETE' && path == 'posts/2') {
        deleteRequests++;
        response.statusCode = 200;
        response.write(jsonEncode({'deleted': true}));
      } else {
        response.statusCode = 404;
        response.write(jsonEncode({'error': 'Not found'}));
      }
      await response.close();
    });

    final client = http.Client();
    final apiBaseUrl = 'http://localhost:${server.port}';

    addTearDown(() {
      client.close();
      server.close();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: SamplePage(apiBaseUrl: apiBaseUrl, client: client),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('First post'), findsOneWidget);
    expect(find.text('Second post'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete item 2'));
    await tester.pumpAndSettle();

    expect(deleteRequests, 1);
    expect(find.text('First post'), findsOneWidget);
    expect(find.text('Second post'), findsNothing);
  });
}
