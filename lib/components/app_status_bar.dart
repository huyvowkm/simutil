import 'package:nocterm/nocterm.dart';

class AppStatusBar extends StatelessComponent {
  const AppStatusBar({super.key, required this.message});

  final String message;

  @override
  Component build(BuildContext context) {
    return Row(children: [Expanded(child: Text(' $message', softWrap: true))]);
  }
}
