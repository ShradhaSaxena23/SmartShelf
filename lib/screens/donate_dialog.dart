
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../models/product_model.dart';
// import '../services/donation_service.dart';
// import '../theme/app_theme.dart';
// import 'package:intl/intl.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// // Public API: call this to show the dialog
// // ─────────────────────────────────────────────────────────────────────────────

// void showDonateDialog(BuildContext context, ProductModel product) {
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (_) => _DonateDialog(product: product),
//   );
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Dialog phases
// // ─────────────────────────────────────────────────────────────────────────────

// enum _Phase { initial, locating, analyzing, results, error }

// // ─────────────────────────────────────────────────────────────────────────────
// // Main Dialog Widget
// // ─────────────────────────────────────────────────────────────────────────────

// class _DonateDialog extends StatefulWidget {
//   final ProductModel product;
//   const _DonateDialog({required this.product});

//   @override
//   State<_DonateDialog> createState() => _DonateDialogState();
// }

// class _DonateDialogState extends State<_DonateDialog>
//     with SingleTickerProviderStateMixin {
//   _Phase _phase = _Phase.initial;
//   Position? _position;
//   GeminiDonationResult? _aiResult;
//   List<DonationCenter> _centers = [];
//   String? _errorMessage;
//   late AnimationController _pulseController;
//   late Animation<double> _pulseAnim;

//   @override
//   void initState() {
//     super.initState();
//     _pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1200),
//     )..repeat(reverse: true);
//     _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );
//   }

//   @override
//   void dispose() {
//     _pulseController.dispose();
//     super.dispose();
//   }

//   // ── Location logic ──────────────────────────────────────────────────────────

//   Future<void> _onFindShelters() async {
//     setState(() => _phase = _Phase.locating);

//     try {
//       // Check permission
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }
//       if (permission == LocationPermission.deniedForever ||
//           permission == LocationPermission.denied) {
//         setState(() {
//           _phase = _Phase.error;
//           _errorMessage =
//               'Location permission denied. Please enable it in device settings to find nearby donation centers.';
//         });
//         return;
//       }

//       final pos = await Geolocator.getCurrentPosition(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.medium,
//           timeLimit: Duration(seconds: 10),
//         ),
//       );
//       _position = pos;
//     } catch (_) {
//       // Use fallback coordinates if location unavailable
//       _position = Position(
//         latitude: 28.6139,
//         longitude: 77.2090,
//         timestamp: DateTime.now(),
//         accuracy: 0,
//         altitude: 0,
//         altitudeAccuracy: 0,
//         heading: 0,
//         headingAccuracy: 0,
//         speed: 0,
//         speedAccuracy: 0,
//       );
//     }

//     // ── AI Analysis ───────────────────────────────────────────────────────────
//     setState(() => _phase = _Phase.analyzing);

//     final aiResult = await DonationService.assessDonationSuitability(widget.product);
//     _aiResult = aiResult;

//     // ── Fetch nearby centers ──────────────────────────────────────────────────
//     final orgTypes = aiResult.isSuitable
//         ? aiResult.suggestedOrgTypes
//         : ['Animal Shelter', 'Food Bank'];

//     final centers = await DonationService.findNearbyDonationCenters(
//       latitude: _position!.latitude,
//       longitude: _position!.longitude,
//       orgTypes: orgTypes,
//     );

//     setState(() {
//       _centers = centers;
//       _phase = _Phase.results;
//     });
//   }

//   // ── Navigation ──────────────────────────────────────────────────────────────

//   Future<void> _openMaps(DonationCenter center) async {
//     final uri = Uri.parse(center.googleMapsUrl);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     }
//   }

//   Future<void> _callPhone(String phone) async {
//     final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     }
//   }

//   Future<void> _openAllOnMap() async {
//     if (_position == null) return;
//     final query = Uri.encodeComponent(
//         _aiResult?.suggestedOrgTypes.isNotEmpty == true
//             ? _aiResult!.suggestedOrgTypes.first
//             : 'animal shelter');
//     final url =
//         'https://www.google.com/maps/search/$query/@${_position!.latitude},${_position!.longitude},13z';
//     final uri = Uri.parse(url);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     }
//   }

//   // ── Build ────────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final isWide = MediaQuery.of(context).size.width > 700;
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//       clipBehavior: Clip.antiAlias,
//       insetPadding: EdgeInsets.symmetric(
//         horizontal: isWide ? 80 : 16,
//         vertical: 24,
//       ),
//       child: ConstrainedBox(
//         constraints: BoxConstraints(
//           maxWidth: 560,
//           maxHeight: MediaQuery.of(context).size.height * 0.88,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _buildHeader(),
//             Flexible(child: _buildBody()),
//             _buildFooter(),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── Header ──────────────────────────────────────────────────────────────────

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFF0F5A36), Color(0xFF1A7A4C)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.white.withValues(alpha: 0.2),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 22),
//           ),
//           const SizedBox(width: 12),
//           const Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Donate Item',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   'Find nearby donation centers with AI',
//                   style: TextStyle(color: Colors.white70, fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.close, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//             tooltip: 'Close',
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Body dispatcher ─────────────────────────────────────────────────────────

//   Widget _buildBody() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildProductCard(),
//           const SizedBox(height: 16),
//           if (_phase == _Phase.initial) _buildInitialPhase(),
//           if (_phase == _Phase.locating) _buildLoadingPhase('Getting your location...', Icons.my_location),
//           if (_phase == _Phase.analyzing) _buildLoadingPhase('AI is analyzing donation suitability...', Icons.psychology),
//           if (_phase == _Phase.results) ...[
//             _buildAiResultCard(),
//             const SizedBox(height: 16),
//             _buildNearbySection(),
//           ],
//           if (_phase == _Phase.error) _buildErrorCard(),
//         ],
//       ),
//     );
//   }

//   // ── Product Card ─────────────────────────────────────────────────────────────

//   Widget _buildProductCard() {
//     final daysAgo = widget.product.daysRemaining.abs();
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: const Color(0xFFFFF5F5),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: const Color(0xFFFECACA)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 52,
//             height: 52,
//             decoration: BoxDecoration(
//               color: _categoryColor(widget.product.category).withValues(alpha: 0.12),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(
//               _categoryIcon(widget.product.category),
//               color: _categoryColor(widget.product.category),
//               size: 28,
//             ),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.product.name,
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.bold,
//                     color: AppTheme.textPrimary,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   '${widget.product.category}  •  ${widget.product.quantity} units',
//                   style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     const Icon(Icons.schedule, size: 13, color: AppTheme.expiredRed),
//                     const SizedBox(width: 3),
//                     Text(
//                       'Expired $daysAgo ${daysAgo == 1 ? 'day' : 'days'} ago  •  ${DateFormat('MMM d, yyyy').format(widget.product.expiryDate)}',
//                       style: const TextStyle(
//                         fontSize: 12,
//                         color: AppTheme.expiredRed,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Phase 1 — Initial ─────────────────────────────────────────────────────────

//   Widget _buildInitialPhase() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.all(14),
//           decoration: BoxDecoration(
//             color: const Color(0xFFF0F9FF),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: const Color(0xFFBAE6FD)),
//           ),
//           child: const Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Icon(Icons.info_outline, color: AppTheme.donateBlue, size: 18),
//               SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   'Our AI will analyze the product and find nearby donation centers like Gaushalas, animal shelters, and dairy farms that can accept this item.',
//                   style: TextStyle(
//                     fontSize: 12.5,
//                     color: Color(0xFF0369A1),
//                     height: 1.4,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 16),
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.all(14),
//           decoration: BoxDecoration(
//             color: AppTheme.backgroundMint,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: AppTheme.cardBorder),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: AppTheme.primaryGreen.withValues(alpha: 0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.my_location, color: AppTheme.primaryGreen, size: 18),
//               ),
//               const SizedBox(width: 12),
//               const Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Location Required',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 13,
//                         color: AppTheme.textPrimary,
//                       ),
//                     ),
//                     SizedBox(height: 2),
//                     Text(
//                       'Tap below to share your location and find nearby centers.',
//                       style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 16),
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton.icon(
//             onPressed: _onFindShelters,
//             icon: const Icon(Icons.search, size: 18),
//             label: const Text('Find Donation Centers'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppTheme.primaryGreen,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 14),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ── Loading Phase ─────────────────────────────────────────────────────────────

//   Widget _buildLoadingPhase(String label, IconData icon) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 32),
//         child: Column(
//           children: [
//             AnimatedBuilder(
//               animation: _pulseAnim,
//               builder: (_, child) => Transform.scale(
//                 scale: _pulseAnim.value,
//                 child: child,
//               ),
//               child: Container(
//                 width: 70,
//                 height: 70,
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: AppTheme.primaryGreen.withValues(alpha: 0.35),
//                       blurRadius: 20,
//                       spreadRadius: 2,
//                     ),
//                   ],
//                 ),
//                 child: Icon(icon, color: Colors.white, size: 32),
//               ),
//             ),
//             const SizedBox(height: 18),
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: AppTheme.textPrimary,
//               ),
//             ),
//             const SizedBox(height: 6),
//             const Text(
//               'This may take a few seconds...',
//               style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
//             ),
//             const SizedBox(height: 20),
//             const SizedBox(
//               width: 200,
//               child: LinearProgressIndicator(
//                 backgroundColor: AppTheme.cardBorder,
//                 color: AppTheme.primaryGreen,
//                 minHeight: 3,
//                 borderRadius: BorderRadius.all(Radius.circular(4)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── AI Result Card ────────────────────────────────────────────────────────────

//   Widget _buildAiResultCard() {
//     final result = _aiResult!;
//     final isSuitable = result.isSuitable;
//     final bgColor = isSuitable ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB);
//     final borderColor = isSuitable ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A);
//     final iconColor = isSuitable ? AppTheme.freshGreen : AppTheme.expiringSoonYellow;
//     final icon = isSuitable ? Icons.check_circle : Icons.warning_amber_rounded;
//     final title = isSuitable ? 'Good news! This item is safe to donate.' : 'Caution — Verify before donating.';

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: bgColor,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: borderColor),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: iconColor, size: 20),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 13.5,
//                     color: iconColor,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             result.reason,
//             style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.4),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                 decoration: BoxDecoration(
//                   color: result.usedAi
//                       ? AppTheme.donateBlue.withValues(alpha: 0.12)
//                       : AppTheme.textMuted.withValues(alpha: 0.12),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       result.usedAi ? Icons.auto_awesome : Icons.data_object,
//                       size: 11,
//                       color: result.usedAi ? AppTheme.donateBlue : AppTheme.textMuted,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       result.usedAi ? 'Verified by AI (Gemini)' : 'Smart Rule-Based Analysis',
//                       style: TextStyle(
//                         fontSize: 10.5,
//                         fontWeight: FontWeight.w600,
//                         color: result.usedAi ? AppTheme.donateBlue : AppTheme.textMuted,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Nearby Centers Section ────────────────────────────────────────────────────

//   Widget _buildNearbySection() {
//     final usedPlaces = _kGooglePlacesApiKeyIsSet();
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             const Text(
//               'Find Donation Centers Near You',
//               style: TextStyle(
//                 fontSize: 15,
//                 fontWeight: FontWeight.bold,
//                 color: AppTheme.textPrimary,
//               ),
//             ),
//             const Spacer(),
//             if (!usedPlaces)
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
//                 decoration: BoxDecoration(
//                   color: AppTheme.textMuted.withValues(alpha: 0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.pin_drop_outlined, size: 11, color: AppTheme.textMuted),
//                     SizedBox(width: 3),
//                     Text(
//                       'Demo Data',
//                       style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//         const SizedBox(height: 4),
//         Text(
//           usedPlaces
//               ? 'We found donation centers near your location.'
//               : 'Showing sample centers. Add Google Places API key for live results.',
//           style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
//         ),
//         const SizedBox(height: 12),
//         ..._centers.map((c) => _DonationCenterTile(
//               center: c,
//               onNavigate: () => _openMaps(c),
//               onCall: c.phone != null ? () => _callPhone(c.phone!) : null,
//             )),
//         const SizedBox(height: 8),
//         GestureDetector(
//           onTap: _openAllOnMap,
//           child: const Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.open_in_new, size: 14, color: AppTheme.donateBlue),
//               SizedBox(width: 5),
//               Text(
//                 'View more centers on map',
//                 style: TextStyle(
//                   fontSize: 12.5,
//                   color: AppTheme.donateBlue,
//                   fontWeight: FontWeight.w600,
//                   decoration: TextDecoration.underline,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   // ── Error Card ────────────────────────────────────────────────────────────────

//   Widget _buildErrorCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFFFEF2F2),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: const Color(0xFFFECACA)),
//       ),
//       child: Column(
//         children: [
//           const Icon(Icons.location_off, color: AppTheme.expiredRed, size: 36),
//           const SizedBox(height: 12),
//           Text(
//             _errorMessage ?? 'Something went wrong.',
//             textAlign: TextAlign.center,
//             style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
//           ),
//           const SizedBox(height: 14),
//           OutlinedButton.icon(
//             onPressed: () => setState(() => _phase = _Phase.initial),
//             icon: const Icon(Icons.refresh, size: 16),
//             label: const Text('Try Again'),
//             style: OutlinedButton.styleFrom(
//               foregroundColor: AppTheme.primaryGreen,
//               side: const BorderSide(color: AppTheme.primaryGreen),
//               minimumSize: const Size(120, 38),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Footer ────────────────────────────────────────────────────────────────────

//   Widget _buildFooter() {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         border: Border(top: BorderSide(color: AppTheme.cardBorder)),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: OutlinedButton(
//               onPressed: () => Navigator.pop(context),
//               style: OutlinedButton.styleFrom(
//                 foregroundColor: AppTheme.textSecondary,
//                 side: const BorderSide(color: AppTheme.cardBorder),
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                 minimumSize: const Size(0, 44),
//               ),
//               child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             flex: 2,
//             child: ElevatedButton.icon(
//               onPressed: _phase == _Phase.results
//                   ? () {
//                       // Select first center if available
//                       Navigator.pop(context);
//                     }
//                   : null,
//               icon: const Icon(Icons.volunteer_activism, size: 17),
//               label: const Text('Proceed to Donate'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppTheme.primaryGreen,
//                 foregroundColor: Colors.white,
//                 disabledBackgroundColor: AppTheme.cardBorder,
//                 disabledForegroundColor: AppTheme.textMuted,
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                 minimumSize: const Size(0, 44),
//                 textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Helpers ───────────────────────────────────────────────────────────────────

//   // Returns true once a real Google Places API key is set in donation_service.dart
//   bool _kGooglePlacesApiKeyIsSet() => false;

//   Color _categoryColor(String category) {
//     switch (category) {
//       case 'Dairy':
//         return AppTheme.donateBlue;
//       case 'Bakery':
//         return AppTheme.warningOrange;
//       case 'Produce':
//         return AppTheme.freshGreen;
//       case 'Meat':
//         return AppTheme.expiredRed;
//       case 'Beverages':
//         return AppTheme.accentGreen;
//       case 'Snacks':
//         return AppTheme.discountPurple;
//       default:
//         return AppTheme.primaryGreen;
//     }
//   }

//   IconData _categoryIcon(String category) {
//     switch (category) {
//       case 'Dairy':
//         return Icons.water_drop_outlined;
//       case 'Bakery':
//         return Icons.bakery_dining_outlined;
//       case 'Produce':
//         return Icons.eco_outlined;
//       case 'Meat':
//         return Icons.kebab_dining_outlined;
//       case 'Beverages':
//         return Icons.local_cafe_outlined;
//       case 'Snacks':
//         return Icons.cookie_outlined;
//       default:
//         return Icons.shopping_bag_outlined;
//     }
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Donation Center Tile
// // ─────────────────────────────────────────────────────────────────────────────

// class _DonationCenterTile extends StatelessWidget {
//   final DonationCenter center;
//   final VoidCallback onNavigate;
//   final VoidCallback? onCall;

//   const _DonationCenterTile({
//     required this.center,
//     required this.onNavigate,
//     this.onCall,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(13),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: AppTheme.cardBorder),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.03),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Avatar
//           Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               color: _typeColor(center.type).withValues(alpha: 0.12),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(_typeIcon(center.type), color: _typeColor(center.type), size: 22),
//           ),
//           const SizedBox(width: 12),
//           // Info
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         center.name,
//                         style: const TextStyle(
//                           fontSize: 13.5,
//                           fontWeight: FontWeight.bold,
//                           color: AppTheme.textPrimary,
//                         ),
//                       ),
//                     ),
//                     _DistanceBadge(km: center.distanceKm),
//                   ],
//                 ),
//                 const SizedBox(height: 3),
//                 // Type chip
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: _typeColor(center.type).withValues(alpha: 0.1),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Text(
//                     center.type,
//                     style: TextStyle(
//                       fontSize: 10.5,
//                       color: _typeColor(center.type),
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 // Rating
//                 if (center.rating != null)
//                   Row(
//                     children: [
//                       ...List.generate(5, (i) {
//                         final filled = i < center.rating!.floor();
//                         final half = !filled && i < center.rating!;
//                         return Icon(
//                           half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
//                           size: 13,
//                           color: const Color(0xFFF59E0B),
//                         );
//                       }),
//                       const SizedBox(width: 5),
//                       Text(
//                         '${center.rating!.toStringAsFixed(1)} (${center.reviewCount ?? 0})',
//                         style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
//                       ),
//                     ],
//                   ),
//                 const SizedBox(height: 4),
//                 // Address
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textMuted),
//                     const SizedBox(width: 3),
//                     Expanded(
//                       child: Text(
//                         center.address,
//                         style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 8),
//           // Action buttons
//           Column(
//             children: [
//               _ActionBtn(
//                 icon: Icons.directions,
//                 color: AppTheme.primaryGreen,
//                 tooltip: 'Get Directions',
//                 onTap: onNavigate,
//               ),
//               if (onCall != null) ...[
//                 const SizedBox(height: 6),
//                 _ActionBtn(
//                   icon: Icons.phone_outlined,
//                   color: AppTheme.donateBlue,
//                   tooltip: 'Call',
//                   onTap: onCall!,
//                 ),
//               ],
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Color _typeColor(String type) {
//     switch (type.toLowerCase()) {
//       case 'gaushala':
//       case 'cattle shelter':
//         return const Color(0xFF8B5CF6);
//       case 'dairy farm':
//         return AppTheme.donateBlue;
//       case 'animal shelter':
//         return AppTheme.warningOrange;
//       case 'food bank':
//       case 'community kitchen':
//         return AppTheme.freshGreen;
//       default:
//         return AppTheme.primaryGreen;
//     }
//   }

//   IconData _typeIcon(String type) {
//     switch (type.toLowerCase()) {
//       case 'gaushala':
//       case 'cattle shelter':
//         return Icons.pets;
//       case 'dairy farm':
//         return Icons.water_drop_outlined;
//       case 'animal shelter':
//         return Icons.cruelty_free;
//       case 'food bank':
//       case 'community kitchen':
//         return Icons.restaurant_outlined;
//       default:
//         return Icons.volunteer_activism;
//     }
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Small Widgets
// // ─────────────────────────────────────────────────────────────────────────────

// class _DistanceBadge extends StatelessWidget {
//   final double km;
//   const _DistanceBadge({required this.km});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//       decoration: BoxDecoration(
//         color: AppTheme.backgroundMint,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: AppTheme.cardBorder),
//       ),
//       child: Text(
//         '${km.toStringAsFixed(1)} km',
//         style: const TextStyle(
//           fontSize: 11,
//           fontWeight: FontWeight.w700,
//           color: AppTheme.primaryGreen,
//         ),
//       ),
//     );
//   }
// }

// class _ActionBtn extends StatelessWidget {
//   final IconData icon;
//   final Color color;
//   final String tooltip;
//   final VoidCallback onTap;

//   const _ActionBtn({
//     required this.icon,
//     required this.color,
//     required this.tooltip,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Tooltip(
//       message: tooltip,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(8),
//         child: Container(
//           padding: const EdgeInsets.all(7),
//           decoration: BoxDecoration(
//             color: color.withValues(alpha: 0.1),
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: color.withValues(alpha: 0.2)),
//           ),
//           child: Icon(icon, size: 18, color: color),
//         ),
//       ),
//     );
//   }
// }

//version 2- ai studio 

// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../models/product_model.dart';
// import '../services/donation_service.dart';
// import '../theme/app_theme.dart';
// import 'package:intl/intl.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// // SHOW DONATE DIALOG
// // ─────────────────────────────────────────────────────────────────────────────

// void showDonateDialog(
//   BuildContext context,
//   ProductModel product,
// ) {
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (_) => _DonateDialog(
//       product: product,
//     ),
//   );
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // PHASE
// // ─────────────────────────────────────────────────────────────────────────────

// enum _Phase {
//   initial,
//   locating,
//   analyzing,
//   results,
//   error,
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // DIALOG
// // ─────────────────────────────────────────────────────────────────────────────

// class _DonateDialog extends StatefulWidget {
//   final ProductModel product;

//   const _DonateDialog({
//     required this.product,
//   });

//   @override
//   State<_DonateDialog> createState() =>
//       _DonateDialogState();
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // STATE
// // ─────────────────────────────────────────────────────────────────────────────

// class _DonateDialogState
//     extends State<_DonateDialog>
//     with SingleTickerProviderStateMixin {
//   _Phase _phase = _Phase.initial;

//   Position? _position;

//   GeminiDonationResult? _aiResult;

//   List<DonationCenter> _centers = [];

//   String? _errorMessage;

//   late AnimationController _pulseController;
//   late Animation<double> _pulseAnim;

//   // ───────────────────────────────────────────────────────────────────────────
//   // INIT
//   // ───────────────────────────────────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();

//     _pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(
//         milliseconds: 1200,
//       ),
//     )..repeat(reverse: true);

//     _pulseAnim = Tween<double>(
//       begin: 0.92,
//       end: 1.08,
//     ).animate(
//       CurvedAnimation(
//         parent: _pulseController,
//         curve: Curves.easeInOut,
//       ),
//     );
//   }

//   // ───────────────────────────────────────────────────────────────────────────
//   // DISPOSE
//   // ───────────────────────────────────────────────────────────────────────────

//   @override
//   void dispose() {
//     _pulseController.dispose();
//     super.dispose();
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // FIND DONATION CENTERS
//   // ═══════════════════════════════════════════════════════════════════════════

//   Future<void> _onFindShelters() async {
//     setState(() {
//       _phase = _Phase.locating;
//       _errorMessage = null;
//       _centers = [];
//       _aiResult = null;
//     });

//     try {
//       // ─────────────────────────────────────────────────────────────────────
//       // 1. GET LOCATION
//       // ─────────────────────────────────────────────────────────────────────

//       LocationPermission permission =
//           await Geolocator.checkPermission();

//       if (permission == LocationPermission.denied) {
//         permission =
//             await Geolocator.requestPermission();
//       }

//       if (permission == LocationPermission.denied ||
//           permission ==
//               LocationPermission.deniedForever) {
//         if (!mounted) return;

//         setState(() {
//           _phase = _Phase.error;
//           _errorMessage =
//               'Location permission denied. Please enable location access to find nearby donation centers.';
//         });

//         return;
//       }

//       try {
//         final pos =
//             await Geolocator.getCurrentPosition(
//           locationSettings:
//               const LocationSettings(
//             accuracy: LocationAccuracy.medium,
//             timeLimit:
//                 Duration(seconds: 10),
//           ),
//         );

//         _position = pos;
//       } catch (_) {
//         // Fallback location.
//         _position = Position(
//           latitude: 28.6139,
//           longitude: 77.2090,
//           timestamp: DateTime.now(),
//           accuracy: 0,
//           altitude: 0,
//           altitudeAccuracy: 0,
//           heading: 0,
//           headingAccuracy: 0,
//           speed: 0,
//           speedAccuracy: 0,
//         );
//       }

//       if (!mounted) return;

//       // ─────────────────────────────────────────────────────────────────────
//       // 2. GEMINI ANALYSIS
//       // ─────────────────────────────────────────────────────────────────────

//       setState(() {
//         _phase = _Phase.analyzing;
//       });

//       final aiResult =
//           await DonationService
//               .assessDonationSuitability(
//         widget.product,
//       );

//       if (!mounted) return;

//       _aiResult = aiResult;

//       // ─────────────────────────────────────────────────────────────────────
//       // 3. GEMINI SAYS UNSAFE / UNKNOWN
//       //
//       // In this case we DO NOT search Google Places.
//       // ─────────────────────────────────────────────────────────────────────

//       if (!aiResult.isSuitable ||
//           aiResult.suggestedOrgTypes.isEmpty) {
//         setState(() {
//           _centers = [];
//           _phase = _Phase.results;
//         });

//         return;
//       }

//       // ─────────────────────────────────────────────────────────────────────
//       // 4. GEMINI FOUND A POTENTIALLY SUITABLE DONATION PATH
//       //
//       // IMPORTANT:
//       //
//       // We intentionally DO NOT check:
//       //
//       // daysRemaining >= 0
//       //
//       // because a product that has not expired yet can still be donated
//       // proactively.
//       //
//       // Example:
//       //
//       // Today  : Aug 13
//       // Expiry : Aug 18
//       // Result : Expires in 5 days
//       //
//       // Gemini can recommend animal feed / Food Bank / NGO etc.
//       // Then Google Places finds relevant nearby centers.
//       // ─────────────────────────────────────────────────────────────────────

//       final centers =
//           await DonationService
//               .findNearbyDonationCenters(
//         latitude: _position!.latitude,
//         longitude: _position!.longitude,
//         orgTypes:
//             aiResult.suggestedOrgTypes,
//       );

//       if (!mounted) return;

//       setState(() {
//         _centers = centers;
//         _phase = _Phase.results;
//       });
//     } catch (_) {
//       if (!mounted) return;

//       setState(() {
//         _phase = _Phase.error;
//         _errorMessage =
//             'Something went wrong while analyzing the product. Please try again.';
//       });
//     }
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // BUILD
//   // ═══════════════════════════════════════════════════════════════════════════

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       insetPadding:
//           const EdgeInsets.symmetric(
//         horizontal: 18,
//         vertical: 24,
//       ),
//       shape: RoundedRectangleBorder(
//         borderRadius:
//             BorderRadius.circular(24),
//       ),
//       child: ConstrainedBox(
//         constraints:
//             const BoxConstraints(
//           maxWidth: 600,
//           maxHeight: 760,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _buildHeader(),
//             Flexible(
//               child: _buildBody(),
//             ),
//             _buildFooter(),
//           ],
//         ),
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // HEADER
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(
//         20,
//         18,
//         12,
//         18,
//       ),
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Color(0xFF15803D),
//             Color(0xFF16A34A),
//           ],
//         ),
//         borderRadius:
//             BorderRadius.vertical(
//           top: Radius.circular(24),
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 42,
//             height: 42,
//             decoration: BoxDecoration(
//               color:
//                   Colors.white.withValues(
//                 alpha: 0.18,
//               ),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.volunteer_activism,
//               color: Colors.white,
//               size: 23,
//             ),
//           ),

//           const SizedBox(width: 12),

//           const Expanded(
//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Donate Item',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight:
//                         FontWeight.w700,
//                   ),
//                 ),
//                 SizedBox(height: 2),
//                 Text(
//                   'Find suitable donation options with AI',
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 11.5,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           IconButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//             icon: const Icon(
//               Icons.close,
//               color: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // BODY
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildBody() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,
//         children: [
//           _buildProductCard(),

//           const SizedBox(height: 16),

//           if (_phase == _Phase.initial)
//             _buildInitialPhase(),

//           if (_phase == _Phase.locating)
//             _buildLoadingPhase(
//               'Getting your location...',
//               Icons.my_location,
//             ),

//           if (_phase == _Phase.analyzing)
//             _buildLoadingPhase(
//               'Gemini is analyzing donation suitability...',
//               Icons.psychology,
//             ),

//           if (_phase == _Phase.results) ...[
//             if (_aiResult != null)
//               _buildAiResultCard(),

//             if (_centers.isNotEmpty) ...[
//               const SizedBox(height: 16),
//               _buildNearbySection(),
//             ],

//             if (_aiResult != null &&
//                 _centers.isEmpty)
//               _buildNoCentersCard(),
//           ],

//           if (_phase == _Phase.error)
//             _buildErrorCard(),
//         ],
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // PRODUCT CARD
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildProductCard() {
//     final daysRemaining =
//         widget.product.daysRemaining;

//     String expiryText;
//     Color expiryColor;
//     IconData expiryIcon;

//     // ───────────────────────────────────────────────────────────────────────
//     // FUTURE EXPIRY
//     // ───────────────────────────────────────────────────────────────────────

//     if (daysRemaining > 0) {
//       expiryText =
//           'Expires in $daysRemaining ${daysRemaining == 1 ? 'day' : 'days'}';

//       expiryColor =
//           daysRemaining <= 7
//               ? Colors.orange
//               : AppTheme.primaryGreen;

//       expiryIcon =
//           Icons.event_available;
//     }

//     // ───────────────────────────────────────────────────────────────────────
//     // EXPIRES TODAY
//     // ───────────────────────────────────────────────────────────────────────

//     else if (daysRemaining == 0) {
//       expiryText = 'Expires today';
//       expiryColor = Colors.orange;
//       expiryIcon =
//           Icons.warning_amber_rounded;
//     }

//     // ───────────────────────────────────────────────────────────────────────
//     // ALREADY EXPIRED
//     // ───────────────────────────────────────────────────────────────────────

//     else {
//       final daysExpired =
//           daysRemaining.abs();

//       expiryText =
//           'Expired $daysExpired ${daysExpired == 1 ? 'day' : 'days'} ago';

//       expiryColor =
//           AppTheme.expiredRed;

//       expiryIcon = Icons.schedule;
//     }

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: daysRemaining < 0
//             ? const Color(0xFFFFF5F5)
//             : const Color(0xFFF0FDF4),
//         borderRadius:
//             BorderRadius.circular(14),
//         border: Border.all(
//           color: daysRemaining < 0
//               ? const Color(0xFFFECACA)
//               : const Color(0xFFBBF7D0),
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 52,
//             height: 52,
//             decoration: BoxDecoration(
//               color: _categoryColor(
//                 widget.product.category,
//               ).withValues(
//                 alpha: 0.12,
//               ),
//               borderRadius:
//                   BorderRadius.circular(12),
//             ),
//             child: Icon(
//               _categoryIcon(
//                 widget.product.category,
//               ),
//               color: _categoryColor(
//                 widget.product.category,
//               ),
//               size: 28,
//             ),
//           ),

//           const SizedBox(width: 14),

//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.product.name,
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight:
//                         FontWeight.bold,
//                     color:
//                         AppTheme.textPrimary,
//                   ),
//                 ),

//                 const SizedBox(height: 3),

//                 Text(
//                   '${widget.product.category}  •  ${widget.product.quantity} units',
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color:
//                         AppTheme.textSecondary,
//                   ),
//                 ),

//                 const SizedBox(height: 5),

//                 Row(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                   children: [
//                     Icon(
//                       expiryIcon,
//                       size: 14,
//                       color: expiryColor,
//                     ),

//                     const SizedBox(width: 4),

//                     Expanded(
//                       child: Text(
//                         '$expiryText  •  ${DateFormat('MMM d, yyyy').format(widget.product.expiryDate)}',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color:
//                               expiryColor,
//                           fontWeight:
//                               FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // INITIAL PHASE
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildInitialPhase() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         Container(
//           width: double.infinity,
//           padding:
//               const EdgeInsets.all(14),
//           decoration: BoxDecoration(
//             color:
//                 const Color(0xFFF0FDF4),
//             borderRadius:
//                 BorderRadius.circular(14),
//             border: Border.all(
//               color:
//                   const Color(0xFFBBF7D0),
//             ),
//           ),
//           child: Row(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,
//             children: [
//               const Icon(
//                 Icons.auto_awesome,
//                 color:
//                     AppTheme.primaryGreen,
//                 size: 20,
//               ),

//               const SizedBox(width: 10),

//               const Expanded(
//                 child: Text(
//                   'Gemini will analyze whether this product could potentially be donated for animal feed or community use. If suitable, we will use your location to find relevant nearby donation centers.',
//                   style: TextStyle(
//                     fontSize: 12.5,
//                     color:
//                         Color(0xFF166534),
//                     height: 1.4,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),

//         const SizedBox(height: 14),

//         Container(
//           width: double.infinity,
//           padding:
//               const EdgeInsets.all(14),
//           decoration: BoxDecoration(
//             color:
//                 const Color(0xFFF8FAFC),
//             borderRadius:
//                 BorderRadius.circular(14),
//             border: Border.all(
//               color:
//                   const Color(0xFFE2E8F0),
//             ),
//           ),
//           child: const Row(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,
//             children: [
//               Icon(
//                 Icons.location_on_outlined,
//                 color:
//                     Color(0xFF2563EB),
//                 size: 21,
//               ),

//               SizedBox(width: 10),

//               Expanded(
//                 child: Text(
//                   'Your location is used only to find relevant nearby donation centers through Google Places.',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color:
//                         Color(0xFF475569),
//                     height: 1.4,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),

//         const SizedBox(height: 16),

//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton.icon(
//             onPressed: _onFindShelters,
//             icon: const Icon(
//               Icons.search,
//             ),
//             label: const Text(
//               'Analyze & Find Donation Centers',
//             ),
//             style: ElevatedButton.styleFrom(
//               backgroundColor:
//                   AppTheme.primaryGreen,
//               foregroundColor:
//                   Colors.white,
//               padding:
//                   const EdgeInsets.symmetric(
//                 vertical: 14,
//               ),
//               shape:
//                   RoundedRectangleBorder(
//                 borderRadius:
//                     BorderRadius.circular(
//                   12,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // LOADING
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildLoadingPhase(
//     String message,
//     IconData icon,
//   ) {
//     return Container(
//       width: double.infinity,
//       padding:
//           const EdgeInsets.symmetric(
//         vertical: 30,
//         horizontal: 20,
//       ),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF8FAFC),
//         borderRadius:
//             BorderRadius.circular(16),
//       ),
//       child: Column(
//         children: [
//           ScaleTransition(
//             scale: _pulseAnim,
//             child: Container(
//               width: 64,
//               height: 64,
//               decoration: BoxDecoration(
//                 color:
//                     AppTheme.primaryGreen
//                         .withValues(
//                   alpha: 0.1,
//                 ),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 icon,
//                 color:
//                     AppTheme.primaryGreen,
//                 size: 30,
//               ),
//             ),
//           ),

//           const SizedBox(height: 16),

//           Text(
//             message,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight:
//                   FontWeight.w600,
//               color:
//                   AppTheme.textPrimary,
//             ),
//           ),

//           const SizedBox(height: 8),

//           const Text(
//             'This may take a few seconds...',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 11.5,
//               color:
//                   AppTheme.textSecondary,
//             ),
//           ),

//           const SizedBox(height: 18),

//           const LinearProgressIndicator(
//             minHeight: 4,
//           ),
//         ],
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // GEMINI RESULT
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildAiResultCard() {
//     final result = _aiResult!;

//     final isSuitable =
//         result.isSuitable;

//     final bgColor = isSuitable
//         ? const Color(0xFFF0FDF4)
//         : const Color(0xFFFFFBEB);

//     final borderColor = isSuitable
//         ? const Color(0xFFBBF7D0)
//         : const Color(0xFFFDE68A);

//     final iconColor = isSuitable
//         ? AppTheme.freshGreen
//         : AppTheme.expiringSoonYellow;

//     final icon = isSuitable
//         ? Icons.check_circle
//         : Icons.warning_amber_rounded;

//     String title;

//     switch (result.donationCategory) {
//       case 'animal_feed':
//         title =
//             'Potentially suitable as animal feed';
//         break;

//       case 'human_consumption':
//         title =
//             'Potentially suitable for community donation';
//         break;

//       case 'non_food_use':
//         title =
//             'Potential non-food donation use';
//         break;

//       case 'unsafe':
//         title = 'Unsafe for donation';
//         break;

//       case 'unknown':
//       default:
//         title =
//             'Caution — Verify before donating';
//         break;
//     }

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: bgColor,
//         borderRadius:
//             BorderRadius.circular(14),
//         border: Border.all(
//           color: borderColor,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,
//         children: [
//           // ────────────────────────────────────────────────────────────────
//           // RESULT HEADER
//           // ────────────────────────────────────────────────────────────────

//           Row(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,
//             children: [
//               Icon(
//                 icon,
//                 color: iconColor,
//                 size: 20,
//               ),

//               const SizedBox(width: 8),

//               Expanded(
//                 child: Text(
//                   title,
//                   style: TextStyle(
//                     fontWeight:
//                         FontWeight.bold,
//                     fontSize: 13.5,
//                     color: iconColor,
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 8),

//           // ────────────────────────────────────────────────────────────────
//           // REASON
//           // ────────────────────────────────────────────────────────────────

//           Text(
//             result.reason,
//             style: const TextStyle(
//               fontSize: 12.5,
//               color:
//                   AppTheme.textSecondary,
//               height: 1.4,
//             ),
//           ),

//           // ────────────────────────────────────────────────────────────────
//           // ANIMALS
//           // ────────────────────────────────────────────────────────────────

//           if (result
//               .suggestedAnimals
//               .isNotEmpty) ...[
//             const SizedBox(height: 14),

//             const Row(
//               children: [
//                 Icon(
//                   Icons.pets,
//                   size: 17,
//                   color:
//                       AppTheme.primaryGreen,
//                 ),
//                 SizedBox(width: 6),
//                 Text(
//                   'Potentially suitable for',
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight:
//                         FontWeight.w700,
//                     color:
//                         AppTheme.textPrimary,
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 8),

//             Wrap(
//               spacing: 6,
//               runSpacing: 6,
//               children: result
//                   .suggestedAnimals
//                   .map(
//                     (animal) {
//                       return Container(
//                         padding:
//                             const EdgeInsets
//                                 .symmetric(
//                           horizontal: 9,
//                           vertical: 5,
//                         ),
//                         decoration:
//                             BoxDecoration(
//                           color: AppTheme
//                               .backgroundMint,
//                           borderRadius:
//                               BorderRadius
//                                   .circular(
//                             20,
//                           ),
//                           border: Border.all(
//                             color: AppTheme
//                                 .cardBorder,
//                           ),
//                         ),
//                         child: Row(
//                           mainAxisSize:
//                               MainAxisSize
//                                   .min,
//                           children: [
//                             const Icon(
//                               Icons.pets,
//                               size: 12,
//                               color: AppTheme
//                                   .primaryGreen,
//                             ),
//                             const SizedBox(
//                                 width: 4),
//                             Text(
//                               animal,
//                               style:
//                                   const TextStyle(
//                                 fontSize:
//                                     11.5,
//                                 fontWeight:
//                                     FontWeight
//                                         .w600,
//                                 color: AppTheme
//                                     .primaryGreen,
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   )
//                   .toList(),
//             ),
//           ],

//           // ────────────────────────────────────────────────────────────────
//           // ORGANIZATION TYPES
//           // ────────────────────────────────────────────────────────────────

//           if (result
//               .suggestedOrgTypes
//               .isNotEmpty) ...[
//             const SizedBox(height: 14),

//             const Row(
//               children: [
//                 Icon(
//                   Icons.location_city_outlined,
//                   size: 17,
//                   color:
//                       AppTheme.donateBlue,
//                 ),
//                 SizedBox(width: 6),
//                 Text(
//                   'Suitable donation categories',
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight:
//                         FontWeight.w700,
//                     color:
//                         AppTheme.textPrimary,
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 8),

//             Wrap(
//               spacing: 6,
//               runSpacing: 6,
//               children: result
//                   .suggestedOrgTypes
//                   .map(
//                     (type) {
//                       return Container(
//                         padding:
//                             const EdgeInsets
//                                 .symmetric(
//                           horizontal: 9,
//                           vertical: 5,
//                         ),
//                         decoration:
//                             BoxDecoration(
//                           color: AppTheme
//                               .donateBlue
//                               .withValues(
//                             alpha: 0.08,
//                           ),
//                           borderRadius:
//                               BorderRadius
//                                   .circular(
//                             20,
//                           ),
//                           border: Border.all(
//                             color: AppTheme
//                                 .donateBlue
//                                 .withValues(
//                               alpha: 0.18,
//                             ),
//                           ),
//                         ),
//                         child: Text(
//                           type,
//                           style:
//                               const TextStyle(
//                             fontSize: 11.5,
//                             fontWeight:
//                                 FontWeight.w600,
//                             color: AppTheme
//                                 .donateBlue,
//                           ),
//                         ),
//                       );
//                     },
//                   )
//                   .toList(),
//             ),
//           ],

//           const SizedBox(height: 12),

//           // ────────────────────────────────────────────────────────────────
//           // GEMINI / FALLBACK BADGE
//           // ────────────────────────────────────────────────────────────────

//           Container(
//             padding:
//                 const EdgeInsets.symmetric(
//               horizontal: 8,
//               vertical: 4,
//             ),
//             decoration: BoxDecoration(
//               color: result.usedAi
//                   ? AppTheme.donateBlue
//                       .withValues(
//                       alpha: 0.12,
//                     )
//                   : AppTheme.textMuted
//                       .withValues(
//                       alpha: 0.12,
//                     ),
//               borderRadius:
//                   BorderRadius.circular(
//                 20,
//               ),
//             ),
//             child: Row(
//               mainAxisSize:
//                   MainAxisSize.min,
//               children: [
//                 Icon(
//                   result.usedAi
//                       ? Icons.auto_awesome
//                       : Icons.data_object,
//                   size: 11,
//                   color: result.usedAi
//                       ? AppTheme.donateBlue
//                       : AppTheme.textMuted,
//                 ),

//                 const SizedBox(width: 4),

//                 Text(
//                   result.usedAi
//                       ? 'Analyzed by Gemini AI'
//                       : 'Smart Rule-Based Analysis',
//                   style: TextStyle(
//                     fontSize: 10.5,
//                     fontWeight:
//                         FontWeight.w600,
//                     color: result.usedAi
//                         ? AppTheme.donateBlue
//                         : AppTheme.textMuted,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // NEARBY SECTION
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildNearbySection() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             const Expanded(
//               child: Text(
//                 'Nearby Donation Centers',
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight:
//                       FontWeight.w700,
//                   color:
//                       AppTheme.textPrimary,
//                 ),
//               ),
//             ),

//             Container(
//               padding:
//                   const EdgeInsets.symmetric(
//                 horizontal: 8,
//                 vertical: 4,
//               ),
//               decoration: BoxDecoration(
//                 color:
//                     _kGooglePlacesApiKeyIsSet()
//                         ? const Color(
//                             0xFFE0F2FE,
//                           )
//                         : const Color(
//                             0xFFFFF7ED,
//                           ),
//                 borderRadius:
//                     BorderRadius.circular(
//                   20,
//                 ),
//               ),
//               child: Text(
//                 _kGooglePlacesApiKeyIsSet()
//                     ? 'Live'
//                     : 'Demo Data',
//                 style: TextStyle(
//                   fontSize: 10,
//                   fontWeight:
//                       FontWeight.w600,
//                   color:
//                       _kGooglePlacesApiKeyIsSet()
//                           ? const Color(
//                               0xFF0369A1,
//                             )
//                           : const Color(
//                               0xFFC2410C,
//                             ),
//                 ),
//               ),
//             ),
//           ],
//         ),

//         const SizedBox(height: 10),

//         ..._centers.map(
//           (center) =>
//               Padding(
//             padding:
//                 const EdgeInsets.only(
//               bottom: 10,
//             ),
//             child:
//                 _DonationCenterTile(
//               center: center,
//               onDirections: () =>
//                   _openMaps(center),
//               onCall: center.phone ==
//                       null
//                   ? null
//                   : () => _callPhone(
//                         center.phone!,
//                       ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // NO CENTERS
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildNoCentersCard() {
//     final result = _aiResult;

//     if (result == null) {
//       return const SizedBox.shrink();
//     }

//     String message;

//     if (!result.isSuitable) {
//       message =
//           'Gemini did not find a sufficiently safe donation option for this product, so nearby donation centers are not being shown.';
//     } else {
//       message =
//           'No suitable donation centers were found for the recommended categories.';
//     }

//     return Container(
//       width: double.infinity,
//       margin:
//           const EdgeInsets.only(top: 16),
//       padding:
//           const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color:
//             const Color(0xFFF8FAFC),
//         borderRadius:
//             BorderRadius.circular(14),
//         border: Border.all(
//           color:
//               const Color(0xFFE2E8F0),
//         ),
//       ),
//       child: Row(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,
//         children: [
//           const Icon(
//             Icons.info_outline,
//             color:
//                 Color(0xFF64748B),
//             size: 20,
//           ),

//           const SizedBox(width: 10),

//           Expanded(
//             child: Text(
//               message,
//               style: const TextStyle(
//                 fontSize: 12,
//                 color:
//                     Color(0xFF475569),
//                 height: 1.4,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // ERROR
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildErrorCard() {
//     return Container(
//       width: double.infinity,
//       padding:
//           const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color:
//             const Color(0xFFFFF5F5),
//         borderRadius:
//             BorderRadius.circular(14),
//         border: Border.all(
//           color:
//               const Color(0xFFFECACA),
//         ),
//       ),
//       child: Column(
//         children: [
//           const Icon(
//             Icons.error_outline,
//             color:
//                 Color(0xFFDC2626),
//             size: 32,
//           ),

//           const SizedBox(height: 8),

//           Text(
//             _errorMessage ??
//                 'Something went wrong.',
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               fontSize: 12.5,
//               color:
//                   Color(0xFF991B1B),
//               height: 1.4,
//             ),
//           ),

//           const SizedBox(height: 12),

//           OutlinedButton.icon(
//             onPressed: _onFindShelters,
//             icon: const Icon(
//               Icons.refresh,
//             ),
//             label: const Text(
//               'Try Again',
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // FOOTER
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildFooter() {
//     final canProceed =
//         _phase == _Phase.results &&
//         _aiResult != null &&
//         _aiResult!.isSuitable;

//     return Container(
//       padding:
//           const EdgeInsets.fromLTRB(
//         20,
//         10,
//         20,
//         18,
//       ),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.vertical(
//           bottom: Radius.circular(24),
//         ),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: OutlinedButton(
//               onPressed: () {
//                 Navigator.of(context)
//                     .pop();
//               },
//               style:
//                   OutlinedButton.styleFrom(
//                 padding:
//                     const EdgeInsets
//                         .symmetric(
//                   vertical: 13,
//                 ),
//                 shape:
//                     RoundedRectangleBorder(
//                   borderRadius:
//                       BorderRadius.circular(
//                     12,
//                   ),
//                 ),
//               ),
//               child:
//                   const Text('Close'),
//             ),
//           ),

//           const SizedBox(width: 10),

//           Expanded(
//             child: ElevatedButton(
//               onPressed: canProceed
//                   ? () {
//                       Navigator.of(context)
//                           .pop();
//                     }
//                   : null,
//               style:
//                   ElevatedButton.styleFrom(
//                 backgroundColor:
//                     AppTheme.primaryGreen,
//                 foregroundColor:
//                     Colors.white,
//                 disabledBackgroundColor:
//                     Colors.grey.shade200,
//                 disabledForegroundColor:
//                     Colors.grey.shade500,
//                 padding:
//                     const EdgeInsets
//                         .symmetric(
//                   vertical: 13,
//                 ),
//                 shape:
//                     RoundedRectangleBorder(
//                   borderRadius:
//                       BorderRadius.circular(
//                     12,
//                   ),
//                 ),
//               ),
//               child: const Text(
//                 'Proceed to Donate',
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // OPEN GOOGLE MAPS
//   // ═══════════════════════════════════════════════════════════════════════════

//   Future<void> _openMaps(
//     DonationCenter center,
//   ) async {
//     final uri =
//         Uri.parse(center.googleMapsUrl);

//     if (await canLaunchUrl(uri)) {
//       await launchUrl(
//         uri,
//         mode:
//             LaunchMode.externalApplication,
//       );
//     }
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // CALL
//   // ═══════════════════════════════════════════════════════════════════════════

//   Future<void> _callPhone(
//     String phone,
//   ) async {
//     final uri =
//         Uri.parse('tel:$phone');

//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     }
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // GOOGLE PLACES KEY CHECK
//   // ═══════════════════════════════════════════════════════════════════════════

//   bool _kGooglePlacesApiKeyIsSet() {
//     // Keep false for now because the current Places implementation
//     // intentionally uses demo data when the placeholder key is present.
//     return false;
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // CATEGORY COLOR
//   // ═══════════════════════════════════════════════════════════════════════════

//   Color _categoryColor(
//     String category,
//   ) {
//     switch (category.toLowerCase()) {
//       case 'dairy':
//       case 'milk':
//         return Colors.blue;

//       case 'meat':
//       case 'fish':
//       case 'seafood':
//         return Colors.red;

//       case 'fruits':
//       case 'vegetables':
//       case 'produce':
//         return Colors.green;

//       case 'snacks':
//         return Colors.orange;

//       case 'beverages':
//         return Colors.purple;

//       case 'bakery':
//         return Colors.brown;

//       case 'pantry':
//       case 'grains':
//       case 'flour':
//       case 'cereals':
//         return Colors.amber;

//       default:
//         return AppTheme.primaryGreen;
//     }
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // CATEGORY ICON
//   // ═══════════════════════════════════════════════════════════════════════════

//   IconData _categoryIcon(
//     String category,
//   ) {
//     switch (category.toLowerCase()) {
//       case 'dairy':
//       case 'milk':
//         return Icons.local_drink;

//       case 'meat':
//         return Icons.set_meal;

//       case 'fish':
//       case 'seafood':
//         return Icons.phishing;

//       case 'fruits':
//       case 'vegetables':
//       case 'produce':
//         return Icons.eco;

//       case 'snacks':
//         return Icons.cookie;

//       case 'beverages':
//         return Icons.local_cafe;

//       case 'bakery':
//         return Icons.bakery_dining;

//       case 'pantry':
//       case 'grains':
//       case 'flour':
//       case 'cereals':
//         return Icons.grass;

//       default:
//         return Icons.inventory_2_outlined;
//     }
//   }
// }

// // ═════════════════════════════════════════════════════════════════════════════
// // DONATION CENTER TILE
// // ═════════════════════════════════════════════════════════════════════════════

// class _DonationCenterTile
//     extends StatelessWidget {
//   final DonationCenter center;
//   final VoidCallback onDirections;
//   final VoidCallback? onCall;

//   const _DonationCenterTile({
//     required this.center,
//     required this.onDirections,
//     required this.onCall,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding:
//           const EdgeInsets.all(13),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.circular(14),
//         border: Border.all(
//           color:
//               const Color(0xFFE2E8F0),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black
//                 .withValues(alpha: 0.03),
//             blurRadius: 8,
//             offset:
//                 const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,
//         children: [
//           Row(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 42,
//                 height: 42,
//                 decoration: BoxDecoration(
//                   color:
//                       _typeColor(center.type)
//                           .withValues(
//                     alpha: 0.1,
//                   ),
//                   borderRadius:
//                       BorderRadius.circular(
//                     11,
//                   ),
//                 ),
//                 child: Icon(
//                   _typeIcon(center.type),
//                   color:
//                       _typeColor(
//                     center.type,
//                   ),
//                   size: 22,
//                 ),
//               ),

//               const SizedBox(width: 10),

//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       center.name,
//                       style:
//                           const TextStyle(
//                         fontSize: 13.5,
//                         fontWeight:
//                             FontWeight.w700,
//                         color: AppTheme
//                             .textPrimary,
//                       ),
//                     ),

//                     const SizedBox(height: 4),

//                     Row(
//                       children: [
//                         _DistanceBadge(
//                           distanceKm:
//                               center.distanceKm,
//                         ),

//                         const SizedBox(
//                             width: 6),

//                         Container(
//                           padding:
//                               const EdgeInsets
//                                   .symmetric(
//                             horizontal: 7,
//                             vertical: 3,
//                           ),
//                           decoration:
//                               BoxDecoration(
//                             color:
//                                 _typeColor(
//                               center.type,
//                             ).withValues(
//                               alpha: 0.1,
//                             ),
//                             borderRadius:
//                                 BorderRadius
//                                     .circular(
//                               20,
//                             ),
//                           ),
//                           child: Text(
//                             center.type,
//                             style:
//                                 TextStyle(
//                               fontSize: 9.5,
//                               fontWeight:
//                                   FontWeight
//                                       .w600,
//                               color:
//                                   _typeColor(
//                                 center.type,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 10),

//           Text(
//             center.address,
//             style: const TextStyle(
//               fontSize: 11.5,
//               color:
//                   AppTheme.textSecondary,
//               height: 1.35,
//             ),
//           ),

//           const SizedBox(height: 9),

//           Row(
//             children: [
//               if (center.rating != null) ...[
//                 const Icon(
//                   Icons.star,
//                   size: 15,
//                   color: Colors.amber,
//                 ),

//                 const SizedBox(width: 3),

//                 Text(
//                   center.rating!
//                       .toStringAsFixed(1),
//                   style:
//                       const TextStyle(
//                     fontSize: 11,
//                     fontWeight:
//                         FontWeight.w600,
//                   ),
//                 ),

//                 if (center.reviewCount !=
//                     null) ...[
//                   const SizedBox(width: 3),
//                   Text(
//                     '(${center.reviewCount})',
//                     style:
//                         const TextStyle(
//                       fontSize: 10,
//                       color:
//                           AppTheme.textMuted,
//                     ),
//                   ),
//                 ],

//                 const Spacer(),
//               ] else
//                 const Spacer(),

//               _ActionBtn(
//                 icon:
//                     Icons.directions,
//                 label: 'Directions',
//                 onPressed:
//                     onDirections,
//               ),

//               if (onCall != null) ...[
//                 const SizedBox(width: 6),
//                 _ActionBtn(
//                   icon:
//                       Icons.phone_outlined,
//                   label: 'Call',
//                   onPressed: onCall!,
//                 ),
//               ],
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Color _typeColor(
//     String type,
//   ) {
//     switch (type.toLowerCase()) {
//       case 'gaushala':
//       case 'cattle shelter':
//       case 'dairy farm':
//         return Colors.green;

//       case 'animal shelter':
//         return Colors.orange;

//       case 'poultry farm':
//       case 'poultry':
//         return Colors.amber.shade800;

//       case 'food bank':
//       case 'community kitchen':
//         return Colors.blue;

//       case 'ngo':
//         return Colors.purple;

//       default:
//         return AppTheme.primaryGreen;
//     }
//   }

//   IconData _typeIcon(
//     String type,
//   ) {
//     switch (type.toLowerCase()) {
//       case 'gaushala':
//       case 'cattle shelter':
//       case 'dairy farm':
//         return Icons.agriculture;

//       case 'animal shelter':
//         return Icons.pets;

//       case 'poultry farm':
//       case 'poultry':
//         return Icons.egg;

//       case 'food bank':
//         return Icons.inventory_2_outlined;

//       case 'community kitchen':
//         return Icons.restaurant;

//       case 'ngo':
//         return Icons.volunteer_activism;

//       default:
//         return Icons.location_city;
//     }
//   }
// }

// // ═════════════════════════════════════════════════════════════════════════════
// // DISTANCE BADGE
// // ═════════════════════════════════════════════════════════════════════════════

// class _DistanceBadge
//     extends StatelessWidget {
//   final double distanceKm;

//   const _DistanceBadge({
//     required this.distanceKm,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding:
//           const EdgeInsets.symmetric(
//         horizontal: 7,
//         vertical: 3,
//       ),
//       decoration: BoxDecoration(
//         color:
//             const Color(0xFFF1F5F9),
//         borderRadius:
//             BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize:
//             MainAxisSize.min,
//         children: [
//           const Icon(
//             Icons.near_me,
//             size: 11,
//             color:
//                 Color(0xFF64748B),
//           ),

//           const SizedBox(width: 3),

//           Text(
//             '${distanceKm.toStringAsFixed(1)} km',
//             style: const TextStyle(
//               fontSize: 9.5,
//               fontWeight:
//                   FontWeight.w600,
//               color:
//                   Color(0xFF475569),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ═════════════════════════════════════════════════════════════════════════════
// // ACTION BUTTON
// // ═════════════════════════════════════════════════════════════════════════════

// class _ActionBtn
//     extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback onPressed;

//   const _ActionBtn({
//     required this.icon,
//     required this.label,
//     required this.onPressed,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onPressed,
//       borderRadius:
//           BorderRadius.circular(8),
//       child: Container(
//         padding:
//             const EdgeInsets.symmetric(
//           horizontal: 8,
//           vertical: 6,
//         ),
//         decoration: BoxDecoration(
//           border: Border.all(
//             color:
//                 const Color(0xFFE2E8F0),
//           ),
//           borderRadius:
//               BorderRadius.circular(8),
//         ),
//         child: Row(
//           mainAxisSize:
//               MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               size: 13,
//               color:
//                   AppTheme.primaryGreen,
//             ),

//             const SizedBox(width: 4),

//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 10,
//                 fontWeight:
//                     FontWeight.w600,
//                 color:
//                     AppTheme.primaryGreen,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// version 3 - cloud func

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../models/product_model.dart';
import '../services/donation_service.dart';

class DonateDialog extends StatefulWidget {
  final ProductModel product;

  const DonateDialog({
    super.key,
    required this.product,
  });

  @override
  State<DonateDialog> createState() => _DonateDialogState();
}

class _DonateDialogState extends State<DonateDialog>
    with SingleTickerProviderStateMixin {
  /* ======================================================================== */
  /* STATE                                                                    */
  /* ======================================================================== */

  _Phase _phase = _Phase.initial;

  GeminiDonationResult? _aiResult;

  List<DonationCenter> _centers = [];

  String? _errorMessage;

  late AnimationController _pulseController;

  late Animation<double> _pulseAnim;

  /* ======================================================================== */
  /* LIFECYCLE                                                                */
  /* ======================================================================== */

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1200,
      ),
    );

    _pulseAnim = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /* ======================================================================== */
  /* FIND DONATION OPTIONS                                                    */
  /* ======================================================================== */

  Future<void> _onFindShelters() async {
    setState(() {
      _phase = _Phase.locating;
      _errorMessage = null;
      _centers = [];
      _aiResult = null;
    });

    _pulseController.repeat(
      reverse: true,
    );

    try {
      /*
       * IMPORTANT:
       *
       * We do NOT request device/browser location.
       *
       * The backend gets:
       *
       * Firebase Auth UID
       *       ↓
       * Firestore users/{uid}
       *       ↓
       * location: "Lucknow"
       */

      await Future<void>.delayed(
        const Duration(
          milliseconds: 300,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _phase = _Phase.analyzing;
      });

      final result =
          await DonationService.assessAndFindDonationOptions(
        product: widget.product,
      );

      if (!mounted) {
        return;
      }

      _pulseController.stop();

      setState(() {
        _aiResult = result.donation;
        _centers = result.centers;
        _phase = _Phase.results;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _pulseController.stop();

      setState(() {
        _phase = _Phase.error;

        _errorMessage = error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  /* ======================================================================== */
  /* OPEN GOOGLE MAPS                                                         */
  /* ======================================================================== */

  Future<void> _openMaps(
    DonationCenter center,
  ) async {
    final url = center.googleMapsUrl;

    if (url.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open Google Maps.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open Google Maps.',
          ),
        ),
      );
    }
  }

  /* ======================================================================== */
  /* CALL PHONE                                                               */
  /* ======================================================================== */

  Future<void> _callPhone(
    String phone,
  ) async {
    final cleaned = phone.trim();

    if (cleaned.isEmpty) {
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: cleaned,
    );

    try {
      final launched = await launchUrl(uri);

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not make the call.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not make the call.',
          ),
        ),
      );
    }
  }

  /* ======================================================================== */
  /* DATE FORMATTING                                                          */
  /* ======================================================================== */

  String _formattedExpiryDate() {
    try {
      return DateFormat(
        'dd MMM yyyy',
      ).format(
        widget.product.expiryDate,
      );
    } catch (_) {
      return widget.product.expiryDate.toString();
    }
  }

  /* ======================================================================== */
  /* DONATION CATEGORY TITLE                                                  */
  /* ======================================================================== */

  String _categoryTitle(
    String category,
  ) {
    switch (category) {
      case 'animal_feed':
        return 'Potentially suitable as animal feed';

      case 'human_consumption':
        return 'Potentially suitable for community donation';

      case 'non_food_use':
        return 'Potential non-food donation use';

      case 'unsafe':
        return 'Unsafe for donation';

      case 'unknown':
      default:
        return 'Caution — Verify before donating';
    }
  }

  /* ======================================================================== */
  /* DONATION CATEGORY ICON                                                   */
  /* ======================================================================== */

  IconData _categoryIcon(
    String category,
  ) {
    switch (category) {
      case 'animal_feed':
        return Icons.pets_outlined;

      case 'human_consumption':
        return Icons.volunteer_activism_outlined;

      case 'non_food_use':
        return Icons.recycling_outlined;

      case 'unsafe':
        return Icons.warning_amber_rounded;

      case 'unknown':
      default:
        return Icons.help_outline_rounded;
    }
  }

  /* ======================================================================== */
  /* CATEGORY COLOR                                                           */
  /* ======================================================================== */

  Color _categoryColor(
    String category,
  ) {
    switch (category) {
      case 'animal_feed':
        return Colors.green;

      case 'human_consumption':
        return Colors.teal;

      case 'non_food_use':
        return Colors.blue;

      case 'unsafe':
        return Colors.red;

      case 'unknown':
      default:
        return Colors.orange;
    }
  }

  /* ======================================================================== */
  /* TYPE ICON                                                                */
  /* ======================================================================== */

  IconData _typeIcon(
    String type,
  ) {
    final value = type.toLowerCase();

    if (value.contains('gaushala')) {
      return Icons.agriculture_outlined;
    }

    if (value.contains('cattle')) {
      return Icons.agriculture_outlined;
    }

    if (value.contains('animal')) {
      return Icons.pets_outlined;
    }

    if (value.contains('dairy')) {
      return Icons.water_drop_outlined;
    }

    if (value.contains('poultry')) {
      return Icons.egg_alt_outlined;
    }

    if (value.contains('food bank')) {
      return Icons.inventory_2_outlined;
    }

    if (value.contains('community kitchen')) {
      return Icons.restaurant_outlined;
    }

    if (value.contains('ngo')) {
      return Icons.volunteer_activism_outlined;
    }

    return Icons.location_on_outlined;
  }

  /* ======================================================================== */
  /* BUILD                                                                    */
  /* ======================================================================== */

  @override
  Widget build(
    BuildContext context,
  ) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 720,
          maxHeight: 760,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.15,
              ),
              blurRadius: 30,
              offset: const Offset(
                0,
                12,
              ),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    20,
                    24,
                    16,
                  ),
                  child: _buildContent(),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  /* ======================================================================== */
  /* HEADER                                                                   */
  /* ======================================================================== */

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        24,
        22,
        18,
        22,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF16A34A),
            Color(0xFF15803D),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.18,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.volunteer_activism_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Donate Item',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Find suitable donation options with AI',
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.88,
                    ),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /* ======================================================================== */
  /* CONTENT                                                                  */
  /* ======================================================================== */

  Widget _buildContent() {
    switch (_phase) {
      case _Phase.initial:
        return _buildInitial();

      case _Phase.locating:
        return _buildLoading(
          title: 'Getting your saved location...',
          subtitle:
              'Checking your saved city to find nearby donation options.',
        );

      case _Phase.analyzing:
        return _buildLoading(
          title: 'Gemini is analyzing donation suitability...',
          subtitle:
              'We are checking whether this item can be safely donated and finding relevant organizations.',
        );

      case _Phase.results:
        return _buildResults();

      case _Phase.error:
        return _buildError();
    }
  }

  /* ======================================================================== */
  /* PRODUCT CARD                                                             */
  /* ======================================================================== */

  Widget _buildProductCard() {
    final product = widget.product;

    final isExpired = product.isExpired;

    final isExpiringSoon = product.isExpiringSoon;

    /*
     * ProductModel.brand is String?, so always safely convert
     * null into an empty string before using trim().
     */
    final brand = (product.brand ?? '').trim();

    Color statusColor;

    String statusText;

    IconData statusIcon;

    if (isExpired) {
      statusColor = Colors.red;
      statusText = 'Expired';
      statusIcon = Icons.error_outline;
    } else if (isExpiringSoon) {
      statusColor = Colors.orange;
      statusText = 'Expiring Soon';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = Colors.green;
      statusText = 'Fresh';
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),

                /*
                 * FIX:
                 *
                 * product.brand is nullable.
                 * We use the safe local `brand` variable.
                 */
                if (brand.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    brand,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],

                const SizedBox(height: 7),

                Row(
                  children: [
                    Icon(
                      statusIcon,
                      size: 15,
                      color: statusColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Expiry: ${_formattedExpiryDate()}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* ======================================================================== */
  /* INITIAL                                                                  */
  /* ======================================================================== */

  Widget _buildInitial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductCard(),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFBBF7D0),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF16A34A),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI-powered donation check',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF166534),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Gemini will analyze this product for donation suitability. We will then use your saved city to find relevant nearby donation organizations.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: const Color(0xFF166534).withValues(
                          alpha: 0.78,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _onFindShelters,
            icon: const Icon(
              Icons.search_rounded,
            ),
            label: const Text(
              'Find Donation Options',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /* ======================================================================== */
  /* LOADING                                                                  */
  /* ======================================================================== */

  Widget _buildLoading({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductCard(),
        const SizedBox(height: 26),
        Center(
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (
              context,
              child,
            ) {
              return Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF16A34A),
                    size: 32,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFF16A34A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /* ======================================================================== */
  /* RESULTS                                                                  */
  /* ======================================================================== */

  Widget _buildResults() {
    final result = _aiResult;

    if (result == null) {
      return _buildError(
        customMessage:
            'Donation analysis could not be loaded.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductCard(),

        const SizedBox(height: 18),

        _buildAiResultCard(result),

        if (result.suggestedAnimals.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildAnimalsSection(result),
        ],

        if (result.suggestedOrgTypes.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildOrganizationTypesSection(result),
        ],

        const SizedBox(height: 22),

        _buildNearbyCentersHeader(),

        const SizedBox(height: 10),

        if (_centers.isEmpty)
          _buildNoCenters()
        else
          ..._centers.map(
            (center) => Padding(
              padding: const EdgeInsets.only(
                bottom: 10,
              ),
              child: _DonationCenterTile(
                center: center,
                typeIcon: _typeIcon(center.type),
                onDirections: () => _openMaps(center),
                onCall: center.phone != null &&
                        center.phone!.trim().isNotEmpty
                    ? () => _callPhone(
                          center.phone!,
                        )
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  /* ======================================================================== */
  /* AI RESULT CARD                                                           */
  /* ======================================================================== */

  Widget _buildAiResultCard(
    GeminiDonationResult result,
  ) {
    final category = result.donationCategory;

    final color = _categoryColor(category);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(category),
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categoryTitle(category),
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        result.usedAi
                            ? 'AI Analysis'
                            : 'Analysis Unavailable',
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'Recommendation',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            result.reason,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  /* ======================================================================== */
  /* ANIMALS                                                                  */
  /* ======================================================================== */

  Widget _buildAnimalsSection(
    GeminiDonationResult result,
  ) {
    return _sectionCard(
      title: 'Potentially suitable for',
      icon: Icons.pets_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: result.suggestedAnimals
            .map(
              (animal) => _chip(
                animal,
                Icons.pets_outlined,
              ),
            )
            .toList(),
      ),
    );
  }

  /* ======================================================================== */
  /* ORGANIZATION TYPES                                                       */
  /* ======================================================================== */

  Widget _buildOrganizationTypesSection(
    GeminiDonationResult result,
  ) {
    return _sectionCard(
      title: 'Recommended organization types',
      icon: Icons.business_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: result.suggestedOrgTypes
            .map(
              (type) => _chip(
                type,
                _typeIcon(type),
              ),
            )
            .toList(),
      ),
    );
  }

  /* ======================================================================== */
  /* NEARBY CENTERS HEADER                                                    */
  /* ======================================================================== */

  Widget _buildNearbyCentersHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Nearby Donation Centers',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_done_outlined,
                size: 13,
                color: Color(0xFF15803D),
              ),
              SizedBox(width: 4),
              Text(
                'Live',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF15803D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /* ======================================================================== */
  /* NO CENTERS                                                               */
  /* ======================================================================== */

  Widget _buildNoCenters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_off_outlined,
              color: Color(0xFF64748B),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No nearby donation centers found',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'The item may still be suitable for donation. Try again later or check local organizations manually.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  /* ======================================================================== */
  /* ERROR                                                                    */
  /* ======================================================================== */

  Widget _buildError({
    String? customMessage,
  }) {
    final message = customMessage ??
        _errorMessage ??
        'Something went wrong while analyzing the product.';

    return Column(
      children: [
        _buildProductCard(),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFECACA),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Unable to find donation options',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF991B1B),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: Color(0xFF7F1D1D),
                ),
              ),
              const SizedBox(height: 17),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _onFindShelters,
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                  label: const Text(
                    'Try Again',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(
                      color: Color(0xFFFCA5A5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /* ======================================================================== */
  /* SECTION CARD                                                             */
  /* ======================================================================== */

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: const Color(0xFF16A34A),
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /* ======================================================================== */
  /* CHIP                                                                     */
  /* ======================================================================== */

  Widget _chip(
    String text,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF16A34A),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }

  /* ======================================================================== */
  /* FOOTER                                                                   */
  /* ======================================================================== */

  Widget _buildFooter() {
    final canProceed = _phase == _Phase.results &&
        _aiResult != null &&
        _aiResult!.isSuitable &&
        _centers.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        14,
        24,
        20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                side: const BorderSide(
                  color: Color(0xFFCBD5E1),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                'Close',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: canProceed
                  ? _proceedToDonate
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    const Color(0xFFE2E8F0),
                disabledForegroundColor:
                    const Color(0xFF94A3B8),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                'Proceed to Donate',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ======================================================================== */
  /* PROCEED                                                                  */
  /* ======================================================================== */

  void _proceedToDonate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Donation option selected. Please contact the organization before donating.',
        ),
      ),
    );
  }
}

/* ========================================================================== */
/* DONATION CENTER TILE                                                       */
/* ========================================================================== */

class _DonationCenterTile extends StatelessWidget {
  final DonationCenter center;

  final IconData typeIcon;

  final VoidCallback onDirections;

  final VoidCallback? onCall;

  const _DonationCenterTile({
    required this.center,
    required this.typeIcon,
    required this.onDirections,
    required this.onCall,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  typeIcon,
                  color: const Color(0xFF16A34A),
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      center.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        center.type,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (center.address.trim().isNotEmpty) ...[
            const SizedBox(height: 11),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    center.address,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 11),

          Row(
            children: [
              if (center.rating != null) ...[
                const Icon(
                  Icons.star_rounded,
                  size: 15,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 3),
                Text(
                  center.rating!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                if (center.reviewCount != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${center.reviewCount})',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],

              /*
               * Distance is intentionally optional because your
               * backend currently searches using the saved CITY,
               * not the user's GPS coordinates.
               */
              if (center.distanceKm != null &&
                  center.distanceKm! > 0) ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.near_me_outlined,
                  size: 14,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 3),
                Text(
                  '${center.distanceKm!.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDirections,
                  icon: const Icon(
                    Icons.directions_outlined,
                    size: 16,
                  ),
                  label: const Text(
                    'Directions',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF15803D),
                    side: const BorderSide(
                      color: Color(0xFFBBF7D0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),

              if (onCall != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCall,
                    icon: const Icon(
                      Icons.phone_outlined,
                      size: 16,
                    ),
                    label: const Text(
                      'Call',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          const Color(0xFF15803D),
                      side: const BorderSide(
                        color: Color(0xFFBBF7D0),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/* ========================================================================== */
/* HELPER TYPES                                                               */
/* ========================================================================== */

enum _Phase {
  initial,
  locating,
  analyzing,
  results,
  error,
}