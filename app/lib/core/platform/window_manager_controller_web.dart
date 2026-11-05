/// Web stand-in for the window_manager controller (P9-01).
///
/// window_manager does not compile for web, so web builds get the no-op
/// controller under the same name. Selected by the conditional export in
/// desktop_window.dart.
library;

import 'package:flit/core/platform/desktop_window.dart';

typedef WindowManagerController = NoopWindowController;
