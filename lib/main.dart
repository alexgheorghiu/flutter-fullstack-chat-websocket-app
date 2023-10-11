import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:random_avatar/random_avatar.dart';

late String currentName;

class Message {
  String message;

  String author;

  DateTime? date;

  Message(String this.message, String this.author, DateTime? this.date);

  factory Message.fromJson(Map<String, dynamic> json) =>
      Message(json['message'], json['author'], DateTime.tryParse(json['date']));

  Map<String, dynamic> toJson() =>
      {'message': message, 'author': author, 'date': date!.toIso8601String()};
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tiny tiny Flutter Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(title: 'Tiny tiny Flutter WebSocket app'),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});

  final String title;

  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: 300,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                  child: Column(
                    children: [
                      Text('Login', style: TextStyle(fontWeight: FontWeight.bold,), textAlign: TextAlign.left),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: 'You name'),
                      ),
                      TextButton(
                          onPressed: _onSubmit, child: Text('Submit'),
                      ),
                ],
              )),
            )
          ],
        ),
      ),
    );
  }

  void _onSubmit() {
    if (_nameController.text.isNotEmpty) {
      currentName = _nameController.text;
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(title: "Simple chat"),
          ));
    }
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.title});

  final String title;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final WebSocketChannel _channel =
      WebSocketChannel.connect(Uri.parse('ws://192.168.100.73:10000'));

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      Message m = Message(_controller.text, currentName, DateTime.now());
      _channel.sink.add(jsonEncode(m));
    }
    _controller.text = '';
  }

  Widget _messagesToUI(String data) {
    print("_messagesToUI: data = ${data}");
    List<Message> messages = (jsonDecode(data) as List<dynamic>)
        .map((data) => Message.fromJson(data))
        .toList();
    return Expanded(
        child: ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: messages.length,
          itemBuilder: (context, index) => ListTile(
            leading: RandomAvatar(messages[index].author, trBackground: true, height: 50, width: 50),
            title: Text(
              messages[index].author,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                    messages[index].message,
                    style: TextStyle(decoration: TextDecoration.underline)
                ),
              ],
            ),
            trailing: Text('${messages[index].date!.hour}:${messages[index].date!.minute}'),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
                child: TextFormField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Send a message'),
            )),
            SizedBox(
              height: 24,
            ),
            StreamBuilder(
              stream: _channel.stream,
              builder: (context, snapshot) {
                return snapshot.hasData
                    ? _messagesToUI(snapshot.data)
                    : Text('');
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendMessage,
        tooltip: 'Increment',
        child: const Icon(Icons.send),
      ),
    );
  }

  @override
  void dispose() {
    _channel.sink.close();
    _controller.dispose();
    super.dispose();
  }
}
