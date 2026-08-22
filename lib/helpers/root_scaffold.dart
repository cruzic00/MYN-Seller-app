import 'package:flutter/material.dart';

/// Key of the Scaffold in screens/main.dart that hosts the three tabs.
///
/// The side panel used to hang off each tab's own Scaffold. Those Scaffolds sit
/// inside the root one's body, so the floating nav bar — painted by the root —
/// stayed on top of the open panel and left a strip of dashboard showing under
/// it. A Scaffold paints its drawer above its bottomNavigationBar, so hosting
/// the panel on the root and opening it through this key puts it over the nav
/// bar instead of under it.
final GlobalKey<ScaffoldState> rootScaffoldKey = GlobalKey<ScaffoldState>();

/// Opens the side panel from any tab. Silently does nothing when the root
/// Scaffold is not mounted, which is the case for screens pushed on top of it.
void openRootDrawer() => rootScaffoldKey.currentState?.openDrawer();
