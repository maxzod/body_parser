import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:palace_body_parser/palace_body_parser.dart';

void main() async {
  final address = '127.0.0.1';
  final port = 3000;
  final futures = <Future>[];

  for (var i = 1; i < Platform.numberOfProcessors; i++) {
    futures.add(Isolate.spawn(start, [address, port, i]));
  }

  await Future.wait(futures);
  print('All instances started.');
  print('Test with "wrk -t12 -c400 -d30s -s ./example/post.lua http://localhost:3000" or similar');
  start([address, port, 0]);
}

void start(List args) {
  var address = InternetAddress(args[0] as String);
  dynamic port = args[1], id = args[2];

  HttpServer.bind(address, port as int, shared: true).then((server) {
    server.listen((request) async {
      var body = await parseBodyFromStream(
        request,
        request.headers.contentType != null ? MediaType.parse(request.headers.contentType.toString()) : null,
        request.uri,
        storeOriginalBuffer: false,
      );
      request.response
        ..headers.contentType = ContentType('application', 'json')
        ..write(json.encode(body.body));
      await request.response.close();
    });

    print('Server #$id listening at http://${server.address.address}:${server.port}');
  });
}
