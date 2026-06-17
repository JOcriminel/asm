import 'dart:convert';
import 'dart:io';

void main() async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:9090/document/1334977202606131602346207188'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    
    final data = jsonDecode(body);
    final flatPayload = data['data'];
    
    // Print all keys and their types to see what lists exist and what might be null
    flatPayload.forEach((key, value) {
      if (value is List) {
        print('LIST: $key (length: ${value.length})');
      } else if (value == null) {
        print('NULL: $key');
      }
    });
    
    client.close();
  } catch (e) {
    print('Error: $e');
  }
}
