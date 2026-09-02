// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import '../theme/app_theme.dart';
// import 'dashboard_screen.dart';
// import 'add_product_screen.dart';
// //import 'package:smart_shelf/screens/dashboard_screen.dart';

// class MainShell extends StatefulWidget {
//   final VoidCallback onSignOut;
//   const MainShell({super.key, required this.onSignOut});

//   @override
//   State<MainShell> createState() => _MainShellState();
// }

// class _MainShellState extends State<MainShell> {
//   int _selectedIndex = 0;

//   static const List<_NavItem> _navItems = [
//     _NavItem(icon: Icons.grid_view_rounded, activeIcon: Icons.grid_view_rounded, label: 'Dashboard'),
//     _NavItem(icon: Icons.add_circle_outline_rounded, activeIcon: Icons.add_circle_rounded, label: 'Add Item'),
//     _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings'),
//   ];

//   Widget _buildPageContent() {
//     if (_selectedIndex == 0) {
//       return FirestoreDashboardScreen();
//       // return const DashboardScreen();
//     } else if (_selectedIndex == 1) {
//       return AddProductScreen(
//         onItemAdded: () {
//           setState(() => _selectedIndex = 0);
//         },
//       );
//     }
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             _navItems[_selectedIndex].icon,
//             size: 64,
//             color: AppTheme.textMuted.withOpacity(0.4),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             _navItems[_selectedIndex].label,
//             style: const TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//               color: AppTheme.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Coming soon...',
//             style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);
//     final user = authProvider.currentUser;

//     return Scaffold(
//       backgroundColor: AppTheme.backgroundMint,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         surfaceTintColor: Colors.transparent,
//         toolbarHeight: 60,
//         title: Row(
//           children: [
//             Image.asset(
//               'assets/images/logo.png',
//               height: 32,
//               errorBuilder: (_, __, ___) =>
//                   const Icon(Icons.shelves, color: AppTheme.primaryGreen),
//             ),
//             const SizedBox(width: 8),
//             const Text(
//               'SmartShelf',
//               style: TextStyle(
//                 color: AppTheme.primaryGreen,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           // Notification bell with badge
//           Stack(
//             alignment: Alignment.topRight,
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.notifications_none_outlined,
//                     color: AppTheme.textPrimary),
//                 onPressed: () {},
//               ),
//               Positioned(
//                 right: 8,
//                 top: 8,
//                 child: Container(
//                   width: 18,
//                   height: 18,
//                   decoration: BoxDecoration(
//                     color: AppTheme.expiredRed,
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.white, width: 2),
//                   ),
//                   child: const Center(
//                     child: Text(
//                       '3',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 9,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           // User avatar
//           Padding(
//             padding: const EdgeInsets.only(right: 16.0),
//             child: CircleAvatar(
//               radius: 16,
//               backgroundColor: AppTheme.primaryGreen,
//               child: Text(
//                 user?.displayName.substring(0, 1).toUpperCase() ?? 'U',
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),

//       body: _buildPageContent(),

//       // ── Bottom Navigation ──
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, -2),
//             ),
//           ],
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildBottomNavItem(0),
//                 // Floating add button
//                 GestureDetector(
//                   onTap: () => setState(() => _selectedIndex = 1),
//                   child: Container(
//                     width: 52,
//                     height: 52,
//                     decoration: BoxDecoration(
//                       gradient: const LinearGradient(
//                         colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: AppTheme.primaryGreen.withOpacity(0.35),
//                           blurRadius: 12,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: const Icon(Icons.add, color: Colors.white, size: 28),
//                   ),
//                 ),
//                 _buildBottomNavItem(2),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBottomNavItem(int index) {
//     final isSelected = _selectedIndex == index;
//     final item = _navItems[index];
//     return GestureDetector(
//       onTap: () => setState(() => _selectedIndex = index),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             isSelected ? item.activeIcon : item.icon,
//             color: isSelected ? AppTheme.primaryGreen : AppTheme.textMuted,
//             size: 24,
//           ),
//           const SizedBox(height: 4),
//           Text(
//             item.label,
//             style: TextStyle(
//               fontSize: 11,
//               color: isSelected ? AppTheme.primaryGreen : AppTheme.textMuted,
//               fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _NavItem {
//   final IconData icon;
//   final IconData activeIcon;
//   final String label;
//   const _NavItem({required this.icon, required this.activeIcon, required this.label});
// }

// version - signin+ui+login 

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import '../theme/app_theme.dart';
// import 'dashboard_screen.dart';
// import 'add_product_screen.dart';


// class MainShell extends StatefulWidget {
//   final VoidCallback onSignOut;
//   const MainShell({super.key, required this.onSignOut});

//   @override
//   State<MainShell> createState() => _MainShellState();
// }

// class _MainShellState extends State<MainShell> {
//   int _selectedIndex = 0;

//   static const List<_NavItem> _navItems = [
//     _NavItem(
//         icon: Icons.grid_view_rounded,
//         activeIcon: Icons.grid_view_rounded,
//         label: 'Dashboard'),
//     _NavItem(
//         icon: Icons.add_circle_outline_rounded,
//         activeIcon: Icons.add_circle_rounded,
//         label: 'Add Item'),
//     _NavItem(
//         icon: Icons.settings_outlined,
//         activeIcon: Icons.settings_rounded,
//         label: 'Settings'),
//   ];

//   Widget _buildPageContent() {
//     if (_selectedIndex == 0) {
//       // Changed FirestoreDashboardScreen() to DashboardScreen()
//       //return FirestoreDashboardScreen();
//       return const DashboardScreen();
//     } else if (_selectedIndex == 1) {
//       return AddProductScreen(
//         onItemAdded: () {
//           setState(() => _selectedIndex = 0);
//         },
//       );
//     }
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             _navItems[_selectedIndex].icon,
//             size: 64,
//             color: AppTheme.textMuted.withOpacity(0.4),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             _navItems[_selectedIndex].label,
//             style: const TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//               color: AppTheme.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Coming soon...',
//             style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);
//     final user = authProvider.currentUser;

//     return Scaffold(
//       backgroundColor: AppTheme.backgroundMint,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         surfaceTintColor: Colors.transparent,
//         toolbarHeight: 60,
//         title: Row(
//           children: [
//             Image.asset(
//               'assets/images/logo.png',
//               height: 32,
//               errorBuilder: (_, __, ___) =>
//                   const Icon(Icons.shelves, color: AppTheme.primaryGreen),
//             ),
//             const SizedBox(width: 8),
//             const Text(
//               'SmartShelf',
//               style: TextStyle(
//                 color: AppTheme.primaryGreen,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           // Notification bell with badge
//           Stack(
//             alignment: Alignment.topRight,
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.notifications_none_outlined,
//                     color: AppTheme.textPrimary),
//                 onPressed: () {},
//               ),
//               Positioned(
//                 right: 8,
//                 top: 8,
//                 child: Container(
//                   width: 18,
//                   height: 18,
//                   decoration: BoxDecoration(
//                     color: AppTheme.expiredRed,
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.white, width: 2),
//                   ),
//                   child: const Center(
//                     child: Text(
//                       '3',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 9,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           // User avatar
//           Padding(
//             padding: const EdgeInsets.only(right: 16.0),
//             child: CircleAvatar(
//               radius: 16,
//               backgroundColor: AppTheme.primaryGreen,
//               child: Text(
//                 user?.displayName != null && user!.displayName!.isNotEmpty
//                     ? user.displayName!.substring(0, 1).toUpperCase()
//                     : 'U',
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),

//       body: _buildPageContent(),

//       // ── Bottom Navigation ──
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, -2),
//             ),
//           ],
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildBottomNavItem(0),
//                 // Floating add button
//                 GestureDetector(
//                   onTap: () => setState(() => _selectedIndex = 1),
//                   child: Container(
//                     width: 52,
//                     height: 52,
//                     decoration: BoxDecoration(
//                       gradient: const LinearGradient(
//                         colors: [
//                           AppTheme.primaryGreen,
//                           AppTheme.accentGreen
//                         ],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: AppTheme.primaryGreen.withOpacity(0.35),
//                           blurRadius: 12,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: const Icon(Icons.add,
//                         color: Colors.white, size: 28),
//                   ),
//                 ),
//                 _buildBottomNavItem(2),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBottomNavItem(int index) {
//     final isSelected = _selectedIndex == index;
//     final item = _navItems[index];
//     return GestureDetector(
//       onTap: () => setState(() => _selectedIndex = index),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             isSelected ? item.activeIcon : item.icon,
//             color: isSelected ? AppTheme.primaryGreen : AppTheme.textMuted,
//             size: 24,
//           ),
//           const SizedBox(height: 4),
//           Text(
//             item.label,
//             style: TextStyle(
//               fontSize: 11,
//               color: isSelected ? AppTheme.primaryGreen : AppTheme.textMuted,
//               fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _NavItem {
//   final IconData icon;
//   final IconData activeIcon;
//   final String label;
//   const _NavItem(
//       {required this.icon, required this.activeIcon, required this.label});
// }


// version - signin+ui+login+signout

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../providers/auth_provider.dart';
// import '../theme/app_theme.dart';

// import 'dashboard_screen.dart';
// import 'add_product_screen.dart';

// class MainShell extends StatefulWidget {
//   final VoidCallback onSignOut;

//   const MainShell({
//     super.key,
//     required this.onSignOut,
//   });

//   @override
//   State<MainShell> createState() => _MainShellState();
// }

// class _MainShellState extends State<MainShell> {
//   int _selectedIndex = 0;

//   static const List<_NavItem> _navItems = [
//     _NavItem(
//       icon: Icons.grid_view_rounded,
//       activeIcon: Icons.grid_view_rounded,
//       label: 'Dashboard',
//     ),
//     _NavItem(
//       icon: Icons.add_circle_outline_rounded,
//       activeIcon: Icons.add_circle_rounded,
//       label: 'Add Item',
//     ),
//     _NavItem(
//       icon: Icons.settings_outlined,
//       activeIcon: Icons.settings_rounded,
//       label: 'Settings',
//     ),
//   ];

//   // ------------------------------------------------------------
//   // PAGE CONTENT
//   // ------------------------------------------------------------

//   Widget _buildPageContent() {
//     if (_selectedIndex == 0) {
//       return const DashboardScreen();
//     } else if (_selectedIndex == 1) {
//       return AddProductScreen(
//         onItemAdded: () {
//           setState(() => _selectedIndex = 0);
//         },
//       );
//     }

//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             _navItems[_selectedIndex].icon,
//             size: 64,
//             color: AppTheme.textMuted.withOpacity(0.4),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             _navItems[_selectedIndex].label,
//             style: const TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//               color: AppTheme.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Coming soon...',
//             style: TextStyle(
//               fontSize: 14,
//               color: AppTheme.textMuted,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ------------------------------------------------------------
//   // SIGN OUT
//   // ------------------------------------------------------------

//   Future<void> _handleSignOut() async {
//     final shouldSignOut = await showDialog<bool>(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           title: const Text('Sign Out'),
//           content: const Text(
//             'Are you sure you want to sign out of SmartShelf?',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(dialogContext).pop(false);
//               },
//               child: const Text(
//                 'Cancel',
//                 style: TextStyle(
//                   color: AppTheme.textMuted,
//                 ),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(dialogContext).pop(true);
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppTheme.primaryGreen,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text('Sign Out'),
//             ),
//           ],
//         );
//       },
//     );

//     if (shouldSignOut == true && mounted) {
//       widget.onSignOut();
//     }
//   }

//   // ------------------------------------------------------------
//   // BUILD
//   // ------------------------------------------------------------

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);
//     final user = authProvider.currentUser;

//     return Scaffold(
//       backgroundColor: AppTheme.backgroundMint,

//       // ----------------------------------------------------------
//       // APP BAR
//       // ----------------------------------------------------------

//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         surfaceTintColor: Colors.transparent,
//         toolbarHeight: 60,

//         title: Row(
//           children: [
//             Image.asset(
//               'assets/images/logo.png',
//               height: 32,
//               errorBuilder: (_, __, ___) => const Icon(
//                 Icons.shelves,
//                 color: AppTheme.primaryGreen,
//               ),
//             ),
//             const SizedBox(width: 8),
//             const Text(
//               'SmartShelf',
//               style: TextStyle(
//                 color: AppTheme.primaryGreen,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),

//         actions: [
//           // --------------------------------------------------------
//           // Notification bell with badge
//           // --------------------------------------------------------

//           Stack(
//             alignment: Alignment.topRight,
//             children: [
//               IconButton(
//                 icon: const Icon(
//                   Icons.notifications_none_outlined,
//                   color: AppTheme.textPrimary,
//                 ),
//                 onPressed: () {},
//               ),
//               Positioned(
//                 right: 8,
//                 top: 8,
//                 child: Container(
//                   width: 18,
//                   height: 18,
//                   decoration: BoxDecoration(
//                     color: AppTheme.expiredRed,
//                     shape: BoxShape.circle,
//                     border: Border.all(
//                       color: Colors.white,
//                       width: 2,
//                     ),
//                   ),
//                   child: const Center(
//                     child: Text(
//                       '3',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 9,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           // --------------------------------------------------------
//           // User avatar + menu
//           // --------------------------------------------------------

//           Padding(
//             padding: const EdgeInsets.only(right: 16.0),
//             child: PopupMenuButton<String>(
//               tooltip: 'Account',
//               offset: const Offset(0, 45),

//               onSelected: (value) {
//                 if (value == 'signout') {
//                   _handleSignOut();
//                 }
//               },

//               itemBuilder: (context) => [
//                 // User information
//                 PopupMenuItem<String>(
//                   enabled: false,
//                   child: Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 18,
//                         backgroundColor: AppTheme.primaryGreen,
//                         child: Text(
//                           _getUserInitial(user?.displayName),
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment:
//                               CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               user?.displayName?.isNotEmpty == true
//                                   ? user!.displayName
//                                   : 'User',
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(
//                                 color: AppTheme.textPrimary,
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: 14,
//                               ),
//                             ),
//                             const SizedBox(height: 2),
//                             Text(
//                               user?.email ?? '',
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(
//                                 color: AppTheme.textMuted,
//                                 fontSize: 11,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const PopupMenuDivider(),

//                 // Sign out
//                 const PopupMenuItem<String>(
//                   value: 'signout',
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.logout_rounded,
//                         color: AppTheme.expiredRed,
//                         size: 21,
//                       ),
//                       SizedBox(width: 12),
//                       Text(
//                         'Sign Out',
//                         style: TextStyle(
//                           color: AppTheme.textPrimary,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],

//               // The avatar itself
//               child: CircleAvatar(
//                 radius: 16,
//                 backgroundColor: AppTheme.primaryGreen,
//                 child: Text(
//                   _getUserInitial(user?.displayName),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),

//       // ----------------------------------------------------------
//       // BODY
//       // ----------------------------------------------------------

//       body: _buildPageContent(),

//       // ----------------------------------------------------------
//       // BOTTOM NAVIGATION
//       // ----------------------------------------------------------

//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, -2),
//             ),
//           ],
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 8,
//             ),
//             child: Row(
//               mainAxisAlignment:
//                   MainAxisAlignment.spaceAround,
//               children: [
//                 _buildBottomNavItem(0),

//                 // --------------------------------------------------
//                 // Floating Add Button
//                 // --------------------------------------------------

//                 GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       _selectedIndex = 1;
//                     });
//                   },
//                   child: Container(
//                     width: 52,
//                     height: 52,
//                     decoration: BoxDecoration(
//                       gradient: const LinearGradient(
//                         colors: [
//                           AppTheme.primaryGreen,
//                           AppTheme.accentGreen,
//                         ],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: AppTheme.primaryGreen
//                               .withOpacity(0.35),
//                           blurRadius: 12,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: const Icon(
//                       Icons.add,
//                       color: Colors.white,
//                       size: 28,
//                     ),
//                   ),
//                 ),

//                 _buildBottomNavItem(2),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ------------------------------------------------------------
//   // USER INITIAL
//   // ------------------------------------------------------------

//   String _getUserInitial(String? displayName) {
//     if (displayName != null &&
//         displayName.trim().isNotEmpty) {
//       return displayName
//           .trim()
//           .substring(0, 1)
//           .toUpperCase();
//     }

//     return 'U';
//   }

//   // ------------------------------------------------------------
//   // BOTTOM NAVIGATION ITEM
//   // ------------------------------------------------------------

//   Widget _buildBottomNavItem(int index) {
//     final isSelected = _selectedIndex == index;
//     final item = _navItems[index];

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _selectedIndex = index;
//         });
//       },
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             isSelected
//                 ? item.activeIcon
//                 : item.icon,
//             color: isSelected
//                 ? AppTheme.primaryGreen
//                 : AppTheme.textMuted,
//             size: 24,
//           ),
//           const SizedBox(height: 4),
//           Text(
//             item.label,
//             style: TextStyle(
//               fontSize: 11,
//               color: isSelected
//                   ? AppTheme.primaryGreen
//                   : AppTheme.textMuted,
//               fontWeight: isSelected
//                   ? FontWeight.w600
//                   : FontWeight.normal,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ------------------------------------------------------------
// // NAVIGATION ITEM MODEL
// // ------------------------------------------------------------

// class _NavItem {
//   final IconData icon;
//   final IconData activeIcon;
//   final String label;

//   const _NavItem({
//     required this.icon,
//     required this.activeIcon,
//     required this.label,
//   });
// }

// version - addingg analytics

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

import 'dashboard_screen.dart';
import 'add_product_screen.dart';
import 'analytics_screen.dart';

class MainShell extends StatefulWidget {
  final VoidCallback onSignOut;

  const MainShell({
    super.key,
    required this.onSignOut,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.grid_view_rounded,
      activeIcon: Icons.grid_view_rounded,
      label: 'Dashboard',
    ),
    _NavItem(
      icon: Icons.add_circle_outline_rounded,
      activeIcon: Icons.add_circle_rounded,
      label: 'Add Item',
    ),
    _NavItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics_rounded,
      label: 'Analytics',
    ),
  ];

  // ------------------------------------------------------------
  // PAGE CONTENT
  // ------------------------------------------------------------

  Widget _buildPageContent() {
    if (_selectedIndex == 0) {
      return const DashboardScreen();
    }

    if (_selectedIndex == 1) {
      return AddProductScreen(
        onItemAdded: () {
          setState(() {
            _selectedIndex = 0;
          });
        },
      );
    }

    if (_selectedIndex == 2) {
      return const AnalyticsScreen();
    }

    return const SizedBox.shrink();
  }

  // ------------------------------------------------------------
  // SIGN OUT
  // ------------------------------------------------------------

  Future<void> _handleSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text(
            'Are you sure you want to sign out of SmartShelf?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true && mounted) {
      widget.onSignOut();
    }
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundMint,

      // ----------------------------------------------------------
      // APP BAR
      // ----------------------------------------------------------

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 60,

        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.shelves,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'SmartShelf',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),

        actions: [
          // --------------------------------------------------------
          // Notification bell with badge
          // --------------------------------------------------------

          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_outlined,
                  color: AppTheme.textPrimary,
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.expiredRed,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // --------------------------------------------------------
          // User avatar + menu
          // --------------------------------------------------------

          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              tooltip: 'Account',
              offset: const Offset(0, 45),

              onSelected: (value) {
                if (value == 'signout') {
                  _handleSignOut();
                }
              },

              itemBuilder: (context) => [
                // User information
                PopupMenuItem<String>(
                  enabled: false,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primaryGreen,
                        child: Text(
                          _getUserInitial(
                            user?.displayName,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName?.isNotEmpty == true
                                  ? user!.displayName
                                  : 'User',
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight:
                                    FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              user?.email ?? '',
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const PopupMenuDivider(),

                // Sign out
                const PopupMenuItem<String>(
                  value: 'signout',
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: AppTheme.expiredRed,
                        size: 21,
                      ),

                      SizedBox(width: 12),

                      Text(
                        'Sign Out',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Avatar
              child: CircleAvatar(
                radius: 16,
                backgroundColor:
                    AppTheme.primaryGreen,
                child: Text(
                  _getUserInitial(
                    user?.displayName,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ----------------------------------------------------------
      // BODY
      // ----------------------------------------------------------

      body: _buildPageContent(),

      // ----------------------------------------------------------
      // BOTTOM NAVIGATION
      // ----------------------------------------------------------

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),

        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),

            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
              children: [
                // Dashboard
                _buildBottomNavItem(0),

                // ------------------------------------------------
                // Floating Add Button
                // ------------------------------------------------

                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },

                  child: Container(
                    width: 52,
                    height: 52,

                    decoration: BoxDecoration(
                      gradient:
                          const LinearGradient(
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.accentGreen,
                        ],
                        begin:
                            Alignment.topLeft,
                        end:
                            Alignment.bottomRight,
                      ),

                      shape: BoxShape.circle,

                      boxShadow: [
                        BoxShadow(
                          color: AppTheme
                              .primaryGreen
                              .withOpacity(0.35),
                          blurRadius: 12,
                          offset:
                              const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

                // Analytics
                _buildBottomNavItem(2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // USER INITIAL
  // ------------------------------------------------------------

  String _getUserInitial(
    String? displayName,
  ) {
    if (displayName != null &&
        displayName.trim().isNotEmpty) {
      return displayName
          .trim()
          .substring(0, 1)
          .toUpperCase();
    }

    return 'U';
  }

  // ------------------------------------------------------------
  // BOTTOM NAVIGATION ITEM
  // ------------------------------------------------------------

  Widget _buildBottomNavItem(
    int index,
  ) {
    final isSelected =
        _selectedIndex == index;

    final item =
        _navItems[index];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },

      child: Column(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            isSelected
                ? item.activeIcon
                : item.icon,
            color: isSelected
                ? AppTheme.primaryGreen
                : AppTheme.textMuted,
            size: 24,
          ),

          const SizedBox(height: 4),

          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected
                  ? AppTheme.primaryGreen
                  : AppTheme.textMuted,
              fontWeight: isSelected
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// NAVIGATION ITEM MODEL
// ------------------------------------------------------------

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}