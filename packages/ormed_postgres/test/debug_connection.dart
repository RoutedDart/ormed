import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  final url = Platform.environment['POSTGRES_URL'] ?? 'postgres://postgres:postgres@127.0.0.1:6543/orm_test';
  print('Connecting to: $url');
  
  try {
    final uri = Uri.parse(url);
    print('Host: ${uri.host}, Port: ${uri.port}');
    
    final endpoint = Endpoint(
      host: uri.host,
      port: uri.port,
      database: uri.pathSegments.first,
      username: uri.userInfo.split(':').first,
      password: uri.userInfo.split(':').last,
    );
    
    final connection = await Connection.open(endpoint);
    print('Connected successfully!');
    await connection.close();
  } catch (e) {
    print('Connection failed: $e');
  }
}
