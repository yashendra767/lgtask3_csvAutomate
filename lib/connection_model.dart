class LGConnection {
  String host;
  int port;
  String username;
  String password;
  int screens;

  LGConnection({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.screens,
  });

  Map<String, dynamic> toJson() => {
    'host': host,
    'port': port,
    'username': username,
    'password': password,
    'screens': screens,
  };
}