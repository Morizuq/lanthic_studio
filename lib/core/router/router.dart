
import 'package:go_router/go_router.dart';
import '../../features/project/screens/project_shell_screen.dart';
import 'routes.dart';

final router = GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => const ProjectShellScreen(),
    ),
  ],
);


