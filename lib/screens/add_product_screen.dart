// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:image_picker/image_picker.dart';
// import '../models/product_model.dart';
// import '../providers/product_provider.dart';
// import '../services/gemini_extraction_service.dart';
// import '../theme/app_theme.dart';

// enum ProductInputMethod { manual, upload }

// class AddProductScreen extends StatefulWidget {
//   final VoidCallback? onItemAdded;

//   const AddProductScreen({super.key, this.onItemAdded});

//   @override
//   State<AddProductScreen> createState() => _AddProductScreenState();
// }

// class _AddProductScreenState extends State<AddProductScreen> {
//   final _formKey = GlobalKey<FormState>();

//   ProductInputMethod _selectedMethod = ProductInputMethod.manual;

//   // Form Field Controllers
//   final _nameController = TextEditingController();
//   final _brandController = TextEditingController();
//   final _quantityController = TextEditingController();
//   final _priceController = TextEditingController();
//   final _batchNumberController = TextEditingController();

//   String _selectedCategory = 'Dairy';
//   DateTime? _expiryDate;
//   final List<String> _uploadedImages = [];

//   bool _isAnalyzing = false;
//   String? _scanningStatusText;

//   final List<String> _categories = [
//     'Dairy',
//     'Bakery',
//     'Beverages',
//     'Snacks',
//     'Produce',
//     'Pulses',
//     'Spices',
//     'Pantry',
//     'Personal Care',
//     'Household',
//     'Others'
//   ];

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _brandController.dispose();
//     _quantityController.dispose();
//     _priceController.dispose();
//     _batchNumberController.dispose();
//     super.dispose();
//   }

//   // Calculate dynamic suggested selling price card details
//   double? get _suggestedSellingPrice {
//     final priceStr = _priceController.text.trim();
//     if (priceStr.isEmpty || _expiryDate == null) return null;
//     final price = double.tryParse(priceStr);
//     if (price == null) return null;

//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final expiry = DateTime(_expiryDate!.year, _expiryDate!.month, _expiryDate!.day);
//     final daysRemaining = expiry.difference(today).inDays;

//     if (daysRemaining < 0) return 0.0;
//     if (daysRemaining <= 3) return price * 0.75;
//     if (daysRemaining <= 5) return price * 0.90;
//     if (daysRemaining <= 7) return price * 0.95;
//     return price;
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final initialDate = _expiryDate ?? DateTime.now().add(const Duration(days: 14));

//     final picked = await showDatePicker(
//       context: context,
//       initialDate: initialDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2035),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: AppTheme.primaryGreen,
//               onPrimary: Colors.white,
//               onSurface: AppTheme.textPrimary,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null) {
//       setState(() {
//         _expiryDate = picked;
//       });
//     }
//   }

//   // Run Gemini Extraction logic
//   Future<void> _triggerGeminiAIExtraction(String source) async {
//     setState(() {
//       _isAnalyzing = true;
//       _scanningStatusText = 'Analyzing $source with Gemini AI...';
//     });

//     try {
//       final extracted = await GeminiExtractionService.extractProductFromImage(source);

//       if (!mounted) return;

//       setState(() {
//         if (extracted.productName != null) _nameController.text = extracted.productName!;
//         if (extracted.brand != null) _brandController.text = extracted.brand!;
//         if (extracted.category != null && _categories.contains(extracted.category)) {
//           _selectedCategory = extracted.category!;
//         }
//         if (extracted.quantitySize != null) _quantityController.text = extracted.quantitySize!;
//         if (extracted.price != null) _priceController.text = extracted.price.toString();
//         if (extracted.expiryDate != null) _expiryDate = extracted.expiryDate;
//         if (extracted.batchNumber != null) _batchNumberController.text = extracted.batchNumber!;

//         // Add a demo mock image if non uploaded
//         if (_uploadedImages.isEmpty) {
//           _uploadedImages.add('assets/images/milk.png');
//         }

//         _isAnalyzing = false;
//         _selectedMethod = ProductInputMethod.manual; // Switch back to form preview
//       });

//       final missing = extracted.missingRequiredFields;
//       if (missing.isNotEmpty) {
//         _showMissingFieldsPrompt(missing);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('✨ Product details extracted successfully via Gemini AI!'),
//             backgroundColor: AppTheme.primaryGreen,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _isAnalyzing = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Extraction failed: $e'),
//           backgroundColor: AppTheme.expiredRed,
//         ),
//       );
//     }
//   }

//   void _showMissingFieldsPrompt(List<String> missingFields) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Row(
//           children: [
//             Icon(Icons.info_outline_rounded, color: AppTheme.warningOrange),
//             SizedBox(width: 8),
//             Text('Complete Missing Details'),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Gemini extracted most product details, but couldn\'t confidently identify the following required fields:',
//               style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
//             ),
//             const SizedBox(height: 12),
//             ...missingFields.map((field) => Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 4.0),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.warningOrange),
//                       const SizedBox(width: 8),
//                       Text(field, style: const TextStyle(fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                 )),
//             const SizedBox(height: 12),
//             const Text(
//               'Please complete these fields in the form below before saving.',
//               style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
//             ),
//           ],
//         ),
//         actions: [
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
//             onPressed: () => Navigator.of(ctx).pop(),
//             child: const Text('OK, Fill Manually'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please fill all required fields before saving.'),
//           backgroundColor: AppTheme.expiredRed,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       return;
//     }

//     if (_expiryDate == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select an Expiry Date for the product.'),
//           backgroundColor: AppTheme.expiredRed,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       return;
//     }

//     // Parse quantity
//     int qty = 1;
//     final qtyMatches = RegExp(r'\d+').firstMatch(_quantityController.text);
//     if (qtyMatches != null) {
//       qty = int.tryParse(qtyMatches.group(0)!) ?? 1;
//     }

//     final newProduct = ProductModel(
//       id: '',
//       name: _nameController.text.trim(),
//       category: _selectedCategory,
//       expiryDate: _expiryDate!,
//       originalPrice: double.parse(_priceController.text.trim()),
//       quantity: qty,
//       brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
//       batchNumber: _batchNumberController.text.trim(),
//       images: List.from(_uploadedImages),
//     );

//     final productProvider = Provider.of<ProductProvider>(context, listen: false);
//     final success = await productProvider.addProduct(newProduct);

//     if (mounted) {
//       if (success) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Successfully added "${newProduct.name}" to inventory!'),
//             backgroundColor: AppTheme.primaryGreen,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//         if (widget.onItemAdded != null) {
//           widget.onItemAdded!();
//         } else if (Navigator.of(context).canPop()) {
//           Navigator.of(context).pop();
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final isDesktop = size.width > 900;

//     return SingleChildScrollView(
//       padding: EdgeInsets.symmetric(
//         horizontal: isDesktop ? 32.0 : 16.0,
//         vertical: 24.0,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Add New Item',
//             style: TextStyle(
//               fontSize: 26,
//               fontWeight: FontWeight.bold,
//               color: AppTheme.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 4),
//           const Text(
//             'Add a new product to your inventory',
//             style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
//           ),
//           const SizedBox(height: 24),

//           // ── Method Selector Cards ──
//           _buildMethodSelector(isDesktop),
//           const SizedBox(height: 28),

//           // Render Scanning / Analyzing State Overlay if active
//           if (_isAnalyzing)
//             _buildAnalyzingOverlay()
//           else if (_selectedMethod == ProductInputMethod.upload)
//             _buildUploadView(isDesktop)
//           else
//             // Main Form View
//             Form(
//               key: _formKey,
//               child: isDesktop ? _buildDesktopFormLayout() : _buildMobileFormLayout(),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMethodSelector(bool isDesktop) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Choose a method',
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: AppTheme.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Row(
//           children: [
//             Expanded(
//               child: _buildMethodCard(
//                 method: ProductInputMethod.manual,
//                 icon: Icons.edit_outlined,
//                 activeIcon: Icons.edit,
//                 title: 'Add Manually',
//                 subtitle: 'Enter product details manually',
//                 color: const Color(0xFF10B981),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: _buildMethodCard(
//                 method: ProductInputMethod.upload,
//                 icon: Icons.photo_camera_outlined,
//                 activeIcon: Icons.photo_camera,
//                 title: 'Upload Image',
//                 subtitle: 'Upload image of product to extract',
//                 color: const Color(0xFF8B5CF6),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildMethodCard({
//     required ProductInputMethod method,
//     required IconData icon,
//     required IconData activeIcon,
//     required String title,
//     required String subtitle,
//     required Color color,
//   }) {
//     final isSelected = _selectedMethod == method;
//     return GestureDetector(
//       onTap: () {
//         setState(() => _selectedMethod = method);
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
//         decoration: BoxDecoration(
//           color: isSelected ? color.withOpacity(0.06) : Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: isSelected ? color : AppTheme.cardBorder,
//             width: isSelected ? 2 : 1,
//           ),
//           boxShadow: isSelected
//               ? [
//                   BoxShadow(
//                     color: color.withOpacity(0.12),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   )
//                 ]
//               : [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.02),
//                     blurRadius: 6,
//                     offset: const Offset(0, 2),
//                   )
//                 ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: isSelected ? color.withOpacity(0.15) : color.withOpacity(0.08),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 isSelected ? activeIcon : icon,
//                 color: color,
//                 size: 24,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               subtitle,
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               style: TextStyle(
//                 fontSize: 11,
//                 color: isSelected ? AppTheme.textSecondary : AppTheme.textMuted,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── 3. Upload View Dropzone ──
//   Widget _buildUploadView(bool isDesktop) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppTheme.cardBorder),
//       ),
//       child: Column(
//         children: [
//           InkWell(
//             onTap: () => _pickAndExtractImage(),
//             borderRadius: BorderRadius.circular(16),
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(36),
//               decoration: BoxDecoration(
//                 color: AppTheme.backgroundMint.withOpacity(0.5),
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 1.5),
//               ),
//               child: Column(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(Icons.cloud_upload_outlined, color: AppTheme.primaryGreen, size: 36),
//                   ),
//                   const SizedBox(height: 16),
//                   const Text(
//                     'Click to upload product image or select sample',
//                     style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
//                   ),
//                   const SizedBox(height: 6),
//                   const Text(
//                     'Supports JPG, PNG • Gemini Developer API will extract details automatically',
//                     style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           if (_uploadedImages.isNotEmpty) ...[
//             Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 'Selected Image (${_uploadedImages.length}):',
//                 style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
//               ),
//             ),
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 ..._uploadedImages.map(
//                   (img) => Stack(
//                     children: [
//                       Container(
//                         margin: const EdgeInsets.only(right: 12),
//                         width: 90,
//                         height: 90,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(color: AppTheme.primaryGreen, width: 2),
//                           image: const DecorationImage(
//                             image: AssetImage('assets/images/milk.png'),
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         top: 4,
//                         right: 16,
//                         child: GestureDetector(
//                           onTap: () => setState(() => _uploadedImages.remove(img)),
//                           child: Container(
//                             padding: const EdgeInsets.all(2),
//                             decoration: const BoxDecoration(
//                               color: Colors.black54,
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(Icons.close, size: 14, color: Colors.white),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//           ],
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               OutlinedButton.icon(
//                 style: OutlinedButton.styleFrom(
//                   minimumSize: const Size(160, 48),
//                 ),
//                 onPressed: () => _pickAndExtractImage(),
//                 icon: const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primaryGreen),
//                 label: const Text('Choose Image'),
//               ),
//               const SizedBox(width: 16),
//               ElevatedButton.icon(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppTheme.primaryGreen,
//                   minimumSize: const Size(200, 48),
//                 ),
//                 onPressed: () => _triggerGeminiAIExtraction('Uploaded Image'),
//                 icon: const Icon(Icons.auto_awesome, color: Colors.white),
//                 label: const Text('Extract with Gemini AI'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   void _pickAndExtractImage() async {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (ctx) => Container(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Upload Product Image',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Choose an option to pick image from your device for Gemini AI extraction:',
//               style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
//             ),
//             const SizedBox(height: 20),
//             ListTile(
//               leading: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: AppTheme.primaryGreen.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryGreen),
//               ),
//               title: const Text('Choose from Gallery / Files'),
//               subtitle: const Text('Select product image from device storage'),
//               onTap: () async {
//                 Navigator.pop(ctx);
//                 final picker = ImagePicker();
//                 final XFile? file = await picker.pickImage(source: ImageSource.gallery);
//                 if (file != null) {
//                   _triggerGeminiAIExtraction(file.name.isNotEmpty ? file.name : 'Selected Gallery Image');
//                 } else {
//                   _triggerGeminiAIExtraction('Selected Device Image');
//                 }
//               },
//             ),
//             const Divider(),
//             ListTile(
//               leading: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: AppTheme.accentGreen.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.camera_alt_outlined, color: AppTheme.accentGreen),
//               ),
//               title: const Text('Take Photo with Camera'),
//               subtitle: const Text('Capture product packaging immediately'),
//               onTap: () async {
//                 Navigator.pop(ctx);
//                 final picker = ImagePicker();
//                 final XFile? file = await picker.pickImage(source: ImageSource.camera);
//                 if (file != null) {
//                   _triggerGeminiAIExtraction(file.name.isNotEmpty ? file.name : 'Camera Photo');
//                 } else {
//                   _triggerGeminiAIExtraction('Camera Photo');
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAnalyzingOverlay() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(40),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppTheme.accentGreen.withOpacity(0.5)),
//       ),
//       child: Column(
//         children: [
//           const CircularProgressIndicator(color: AppTheme.primaryGreen),
//           const SizedBox(height: 20),
//           Text(
//             _scanningStatusText ?? 'Extracting product information...',
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Gemini AI is parsing product name, brand, prices, and expiry label variations...',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDesktopFormLayout() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               flex: 3,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Item Details',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildTextField(
//                     label: 'Product Name *',
//                     controller: _nameController,
//                     hint: 'e.g. Amul Milk',
//                     validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required' : null,
//                   ),
//                   const SizedBox(height: 16),
//                   _buildCategoryDropdown(),
//                   const SizedBox(height: 16),
//                   _buildTextField(
//                     label: 'Brand (Optional)',
//                     controller: _brandController,
//                     hint: 'e.g. Amul',
//                   ),
//                   const SizedBox(height: 16),
//                   _buildTextField(
//                     label: 'Batch Number *',
//                     controller: _batchNumberController,
//                     hint: 'e.g. B-99402',
//                     validator: (v) => v == null || v.trim().isEmpty ? 'Batch number is required' : null,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 24),
//             Expanded(
//               flex: 3,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 38),
//                   _buildTextField(
//                     label: 'Quantity / Size *',
//                     controller: _quantityController,
//                     hint: 'e.g. 1 L, 500 g, 1 pack',
//                     validator: (v) => v == null || v.trim().isEmpty ? 'Quantity is required' : null,
//                   ),
//                   const SizedBox(height: 16),
//                   _buildTextField(
//                     label: 'Original Price (₹) *',
//                     controller: _priceController,
//                     keyboardType: TextInputType.number,
//                     hint: 'e.g. 60',
//                     onChanged: (_) => setState(() {}),
//                     validator: (v) {
//                       if (v == null || v.trim().isEmpty) return 'Price is required';
//                       if (double.tryParse(v) == null) return 'Enter a valid price number';
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16),
//                   _buildDatePickerTile(
//                     label: 'Expiry Date *',
//                     date: _expiryDate,
//                     onTap: () => _selectDate(context),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildSuggestedSellingPriceCard(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 24),
//         _buildImagesSection(),
//         const SizedBox(height: 32),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: [
//             OutlinedButton(
//               style: OutlinedButton.styleFrom(
//                 minimumSize: const Size(120, 48),
//               ),
//               onPressed: () {
//                 if (Navigator.of(context).canPop()) Navigator.of(context).pop();
//               },
//               child: const Text('Cancel'),
//             ),
//             const SizedBox(width: 16),
//             ElevatedButton.icon(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppTheme.primaryGreen,
//                 minimumSize: const Size(160, 48),
//               ),
//               onPressed: _submitForm,
//               icon: const Icon(Icons.archive_outlined, color: Colors.white),
//               label: const Text('Save Item'),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildMobileFormLayout() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Item Details',
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
//         ),
//         const SizedBox(height: 16),
//         _buildTextField(
//           label: 'Product Name *',
//           controller: _nameController,
//           hint: 'e.g. Amul Milk',
//           validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required' : null,
//         ),
//         const SizedBox(height: 16),
//         _buildCategoryDropdown(),
//         const SizedBox(height: 16),
//         _buildTextField(
//           label: 'Brand (Optional)',
//           controller: _brandController,
//           hint: 'e.g. Amul',
//         ),
//         const SizedBox(height: 16),
//         _buildTextField(
//           label: 'Batch Number *',
//           controller: _batchNumberController,
//           hint: 'e.g. B-99402',
//           validator: (v) => v == null || v.trim().isEmpty ? 'Batch number is required' : null,
//         ),
//         const SizedBox(height: 16),
//         _buildTextField(
//           label: 'Quantity / Size *',
//           controller: _quantityController,
//           hint: 'e.g. 1 L, 500 g, 1 pack',
//           validator: (v) => v == null || v.trim().isEmpty ? 'Quantity is required' : null,
//         ),
//         const SizedBox(height: 16),
//         _buildTextField(
//           label: 'Original Price (₹) *',
//           controller: _priceController,
//           keyboardType: TextInputType.number,
//           hint: 'e.g. 60',
//           onChanged: (_) => setState(() {}),
//           validator: (v) {
//             if (v == null || v.trim().isEmpty) return 'Price is required';
//             if (double.tryParse(v) == null) return 'Enter a valid price number';
//             return null;
//           },
//         ),
//         const SizedBox(height: 16),
//         _buildDatePickerTile(
//           label: 'Expiry Date *',
//           date: _expiryDate,
//           onTap: () => _selectDate(context),
//         ),
//         const SizedBox(height: 16),
//         _buildSuggestedSellingPriceCard(),
//         const SizedBox(height: 20),
//         _buildImagesSection(),
//         const SizedBox(height: 28),
//         ElevatedButton.icon(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppTheme.primaryGreen,
//             minimumSize: const Size(double.infinity, 50),
//           ),
//           onPressed: _submitForm,
//           icon: const Icon(Icons.archive_outlined, color: Colors.white),
//           label: const Text('Save Item'),
//         ),
//       ],
//     );
//   }

//   Widget _buildTextField({
//     required String label,
//     required TextEditingController controller,
//     required String hint,
//     TextInputType keyboardType = TextInputType.text,
//     int maxLines = 1,
//     ValueChanged<String>? onChanged,
//     FormFieldValidator<String>? validator,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
//         ),
//         const SizedBox(height: 6),
//         TextFormField(
//           controller: controller,
//           keyboardType: keyboardType,
//           maxLines: maxLines,
//           onChanged: onChanged,
//           validator: validator,
//           style: const TextStyle(fontSize: 14),
//           decoration: InputDecoration(
//             hintText: hint,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCategoryDropdown() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Category *',
//           style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
//         ),
//         const SizedBox(height: 6),
//         DropdownButtonFormField<String>(
//           value: _selectedCategory,
//           items: _categories
//               .map((cat) => DropdownMenuItem(
//                     value: cat,
//                     child: Text(cat, style: const TextStyle(fontSize: 14)),
//                   ))
//               .toList(),
//           onChanged: (val) {
//             if (val != null) setState(() => _selectedCategory = val);
//           },
//           decoration: const InputDecoration(
//             contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDatePickerTile({
//     required String label,
//     required DateTime? date,
//     required VoidCallback onTap,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
//         ),
//         const SizedBox(height: 6),
//         InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(12),
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: AppTheme.cardBorder),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   date == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(date),
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: date == null ? AppTheme.textMuted : AppTheme.textPrimary,
//                   ),
//                 ),
//                 const Icon(Icons.calendar_month_outlined, size: 20, color: AppTheme.textSecondary),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSuggestedSellingPriceCard() {
//     final suggested = _suggestedSellingPrice;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF0FDF4),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFBBF7D0)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: const BoxDecoration(
//               color: Color(0xFFDCFCE7),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.currency_rupee, color: AppTheme.primaryGreen, size: 20),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Suggested Selling Price',
//                   style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   'Calculated automatically based on days until expiry',
//                   style: TextStyle(fontSize: 11, color: Colors.green.shade700),
//                 ),
//               ],
//             ),
//           ),
//           Text(
//             suggested != null ? '₹ ${suggested.toStringAsFixed(1)}' : '₹ --',
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildImagesSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Images (Optional)',
//           style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
//         ),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             InkWell(
//               onTap: () => _triggerGeminiAIExtraction('Uploaded Image'),
//               borderRadius: BorderRadius.circular(12),
//               child: Container(
//                 width: 90,
//                 height: 90,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: AppTheme.cardBorder, style: BorderStyle.solid),
//                 ),
//                 child: const Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryGreen, size: 24),
//                     SizedBox(height: 4),
//                     Text('Add more', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             ..._uploadedImages.map(
//               (img) => Stack(
//                 children: [
//                   Container(
//                     margin: const EdgeInsets.only(right: 12),
//                     width: 90,
//                     height: 90,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12),
//                       image: const DecorationImage(
//                         image: AssetImage('assets/images/milk.png'),
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     top: 4,
//                     right: 16,
//                     child: GestureDetector(
//                       onTap: () => setState(() => _uploadedImages.remove(img)),
//                       child: Container(
//                         padding: const EdgeInsets.all(2),
//                         decoration: const BoxDecoration(
//                           color: Colors.black54,
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(Icons.close, size: 14, color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// version 2

// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';

// import '../../theme/app_theme.dart';
// import '../../services/gemini_extraction_service.dart';

// enum ProductInputMethod { manual, upload }

// class AddProductScreen extends StatefulWidget {
//   final VoidCallback? onItemAdded; // 1. Declare parameter

//   const AddProductScreen({
//     Key? key,
//     this.onItemAdded, // 2. Add to constructor
//   }) : super(key: key);

//   @override
//   State<AddProductScreen> createState() => _AddProductScreenState();
// }

// class _AddProductScreenState extends State<AddProductScreen> {
//   final _formKey = GlobalKey<FormState>();

//   ProductInputMethod _selectedMethod = ProductInputMethod.manual;
//   bool _isAnalyzing = false;
//   String? _scanningStatusText;

//   // Form Controllers
//   final _nameController = TextEditingController();
//   final _brandController = TextEditingController();
//   final _batchNumberController = TextEditingController();
//   final _quantityController = TextEditingController();
//   final _priceController = TextEditingController();

//   String _selectedCategory = 'Dairy & Eggs';
//   DateTime? _expiryDate;

//   // Selected image raw bytes for preview & Gemini processing
//   Uint8List? _selectedImageBytes;
//   String _imageMimeType = 'image/jpeg';
//   final List<String> _uploadedImages = [];

//   final List<String> _categories = [
//     'Dairy & Eggs',
//     'Bakery & Bread',
//     'Fruits & Vegetables',
//     'Meat & Seafood',
//     'Beverages',
//     'Pantry & Staples',
//     'Snacks & Confectionery',
//     'Frozen Foods',
//     'Personal Care',
//     'Household Items',
//     'Other',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _batchNumberController.text =
//         'B-${(10000 + (DateTime.now().millisecondsSinceEpoch % 89999)).toString()}';
//     _expiryDate = DateTime.now().add(const Duration(days: 7));
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _brandController.dispose();
//     _batchNumberController.dispose();
//     _quantityController.dispose();
//     _priceController.dispose();
//     super.dispose();
//   }

//   // ── Calculation Helpers ──
//   int? get _daysUntilExpiry {
//     if (_expiryDate == null) return null;
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final exp = DateTime(_expiryDate!.year, _expiryDate!.month, _expiryDate!.day);
//     return exp.difference(today).inDays;
//   }

//   double? get _calculatedSellingPrice {
//     final originalPrice = double.tryParse(_priceController.text);
//     if (originalPrice == null || _daysUntilExpiry == null) return null;

//     final days = _daysUntilExpiry!;
//     if (days <= 0) return originalPrice * 0.20;
//     if (days == 1) return originalPrice * 0.30;
//     if (days == 2) return originalPrice * 0.40;
//     if (days == 3) return originalPrice * 0.50;
//     if (days <= 5) return originalPrice * 0.70;
//     if (days <= 7) return originalPrice * 0.85;
//     return originalPrice;
//   }

//   // ── Date Picker Helper ──
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 7)),
//       firstDate: DateTime.now().subtract(const Duration(days: 30)),
//       lastDate: DateTime.now().add(const Duration(days: 1095)),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: AppTheme.primaryGreen,
//               onPrimary: Colors.white,
//               onSurface: AppTheme.textPrimary,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null) {
//       setState(() => _expiryDate = picked);
//     }
//   }

//   // ── Firebase AI Extraction Flow ──
//   Future<void> _triggerGeminiAIExtraction(
//       Uint8List imageBytes, String mimeType) async {
//     setState(() {
//       _isAnalyzing = true;
//       _scanningStatusText = 'Analyzing image with Firebase AI...';
//     });

//     try {
//       final extracted = await GeminiExtractionService.extractProductFromImage(
//         imageBytes,
//         mimeType: mimeType,
//       );

//       if (extracted != null && mounted) {
//         setState(() {
//           if (extracted.productName != null && extracted.productName!.isNotEmpty) {
//             _nameController.text = extracted.productName!;
//           }
//           if (extracted.brand != null && extracted.brand!.isNotEmpty) {
//             _brandController.text = extracted.brand!;
//           }
//           if (extracted.category != null && _categories.contains(extracted.category)) {
//             _selectedCategory = extracted.category!;
//           }
//           if (extracted.quantitySize != null && extracted.quantitySize!.isNotEmpty) {
//             _quantityController.text = extracted.quantitySize!;
//           }
//           if (extracted.originalPrice != null && extracted.originalPrice! > 0) {
//             _priceController.text = extracted.originalPrice!.toStringAsFixed(0);
//           }
//           if (extracted.batchNumber != null && extracted.batchNumber!.isNotEmpty) {
//             _batchNumberController.text = extracted.batchNumber!;
//           }
//           if (extracted.expiryDate.isNotEmpty) {
//             _expiryDate = DateTime.tryParse(extracted.expiryDate);
//       }

//           _selectedMethod = ProductInputMethod.manual;
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Product details extracted successfully!'),
//             backgroundColor: AppTheme.primaryGreen,
//           ),
//         );
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Could not extract details. Please enter manually.'),
//               backgroundColor: Colors.orange,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error extracting product info: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isAnalyzing = false);
//       }
//     }
//   }

//   // ── Image Selection Bottom Sheet ──
//   void _pickAndExtractImage() async {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (ctx) => Container(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Upload Product Image',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: AppTheme.textPrimary,
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Choose an option to pick image for Firebase AI extraction:',
//               style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
//             ),
//             const SizedBox(height: 20),
//             ListTile(
//               leading: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: AppTheme.primaryGreen.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryGreen),
//               ),
//               title: const Text('Choose from Gallery / Files'),
//               subtitle: const Text('Select product image from device storage'),
//               onTap: () async {
//                 Navigator.pop(ctx);
//                 final picker = ImagePicker();
//                 final XFile? file = await picker.pickImage(source: ImageSource.gallery);
//                 if (file != null) {
//                   final bytes = await file.readAsBytes();
//                   final ext = file.path.split('.').last.toLowerCase();
//                   final mime = (ext == 'png') ? 'image/png' : 'image/jpeg';

//                   setState(() {
//                     _selectedImageBytes = bytes;
//                     _imageMimeType = mime;
//                     _uploadedImages.clear();
//                     _uploadedImages.add(file.name);
//                   });
//                   await _triggerGeminiAIExtraction(bytes, mime);
//                 }
//               },
//             ),
//             const Divider(),
//             ListTile(
//               leading: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: AppTheme.accentGreen.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.camera_alt_outlined, color: AppTheme.accentGreen),
//               ),
//               title: const Text('Take Photo with Camera'),
//               subtitle: const Text('Capture product packaging immediately'),
//               onTap: () async {
//                 Navigator.pop(ctx);
//                 final picker = ImagePicker();
//                 final XFile? file = await picker.pickImage(source: ImageSource.camera);
//                 if (file != null) {
//                   final bytes = await file.readAsBytes();
//                   final ext = file.path.split('.').last.toLowerCase();
//                   final mime = (ext == 'png') ? 'image/png' : 'image/jpeg';

//                   setState(() {
//                     _selectedImageBytes = bytes;
//                     _imageMimeType = mime;
//                     _uploadedImages.clear();
//                     _uploadedImages.add(file.name);
//                   });
//                   await _triggerGeminiAIExtraction(bytes, mime);
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _submitForm() {
//     if (_formKey.currentState?.validate() ?? false) {
//       if (_expiryDate == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Please select an expiry date'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Item "${_nameController.text}" saved successfully!'),
//           backgroundColor: AppTheme.primaryGreen,
//         ),
//       );

//       if (Navigator.of(context).canPop()) {
//         Navigator.of(context).pop();
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final isDesktop = size.width > 900;

//     return SingleChildScrollView(
//       padding: EdgeInsets.symmetric(
//         horizontal: isDesktop ? 32.0 : 16.0,
//         vertical: 24.0,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Add New Item',
//             style: TextStyle(
//               fontSize: 26,
//               fontWeight: FontWeight.bold,
//               color: AppTheme.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 4),
//           const Text(
//             'Add a new product to your inventory',
//             style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
//           ),
//           const SizedBox(height: 24),
//           _buildMethodSelector(isDesktop),
//           const SizedBox(height: 28),
//           if (_isAnalyzing)
//             _buildAnalyzingOverlay()
//           else if (_selectedMethod == ProductInputMethod.upload)
//             _buildUploadView(isDesktop)
//           else
//             Form(
//               key: _formKey,
//               child: isDesktop ? _buildDesktopFormLayout() : _buildMobileFormLayout(),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMethodSelector(bool isDesktop) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Choose a method',
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: AppTheme.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Row(
//           children: [
//             Expanded(
//               child: _buildMethodCard(
//                 method: ProductInputMethod.manual,
//                 icon: Icons.edit_outlined,
//                 activeIcon: Icons.edit,
//                 title: 'Add Manually',
//                 subtitle: 'Enter product details manually',
//                 color: const Color(0xFF10B981),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: _buildMethodCard(
//                 method: ProductInputMethod.upload,
//                 icon: Icons.photo_camera_outlined,
//                 activeIcon: Icons.photo_camera,
//                 title: 'Upload Image',
//                 subtitle: 'Upload image of product to extract',
//                 color: const Color(0xFF8B5CF6),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildMethodCard({
//     required ProductInputMethod method,
//     required IconData icon,
//     required IconData activeIcon,
//     required String title,
//     required String subtitle,
//     required Color color,
//   }) {
//     final isSelected = _selectedMethod == method;
//     return GestureDetector(
//       onTap: () {
//         setState(() => _selectedMethod = method);
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
//         decoration: BoxDecoration(
//           color: isSelected ? color.withOpacity(0.06) : Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: isSelected ? color : AppTheme.cardBorder,
//             width: isSelected ? 2 : 1,
//           ),
//           boxShadow: isSelected
//               ? [
//                   BoxShadow(
//                     color: color.withOpacity(0.12),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   )
//                 ]
//               : [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.02),
//                     blurRadius: 6,
//                     offset: const Offset(0, 2),
//                   )
//                 ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: isSelected ? color.withOpacity(0.15) : color.withOpacity(0.08),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 isSelected ? activeIcon : icon,
//                 color: color,
//                 size: 24,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               subtitle,
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               style: TextStyle(
//                 fontSize: 11,
//                 color: isSelected ? AppTheme.textSecondary : AppTheme.textMuted,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildUploadView(bool isDesktop) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppTheme.cardBorder),
//       ),
//       child: Column(
//         children: [
//           InkWell(
//             onTap: _pickAndExtractImage,
//             borderRadius: BorderRadius.circular(16),
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(36),
//               decoration: BoxDecoration(
//                 color: AppTheme.backgroundMint.withOpacity(0.5),
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 1.5),
//               ),
//               child: Column(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(Icons.cloud_upload_outlined,
//                         color: AppTheme.primaryGreen, size: 36),
//                   ),
//                   const SizedBox(height: 16),
//                   const Text(
//                     'Click to upload product image',
//                     style: TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w600,
//                         color: AppTheme.textPrimary),
//                   ),
//                   const SizedBox(height: 6),
//                   const Text(
//                     'Supports JPG, PNG • Firebase AI extracts details automatically',
//                     style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           if (_selectedImageBytes != null) ...[
//             Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 'Selected Image (${_uploadedImages.length}):',
//                 style: const TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.bold,
//                     color: AppTheme.textPrimary),
//               ),
//             ),
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 Stack(
//                   children: [
//                     Container(
//                       margin: const EdgeInsets.only(right: 12),
//                       width: 90,
//                       height: 90,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: AppTheme.primaryGreen, width: 2),
//                       ),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(10),
//                         child: Image.memory(
//                           _selectedImageBytes!,
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),
//                     Positioned(
//                       top: 4,
//                       right: 16,
//                       child: GestureDetector(
//                         onTap: () => setState(() {
//                           _selectedImageBytes = null;
//                           _uploadedImages.clear();
//                         }),
//                         child: Container(
//                           padding: const EdgeInsets.all(2),
//                           decoration: const BoxDecoration(
//                             color: Colors.black54,
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(Icons.close, size: 14, color: Colors.white),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//           ],
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               OutlinedButton.icon(
//                 style: OutlinedButton.styleFrom(
//                   minimumSize: const Size(160, 48),
//                 ),
//                 onPressed: _pickAndExtractImage,
//                 icon: const Icon(Icons.add_photo_alternate_outlined,
//                     color: AppTheme.primaryGreen),
//                 label: const Text('Choose Image'),
//               ),
//               const SizedBox(width: 16),
//               ElevatedButton.icon(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppTheme.primaryGreen,
//                   minimumSize: const Size(200, 48),
//                 ),
//                 onPressed: _selectedImageBytes == null
//                     ? null
//                     : () => _triggerGeminiAIExtraction(
//                           _selectedImageBytes!,
//                           _imageMimeType,
//                         ),
//                 icon: const Icon(Icons.auto_awesome, color: Colors.white),
//                 label: const Text('Extract with Firebase AI'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAnalyzingOverlay() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(40),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppTheme.accentGreen.withOpacity(0.5)),
//       ),
//       child: Column(
//         children: [
//           const CircularProgressIndicator(color: AppTheme.primaryGreen),
//           const SizedBox(height: 20),
//           Text(
//             _scanningStatusText ?? 'Extracting product information...',
//             style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: AppTheme.primaryGreen),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Firebase AI is parsing product name, brand, price, and expiry date...',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDesktopFormLayout() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               flex: 3,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Item Details',
//                     style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: AppTheme.textPrimary),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildTextField(
//                     label: 'Product Name *',
//                     controller: _nameController,
//                     hint: 'e.g. Amul Milk',
//                     validator: (v) => v == null || v.trim().isEmpty
//                         ? 'Product name is required'
//                         : null,
//                   ),
//                   const SizedBox(height: 16),
//                   _buildCategoryDropdown(),
//                   const SizedBox(height: 16),
//                   _buildTextField(
//                     label: 'Brand (Optional)',
//                     controller: _brandController,
//                     hint: 'e.g. Amul',
//                   ),
//                   const SizedBox(height: 16),
//                   _buildTextField(
//                     label: 'Batch Number *',
//                     controller: _batchNumberController,
//                     hint: 'e.g. B-99402',
//                     validator: (v) => v == null || v.trim().isEmpty
//                         ? 'Batch number is required'
//                         : null,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 24),
//             Expanded(
//               flex: 3,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 38),
//                   _buildTextField(
//                     label: 'Quantity / Size *',
//                     controller: _quantityController,
//                     hint: 'e.g. 1 L, 500 g, 1 pack',
//                     validator: (v) => v == null || v.trim().isEmpty
//                         ? 'Quantity is required'
//                         : null,
//                   ),
//                   const SizedBox(height: 16),
//                   _buildTextField(
//                     label: 'Original Price (₹) *',
//                     controller: _priceController,
//                     keyboardType: TextInputType.number,
//                     hint: 'e.g. 60',
//                     onChanged: (_) => setState(() {}),
//                     validator: (v) {
//                       if (v == null || v.trim().isEmpty) return 'Price is required';
//                       if (double.tryParse(v) == null) return 'Enter a valid price number';
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16),
//                   _buildDatePickerTile(
//                     label: 'Expiry Date *',
//                     date: _expiryDate,
//                     onTap: () => _selectDate(context),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildSuggestedSellingPriceCard(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 24),
//         _buildImagesSection(),
//         const SizedBox(height: 32),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: [
//             OutlinedButton(
//               style: OutlinedButton.styleFrom(
//                 minimumSize: const Size(120, 48),
//               ),
//               onPressed: () {
//                 if (Navigator.of(context).canPop()) Navigator.of(context).pop();
//               },
//               child: const Text('Cancel'),
//             ),
//             const SizedBox(width: 16),
//             ElevatedButton.icon(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppTheme.primaryGreen,
//                 minimumSize: const Size(160, 48),
//               ),
//               onPressed: _submitForm,
//               icon: const Icon(Icons.archive_outlined, color: Colors.white),
//               label: const Text('Save Item'),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildMobileFormLayout() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Item Details',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: AppTheme.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 16),
//         _buildTextField(
//           label: 'Product Name *',
//           controller: _nameController,
//           hint: 'e.g. Amul Milk',
//           validator: (v) =>
//               v == null || v.trim().isEmpty ? 'Product name is required' : null,
//         ),
//         const SizedBox(height: 16),
//         _buildCategoryDropdown(),
//         const SizedBox(height: 16),
//         _buildTextField(
//           label: 'Brand (Optional)',
//           controller: _brandController,
//           hint: 'e.g. Amul',
//         ),
//         const SizedBox(height: 16),
//         _buildTextField(
//           label: 'Batch Number *',
//           controller: _batchNumberController,
//           hint: 'e.g. B-99402',
//           validator: (v) =>
//               v == null || v.trim().isEmpty ? 'Batch number is required' : null,
//         ),
//         const SizedBox(height: 16),
//         _buildTextField(
//           label: 'Quantity / Size *',
//           controller: _quantityController,
//           hint: 'e.g. 1 L, 500 g, 1 pack',
//           validator: (v) =>
//               v == null || v.trim().isEmpty ? 'Quantity is required' : null,
//         ),
//         const SizedBox(height: 16),
//         _buildTextField(
//           label: 'Original Price (₹) *',
//           controller: _priceController,
//           keyboardType: TextInputType.number,
//           hint: 'e.g. 60',
//           onChanged: (_) => setState(() {}),
//           validator: (v) {
//             if (v == null || v.trim().isEmpty) return 'Price is required';
//             if (double.tryParse(v) == null) return 'Enter a valid price number';
//             return null;
//           },
//         ),
//         const SizedBox(height: 16),
//         _buildDatePickerTile(
//           label: 'Expiry Date *',
//           date: _expiryDate,
//           onTap: () => _selectDate(context),
//         ),
//         const SizedBox(height: 16),
//         _buildSuggestedSellingPriceCard(),
//         const SizedBox(height: 20),
//         _buildImagesSection(),
//         const SizedBox(height: 28),
//         ElevatedButton.icon(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppTheme.primaryGreen,
//             minimumSize: const Size(double.infinity, 50),
//           ),
//           onPressed: _submitForm,
//           icon: const Icon(Icons.archive_outlined, color: Colors.white),
//           label: const Text('Save Item'),
//         ),
//       ],
//     );
//   }

//   Widget _buildTextField({
//     required String label,
//     required TextEditingController controller,
//     required String hint,
//     TextInputType keyboardType = TextInputType.text,
//     int maxLines = 1,
//     ValueChanged<String>? onChanged,
//     FormFieldValidator<String>? validator,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 13,
//             fontWeight: FontWeight.w600,
//             color: AppTheme.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 6),
//         TextFormField(
//           controller: controller,
//           keyboardType: keyboardType,
//           maxLines: maxLines,
//           onChanged: onChanged,
//           validator: validator,
//           style: const TextStyle(fontSize: 14),
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
//             contentPadding:
//                 const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//             filled: true,
//             fillColor: Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: const BorderSide(color: AppTheme.cardBorder),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: const BorderSide(color: AppTheme.cardBorder),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide:
//                   const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCategoryDropdown() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Category *',
//           style: TextStyle(
//             fontSize: 13,
//             fontWeight: FontWeight.w600,
//             color: AppTheme.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 6),
//         DropdownButtonFormField<String>(
//           value: _selectedCategory,
//           items: _categories
//               .map((cat) => DropdownMenuItem(
//                     value: cat,
//                     child: Text(cat, style: const TextStyle(fontSize: 14)),
//                   ))
//               .toList(),
//           onChanged: (val) {
//             if (val != null) setState(() => _selectedCategory = val);
//           },
//           decoration: InputDecoration(
//             contentPadding:
//                 const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//             filled: true,
//             fillColor: Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: const BorderSide(color: AppTheme.cardBorder),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: const BorderSide(color: AppTheme.cardBorder),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide:
//                   const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDatePickerTile({
//     required String label,
//     required DateTime? date,
//     required VoidCallback onTap,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 13,
//             fontWeight: FontWeight.w600,
//             color: AppTheme.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 6),
//         InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(12),
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: AppTheme.cardBorder),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   date == null
//                       ? 'Select Date'
//                       : DateFormat('dd MMM yyyy').format(date),
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: date == null
//                         ? AppTheme.textMuted
//                         : AppTheme.textPrimary,
//                   ),
//                 ),
//                 const Icon(Icons.calendar_month_outlined,
//                     size: 20, color: AppTheme.textSecondary),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSuggestedSellingPriceCard() {
//     final sellingPrice = _calculatedSellingPrice;
//     final originalPrice = double.tryParse(_priceController.text) ?? 0;
//     final days = _daysUntilExpiry;

//     if (sellingPrice == null || originalPrice <= 0 || days == null) {
//       return const SizedBox.shrink();
//     }

//     final discountPercent =
//         (((originalPrice - sellingPrice) / originalPrice) * 100).round();

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF0FDF4),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFBBF7D0)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: const BoxDecoration(
//               color: Color(0xFFDCFCE7),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.currency_rupee,
//                 color: AppTheme.primaryGreen, size: 20),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Suggested Selling Price',
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.bold,
//                     color: AppTheme.primaryGreen,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   days <= 0
//                       ? 'Expired item'
//                       : '$days days left • ${discountPercent > 0 ? "$discountPercent% discount" : "Full price"}',
//                   style: TextStyle(fontSize: 11, color: Colors.green.shade700),
//                 ),
//               ],
//             ),
//           ),
//           Text(
//             '₹ ${sellingPrice.toStringAsFixed(0)}',
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: AppTheme.primaryGreen,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildImagesSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Images / Firebase AI Extraction',
//           style: TextStyle(
//             fontSize: 13,
//             fontWeight: FontWeight.w600,
//             color: AppTheme.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             InkWell(
//               onTap: _pickAndExtractImage,
//               borderRadius: BorderRadius.circular(12),
//               child: Container(
//                 width: 90,
//                 height: 90,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: AppTheme.primaryGreen.withOpacity(0.5),
//                     style: BorderStyle.solid,
//                   ),
//                 ),
//                 child: const Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.add_a_photo_outlined,
//                         color: AppTheme.primaryGreen, size: 24),
//                     SizedBox(height: 4),
//                     Text(
//                       'Attach & Extract',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 10,
//                         color: AppTheme.primaryGreen,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             if (_selectedImageBytes != null)
//               Stack(
//                 children: [
//                   Container(
//                     margin: const EdgeInsets.only(right: 12),
//                     width: 90,
//                     height: 90,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: AppTheme.primaryGreen, width: 2),
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(10),
//                       child: Image.memory(
//                         _selectedImageBytes!,
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     top: 4,
//                     right: 16,
//                     child: GestureDetector(
//                       onTap: () => setState(() {
//                         _selectedImageBytes = null;
//                         _uploadedImages.clear();
//                       }),
//                       child: Container(
//                         padding: const EdgeInsets.all(2),
//                         decoration: const BoxDecoration(
//                           color: Colors.black54,
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(Icons.close, size: 14, color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// version 3- crud with firstor +ui

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:image_picker/image_picker.dart';
// import '../models/product_model.dart';
// import '../providers/product_provider.dart';
// import '../services/gemini_extraction_service.dart';
// import '../theme/app_theme.dart';
// import 'dart:typed_data';

// enum ProductInputMethod { manual, upload }

// class AddProductScreen extends StatefulWidget {
//   final VoidCallback? onItemAdded;

//   const AddProductScreen({super.key, this.onItemAdded});

//   @override
//   State<AddProductScreen> createState() => _AddProductScreenState();
// }

// class _AddProductScreenState extends State<AddProductScreen> {
//   final _formKey = GlobalKey<FormState>();

//   ProductInputMethod _selectedMethod = ProductInputMethod.manual;
//   bool _isExtracting = false;
//   // Form Field Controllers
//   final _nameController = TextEditingController();
//   final _brandController = TextEditingController();
//   final _quantityController = TextEditingController();
//   final _priceController = TextEditingController();
//   final _batchNumberController = TextEditingController();

//   String _selectedCategory = 'Dairy';
//   DateTime? _expiryDate;
//   final List<String> _uploadedImages = [];

//   bool _isAnalyzing = false;
//   String? _scanningStatusText;

//   final List<String> _categories = [
//     'Dairy',
//     'Bakery',
//     'Beverages',
//     'Snacks',
//     'Produce',
//     'Pulses',
//     'Spices',
//     'Pantry',
//     'Personal Care',
//     'Household',
//     'Others'
//   ];

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _brandController.dispose();
//     _quantityController.dispose();
//     _priceController.dispose();
//     _batchNumberController.dispose();
//     super.dispose();
//   }

//   // Calculate dynamic suggested selling price card details
//   double? get _suggestedSellingPrice {
//     final priceStr = _priceController.text.trim();
//     if (priceStr.isEmpty || _expiryDate == null) return null;
//     final price = double.tryParse(priceStr);
//     if (price == null) return null;

//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final expiry = DateTime(_expiryDate!.year, _expiryDate!.month, _expiryDate!.day);
//     final daysRemaining = expiry.difference(today).inDays;

//     if (daysRemaining < 0) return 0.0;
//     if (daysRemaining <= 3) return price * 0.75;
//     if (daysRemaining <= 5) return price * 0.90;
//     if (daysRemaining <= 7) return price * 0.95;
//     return price;
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final initialDate = _expiryDate ?? DateTime.now().add(const Duration(days: 14));

//     final picked = await showDatePicker(
//       context: context,
//       initialDate: initialDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2035),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: AppTheme.primaryGreen,
//               onPrimary: Colors.white,
//               onSurface: AppTheme.textPrimary,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null) {
//       setState(() {
//         _expiryDate = picked;
//       });
//     }
//   }

//   // Run Gemini Extraction logic
//   Future<void> _triggerGeminiAIExtraction(
//   Uint8List imageBytes,
//   String mimeType,
// ) async {
//   setState(() {
//     _isExtracting = true;
//   });

//   try {
//     final extracted =
//         await GeminiExtractionService.extractProductFromImage(
//       imageBytes,
//       mimeType: mimeType,
//     );

//     if (!mounted) return;

//     if (extracted == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Could not extract product information from the image.',
//           ),
//         ),
//       );
//       return;
//     }

//     // Product name
//     if (extracted.productName.isNotEmpty) {
//       _nameController.text = extracted.productName;
//     }

//     // Brand
//     if (extracted.brand.isNotEmpty) {
//       _brandController.text = extracted.brand;
//     }

//     // Category
//     if (extracted.category.isNotEmpty &&
//         _categories.contains(extracted.category)) {
//       setState(() {
//         _selectedCategory = extracted.category;
//       });
//     }

//     // Quantity / size
//     if (extracted.quantitySize.isNotEmpty) {
//       _quantityController.text =
//           extracted.quantitySize;
//     }

//     // Original price
//     if (extracted.originalPrice > 0) {
//       _priceController.text =
//           extracted.originalPrice.toStringAsFixed(2);
//     }

//     // Expiry date
//     if (extracted.expiryDate.isNotEmpty) {
//       final parsedDate =
//           DateTime.tryParse(extracted.expiryDate);

//       if (parsedDate != null) {
//         setState(() {
//           _expiryDate = parsedDate;
//         });
//       }
//     }

//     // Batch number
//     if (extracted.batchNumber.isNotEmpty) {
//       _batchNumberController.text =
//           extracted.batchNumber;
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text(
//           'Product information extracted successfully. Please review the fields.',
//         ),
//       ),
//     );
//   } catch (e) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           'Failed to extract product information: $e',
//         ),
//       ),
//     );
//   } finally {
//     if (mounted) {
//       setState(() {
//         _isExtracting = false;
//       });
//     }
//   }
// }

//   void _showMissingFieldsPrompt(List<String> missingFields) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Row(
//           children: [
//             Icon(Icons.info_outline_rounded, color: AppTheme.warningOrange),
//             SizedBox(width: 8),
//             Text('Complete Missing Details'),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Gemini extracted most product details, but couldn\'t confidently identify the following required fields:',
//               style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
//             ),
//             const SizedBox(height: 12),
//             ...missingFields.map((field) => Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 4.0),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.warningOrange),
//                       const SizedBox(width: 8),
//                       Text(field, style: const TextStyle(fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                 )),
//             const SizedBox(height: 12),
//             const Text(
//               'Please complete these fields in the form below before saving.',
//               style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
//             ),
//           ],
//         ),
//         actions: [
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
//             onPressed: () => Navigator.of(ctx).pop(),
//             child: const Text('OK, Fill Manually'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please fill all required fields before saving.'),
//           backgroundColor: AppTheme.expiredRed,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       return;
//     }

//     if (_expiryDate == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select an Expiry Date for the product.'),
//           backgroundColor: AppTheme.expiredRed,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       return;
//     }

//     // Parse quantity
//     int qty = 1;
//     final qtyMatches = RegExp(r'\d+').firstMatch(_quantityController.text);
//     if (qtyMatches != null) {
//       qty = int.tryParse(qtyMatches.group(0)!) ?? 1;
//     }

//     final newProduct = ProductModel(
//       id: '',
//       name: _nameController.text.trim(),
//       category: _selectedCategory,
//       expiryDate: _expiryDate!,
//       originalPrice: double.parse(_priceController.text.trim()),
//       quantity: qty,
//       brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
//       batchNumber: _batchNumberController.text.trim(),
//       //images: List.from(_uploadedImages),
//     );

//     final productProvider = Provider.of<ProductProvider>(context, listen: false);
//     final success = await productProvider.addProduct(newProduct);

//     if (mounted) {
//       if (success) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Successfully added "${newProduct.name}" to inventory!'),
//             backgroundColor: AppTheme.primaryGreen,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//         if (widget.onItemAdded != null) {
//           widget.onItemAdded!();
//         } else if (Navigator.of(context).canPop()) {
//           Navigator.of(context).pop();
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final isDesktop = size.width > 900;

//     return SingleChildScrollView(
//       padding: EdgeInsets.symmetric(
//         horizontal: isDesktop ? 32.0 : 16.0,
//         vertical: 24.0,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Add New Item',
//             style: TextStyle(
//               fontSize: 26,
//               fontWeight: FontWeight.bold,
//               color: AppTheme.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 4),
//           const Text(
//             'Add a new product to your inventory',
//             style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
//           ),
//           const SizedBox(height: 24),

//           // ── Method Selector Cards ──
//           _buildMethodSelector(isDesktop),
//           const SizedBox(height: 28),

//           // Render Scanning / Analyzing State Overlay if active
//           if (_isAnalyzing)
//             _buildAnalyzingOverlay()
//           else if (_selectedMethod == ProductInputMethod.upload)
//             _buildUploadView(isDesktop)
//           else
//             // Main Form View
//             Form(
//               key: _formKey,
//               child: isDesktop ? _buildDesktopFormLayout() : _buildMobileFormLayout(),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMethodSelector(bool isDesktop) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Choose a method',
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: AppTheme.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Row(
//           children: [
//             Expanded(
//               child: _buildMethodCard(
//                 method: ProductInputMethod.manual,
//                 icon: Icons.edit_outlined,
//                 activeIcon: Icons.edit,
//                 title: 'Add Manually',
//                 subtitle: 'Enter product details manually',
//                 color: const Color(0xFF10B981),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: _buildMethodCard(
//                 method: ProductInputMethod.upload,
//                 icon: Icons.photo_camera_outlined,
//                 activeIcon: Icons.photo_camera,
//                 title: 'Upload Image',
//                 subtitle: 'Upload image of product to extract',
//                 color: const Color(0xFF8B5CF6),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildMethodCard({
//     required ProductInputMethod method,
//     required IconData icon,
//     required IconData activeIcon,
//     required String title,
//     required String subtitle,
//     required Color color,
//   }) {
//     final isSelected = _selectedMethod == method;
//     return GestureDetector(
//       onTap: () {
//         setState(() => _selectedMethod = method);
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
//         decoration: BoxDecoration(
//           color: isSelected ? color.withOpacity(0.06) : Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: isSelected ? color : AppTheme.cardBorder,
//             width: isSelected ? 2 : 1,
//           ),
//           boxShadow: isSelected
//               ? [
//                   BoxShadow(
//                     color: color.withOpacity(0.12),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   )
//                 ]
//               : [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.02),
//                     blurRadius: 6,
//                     offset: const Offset(0, 2),
//                   )
//                 ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: isSelected ? color.withOpacity(0.15) : color.withOpacity(0.08),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 isSelected ? activeIcon : icon,
//                 color: color,
//                 size: 24,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               subtitle,
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               style: TextStyle(
//                 fontSize: 11,
//                 color: isSelected ? AppTheme.textSecondary : AppTheme.textMuted,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── 3. Upload View Dropzone ──
//   Widget _buildUploadView(bool isDesktop) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppTheme.cardBorder),
//       ),
//       child: Column(
//         children: [
//           InkWell(
//             onTap: () => _pickAndExtractImage(),
//             borderRadius: BorderRadius.circular(16),
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(36),
//               decoration: BoxDecoration(
//                 color: AppTheme.backgroundMint.withOpacity(0.5),
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 1.5),
//               ),
//               child: Column(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(Icons.cloud_upload_outlined, color: AppTheme.primaryGreen, size: 36),
//                   ),
//                   const SizedBox(height: 16),
//                   const Text(
//                     'Click to upload product image or select sample',
//                     style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
//                   ),
//                   const SizedBox(height: 6),
//                   const Text(
//                     'Supports JPG, PNG • Gemini Developer API will extract details automatically',
//                     style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           if (_uploadedImages.isNotEmpty) ...[
//             Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 'Selected Image (${_uploadedImages.length}):',
//                 style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
//               ),
//             ),
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 ..._uploadedImages.map(
//                   (img) => Stack(
//                     children: [
//                       Container(
//                         margin: const EdgeInsets.only(right: 12),
//                         width: 90,
//                         height: 90,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(color: AppTheme.primaryGreen, width: 2),
//                           image: const DecorationImage(
//                             image: AssetImage('assets/images/milk.png'),
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         top: 4,
//                         right: 16,
//                         child: GestureDetector(
//                           onTap: () => setState(() => _uploadedImages.remove(img)),
//                           child: Container(
//                             padding: const EdgeInsets.all(2),
//                             decoration: const BoxDecoration(
//                               color: Colors.black54,
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(Icons.close, size: 14, color: Colors.white),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//           ],
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               OutlinedButton.icon(
//                 style: OutlinedButton.styleFrom(
//                   minimumSize: const Size(160, 48),
//                 ),
//                 onPressed: () => _pickAndExtractImage(),
//                 icon: const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primaryGreen),
//                 label: const Text('Choose Image'),
//               ),
//               const SizedBox(width: 16),
//               ElevatedButton.icon(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppTheme.primaryGreen,
//                   minimumSize: const Size(200, 48),
//                 ),
//                 onPressed: () => _triggerGeminiAIExtraction('Uploaded Image'),
//                 icon: const Icon(Icons.auto_awesome, color: Colors.white),
//                 label: const Text('Extract with Gemini AI'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   void _pickAndExtractImage() async {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (ctx) => Container(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Upload Product Image',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Choose an option to pick image from your device for Gemini AI extraction:',
//               style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
//             ),
//             const SizedBox(height: 20),
//             ListTile(
//               leading: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: AppTheme.primaryGreen.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryGreen),
//               ),
//               title: const Text('Choose from Gallery / Files'),
//               subtitle: const Text('Select product image from device storage'),
//               onTap: () async {
//                 Navigator.pop(ctx);
//                 final picker = ImagePicker();
//                 final XFile? file = await picker.pickImage(source: ImageSource.gallery);
//                 if (file != null) {
//                   _triggerGeminiAIExtraction(file.name.isNotEmpty ? file.name : 'Selected Gallery Image');
//                 } else {
//                   _triggerGeminiAIExtraction('Selected Device Image');
//                 }
//               },
//             ),
//             const Divider(),
//             ListTile(
//               leading: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: AppTheme.accentGreen.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.camera_alt_outlined, color: AppTheme.accentGreen),
//               ),
//               title: const Text('Take Photo with Camera'),
//               subtitle: const Text('Capture product packaging immediately'),
//               onTap: () async {
//                 Navigator.pop(ctx);
//                 final picker = ImagePicker();
//                 final XFile? file = await picker.pickImage(source: ImageSource.camera);
//                 if (file != null) {
//                   _triggerGeminiAIExtraction(file.name.isNotEmpty ? file.name : 'Camera Photo');
//                 } else {
//                   _triggerGeminiAIExtraction('Camera Photo');
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAnalyzingOverlay() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(40),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppTheme.accentGreen.withOpacity(0.5)),
//       ),
//       child: Column(
//         children: [
//           const CircularProgressIndicator(color: AppTheme.primaryGreen),
//           const SizedBox(height: 20),
//           Text(
//             _scanningStatusText ?? 'Extracting product information...',
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Gemini AI is parsing product name, brand, prices, and expiry label variations...',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDesktopFormLayout() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               flex: 3,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Item Details',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildTextField(
//                     label: 'Product Name *',
//                     controller: _nameController,
//                     hint: 'e.g. Amul Milk',
//                     validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required' : null,
//                   ),
//                   const SizedBox(height: 16),
//                   _buildCategoryDropdown(),
//                   const SizedBox(height: 16),
//                   _buildTextField(
//                     label: 'Brand (Optional)',
//                     controller: _brandController,
//                     hint: 'e.g. Amul',
//                   ),
//                   const SizedBox(height: 16),
//                   _buildTextField(
//                     label: 'Batch Number *',
//                     controller: _batchNumberController,
//                     hint: 'e.g. B-99402',
//                     validator: (v) => v == null || v.trim().isEmpty ? 'Batch number is required' : null,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 24),
//             Expanded(
//               flex: 3,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 38),
//                   _buildTextField(
//                     label: 'Quantity / Size *',
//                     controller: _quantityController,
//                     hint: 'e.g. 1 L, 500 g, 1 pack',
//                     validator: (v) => v == null || v.trim().isEmpty ? 'Quantity is required' : null,
//                   ),
//                   const SizedBox(height: 16),
//                   _buildTextField(
//                     label: 'Original Price (₹) *',
//                     controller: _priceController,
//                     keyboardType: TextInputType.number,
//                     hint: 'e.g. 60',
//                     onChanged: (_) => setState(() {}),
//                     validator: (v) {
//                       if (v == null || v.trim().isEmpty) return 'Price is required';
//                       if (double.tryParse(v) == null) return 'Enter a valid price number';
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16),
//                   _buildDatePickerTile(
//                     label: 'Expiry Date *',
//                     date: _expiryDate,
//                     onTap: () => _selectDate(context),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildSuggestedSellingPriceCard(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 24),
//         _buildImagesSection(),
//         const SizedBox(height: 32),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: [
//             OutlinedButton(
//               style: OutlinedButton.styleFrom(
//                 minimumSize: const Size(120, 48),
//               ),
//               onPressed: () {
//                 if (Navigator.of(context).canPop()) Navigator.of(context).pop();
//               },
//               child: const Text('Cancel'),
//             ),
//             const SizedBox(width: 16),
//             ElevatedButton.icon(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppTheme.primaryGreen,
//                 minimumSize: const Size(160, 48),
//               ),
//               onPressed: _submitForm,
//               icon: const Icon(Icons.archive_outlined, color: Colors.white),
//               label: const Text('Save Item'),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildMobileFormLayout() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Item Details',
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
//         ),
//         const SizedBox(height: 16),
//         _buildTextField(
//           label: 'Product Name *',
//           controller: _nameController,
//           hint: 'e.g. Amul Milk',
//           validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required' : null,
//         ),
//         const SizedBox(height: 16),
//         _buildCategoryDropdown(),
//         const SizedBox(height: 16),
//         _buildTextField(
//           label: 'Brand (Optional)',
//           controller: _brandController,
//           hint: 'e.g. Amul',
//         ),
//         const SizedBox(height: 16),
//         _buildTextField(
//           label: 'Batch Number *',
//           controller: _batchNumberController,
//           hint: 'e.g. B-99402',
//           validator: (v) => v == null || v.trim().isEmpty ? 'Batch number is required' : null,
//         ),
//         const SizedBox(height: 16),
//         _buildTextField(
//           label: 'Quantity / Size *',
//           controller: _quantityController,
//           hint: 'e.g. 1 L, 500 g, 1 pack',
//           validator: (v) => v == null || v.trim().isEmpty ? 'Quantity is required' : null,
//         ),
//         const SizedBox(height: 16),
//         _buildTextField(
//           label: 'Original Price (₹) *',
//           controller: _priceController,
//           keyboardType: TextInputType.number,
//           hint: 'e.g. 60',
//           onChanged: (_) => setState(() {}),
//           validator: (v) {
//             if (v == null || v.trim().isEmpty) return 'Price is required';
//             if (double.tryParse(v) == null) return 'Enter a valid price number';
//             return null;
//           },
//         ),
//         const SizedBox(height: 16),
//         _buildDatePickerTile(
//           label: 'Expiry Date *',
//           date: _expiryDate,
//           onTap: () => _selectDate(context),
//         ),
//         const SizedBox(height: 16),
//         _buildSuggestedSellingPriceCard(),
//         const SizedBox(height: 20),
//         _buildImagesSection(),
//         const SizedBox(height: 28),
//         ElevatedButton.icon(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppTheme.primaryGreen,
//             minimumSize: const Size(double.infinity, 50),
//           ),
//           onPressed: _submitForm,
//           icon: const Icon(Icons.archive_outlined, color: Colors.white),
//           label: const Text('Save Item'),
//         ),
//       ],
//     );
//   }

//   Widget _buildTextField({
//     required String label,
//     required TextEditingController controller,
//     required String hint,
//     TextInputType keyboardType = TextInputType.text,
//     int maxLines = 1,
//     ValueChanged<String>? onChanged,
//     FormFieldValidator<String>? validator,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
//         ),
//         const SizedBox(height: 6),
//         TextFormField(
//           controller: controller,
//           keyboardType: keyboardType,
//           maxLines: maxLines,
//           onChanged: onChanged,
//           validator: validator,
//           style: const TextStyle(fontSize: 14),
//           decoration: InputDecoration(
//             hintText: hint,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCategoryDropdown() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Category *',
//           style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
//         ),
//         const SizedBox(height: 6),
//         DropdownButtonFormField<String>(
//           value: _selectedCategory,
//           items: _categories
//               .map((cat) => DropdownMenuItem(
//                     value: cat,
//                     child: Text(cat, style: const TextStyle(fontSize: 14)),
//                   ))
//               .toList(),
//           onChanged: (val) {
//             if (val != null) setState(() => _selectedCategory = val);
//           },
//           decoration: const InputDecoration(
//             contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDatePickerTile({
//     required String label,
//     required DateTime? date,
//     required VoidCallback onTap,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
//         ),
//         const SizedBox(height: 6),
//         InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(12),
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: AppTheme.cardBorder),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   date == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(date),
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: date == null ? AppTheme.textMuted : AppTheme.textPrimary,
//                   ),
//                 ),
//                 const Icon(Icons.calendar_month_outlined, size: 20, color: AppTheme.textSecondary),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSuggestedSellingPriceCard() {
//     final suggested = _suggestedSellingPrice;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF0FDF4),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFBBF7D0)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: const BoxDecoration(
//               color: Color(0xFFDCFCE7),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.currency_rupee, color: AppTheme.primaryGreen, size: 20),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Suggested Selling Price',
//                   style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   'Calculated automatically based on days until expiry',
//                   style: TextStyle(fontSize: 11, color: Colors.green.shade700),
//                 ),
//               ],
//             ),
//           ),
//           Text(
//             suggested != null ? '₹ ${suggested.toStringAsFixed(1)}' : '₹ --',
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildImagesSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Images (Optional)',
//           style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
//         ),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             InkWell(
//               onTap: () => _triggerGeminiAIExtraction('Uploaded Image'),
//               borderRadius: BorderRadius.circular(12),
//               child: Container(
//                 width: 90,
//                 height: 90,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: AppTheme.cardBorder, style: BorderStyle.solid),
//                 ),
//                 child: const Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryGreen, size: 24),
//                     SizedBox(height: 4),
//                     Text('Add more', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             ..._uploadedImages.map(
//               (img) => Stack(
//                 children: [
//                   Container(
//                     margin: const EdgeInsets.only(right: 12),
//                     width: 90,
//                     height: 90,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12),
//                       image: const DecorationImage(
//                         image: AssetImage('assets/images/milk.png'),
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     top: 4,
//                     right: 16,
//                     child: GestureDetector(
//                       onTap: () => setState(() => _uploadedImages.remove(img)),
//                       child: Container(
//                         padding: const EdgeInsets.all(2),
//                         decoration: const BoxDecoration(
//                           color: Colors.black54,
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(Icons.close, size: 14, color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

//version 3 ---2.0

// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:image_picker/image_picker.dart';

// import '../models/product_model.dart';
// import '../providers/product_provider.dart';
// import '../services/gemini_extraction_service.dart';
// import '../theme/app_theme.dart';

// enum ProductInputMethod { manual, upload }

// class AddProductScreen extends StatefulWidget {
//   final VoidCallback? onItemAdded;

//   const AddProductScreen({
//     super.key,
//     this.onItemAdded,
//   });

//   @override
//   State<AddProductScreen> createState() => _AddProductScreenState();
// }

// class _AddProductScreenState extends State<AddProductScreen> {
//   final _formKey = GlobalKey<FormState>();

//   ProductInputMethod _selectedMethod = ProductInputMethod.manual;

//   bool _isExtracting = false;
//   bool _isAnalyzing = false;

//   String? _scanningStatusText;

//   // ------------------------------------------------------------
//   // Form controllers
//   // ------------------------------------------------------------

//   final _nameController = TextEditingController();
//   final _brandController = TextEditingController();
//   final _quantityController = TextEditingController();
//   final _priceController = TextEditingController();
//   final _batchNumberController = TextEditingController();

//   String _selectedCategory = 'Dairy';

//   DateTime? _expiryDate;

//   // Image names are used only for the existing UI.
//   // Actual image bytes are kept separately for Gemini.
//   final List<String> _uploadedImages = [];

//   Uint8List? _selectedImageBytes;
//   String _selectedImageMimeType = 'image/jpeg';

//   // ------------------------------------------------------------
//   // Categories
//   // ------------------------------------------------------------

//   final List<String> _categories = [
//     'Dairy',
//     'Bakery',
//     'Beverages',
//     'Snacks',
//     'Produce',
//     'Pulses',
//     'Spices',
//     'Pantry',
//     'Personal Care',
//     'Household',
//     'Others',
//   ];

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _brandController.dispose();
//     _quantityController.dispose();
//     _priceController.dispose();
//     _batchNumberController.dispose();
//     super.dispose();
//   }

//   // ============================================================
//   // SUGGESTED SELLING PRICE
//   // ============================================================

//   double? get _suggestedSellingPrice {
//     final priceStr = _priceController.text.trim();

//     if (priceStr.isEmpty || _expiryDate == null) {
//       return null;
//     }

//     final price = double.tryParse(priceStr);

//     if (price == null) {
//       return null;
//     }

//     final now = DateTime.now();

//     final today = DateTime(
//       now.year,
//       now.month,
//       now.day,
//     );

//     final expiry = DateTime(
//       _expiryDate!.year,
//       _expiryDate!.month,
//       _expiryDate!.day,
//     );

//     final daysRemaining =
//         expiry.difference(today).inDays;

//     if (daysRemaining < 0) {
//       return 0.0;
//     }

//     if (daysRemaining <= 3) {
//       return price * 0.75;
//     }

//     if (daysRemaining <= 5) {
//       return price * 0.90;
//     }

//     if (daysRemaining <= 7) {
//       return price * 0.95;
//     }

//     return price;
//   }

//   // ============================================================
//   // DATE PICKER
//   // ============================================================

//   Future<void> _selectDate(BuildContext context) async {
//     final initialDate =
//         _expiryDate ??
//         DateTime.now().add(
//           const Duration(days: 14),
//         );

//     final picked = await showDatePicker(
//       context: context,
//       initialDate: initialDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2035),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: AppTheme.primaryGreen,
//               onPrimary: Colors.white,
//               onSurface: AppTheme.textPrimary,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null) {
//       setState(() {
//         _expiryDate = picked;
//       });
//     }
//   }

//   // ============================================================
//   // GEMINI EXTRACTION
//   // ============================================================

//   Future<void> _triggerGeminiAIExtraction(
//     String source,
//   ) async {
//     if (_selectedImageBytes == null) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please select an image first.',
//           ),
//           backgroundColor: AppTheme.expiredRed,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );

//       return;
//     }

//     setState(() {
//       _isExtracting = true;
//       _isAnalyzing = true;
//       _scanningStatusText =
//           'Extracting product information with Gemini AI...';
//     });

//     try {
//       final extracted =
//           await GeminiExtractionService.extractProductFromImage(
//         _selectedImageBytes!,
//         mimeType: _selectedImageMimeType,
//       );

//       if (!mounted) return;

//       if (extracted == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Could not extract product information from the image.',
//             ),
//             backgroundColor: AppTheme.expiredRed,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );

//         return;
//       }

//       setState(() {
//         // --------------------------------------------------------
//         // Product Name
//         // --------------------------------------------------------

//         if (extracted.productName.trim().isNotEmpty) {
//           _nameController.text =
//               extracted.productName.trim();
//         }

//         // --------------------------------------------------------
//         // Brand
//         // --------------------------------------------------------

//         if (extracted.brand.trim().isNotEmpty) {
//           _brandController.text =
//               extracted.brand.trim();
//         }

//         // --------------------------------------------------------
//         // Category
//         // --------------------------------------------------------

//         final mappedCategory =
//             _mapGeminiCategory(
//           extracted.category,
//         );

//         if (mappedCategory != null) {
//           _selectedCategory = mappedCategory;
//         }

//         // --------------------------------------------------------
//         // Quantity / Size
//         // --------------------------------------------------------

//         if (extracted.quantitySize.trim().isNotEmpty) {
//           _quantityController.text =
//               extracted.quantitySize.trim();
//         }

//         // --------------------------------------------------------
//         // Original Price
//         // --------------------------------------------------------

//         if (extracted.originalPrice > 0) {
//           _priceController.text =
//               extracted.originalPrice
//                   .toStringAsFixed(2);
//         }

//         // --------------------------------------------------------
//         // Expiry Date
//         // Gemini returns YYYY-MM-DD
//         // --------------------------------------------------------

//         if (extracted.expiryDate.trim().isNotEmpty) {
//           final parsedDate =
//               DateTime.tryParse(
//             extracted.expiryDate.trim(),
//           );

//           if (parsedDate != null) {
//             _expiryDate = parsedDate;
//           }
//         }

//         // --------------------------------------------------------
//         // Batch Number
//         // --------------------------------------------------------

//         if (extracted.batchNumber.trim().isNotEmpty) {
//           _batchNumberController.text =
//               extracted.batchNumber.trim();
//         }
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Product information extracted successfully. Please review the fields.',
//           ),
//           backgroundColor: AppTheme.primaryGreen,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Gemini extraction failed: $e',
//           ),
//           backgroundColor: AppTheme.expiredRed,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isExtracting = false;
//           _isAnalyzing = false;
//           _scanningStatusText = null;
//         });
//       }
//     }
//   }

//   // ============================================================
//   // GEMINI CATEGORY MAPPING
//   // ============================================================

//   String? _mapGeminiCategory(String category) {
//     final value = category.trim().toLowerCase();

//     if (value.isEmpty) {
//       return null;
//     }

//     if (value == 'dairy' ||
//         value == 'dairy & eggs' ||
//         value == 'dairy and eggs') {
//       return 'Dairy';
//     }

//     if (value == 'bakery' ||
//         value == 'bakery & bread' ||
//         value == 'bakery and bread') {
//       return 'Bakery';
//     }

//     if (value == 'beverages') {
//       return 'Beverages';
//     }

//     if (value == 'snacks' ||
//         value == 'snacks & confectionery' ||
//         value == 'snacks and confectionery') {
//       return 'Snacks';
//     }

//     if (value == 'produce' ||
//         value == 'fruits & vegetables' ||
//         value == 'fruits and vegetables') {
//       return 'Produce';
//     }

//     if (value == 'pulses') {
//       return 'Pulses';
//     }

//     if (value == 'spices') {
//       return 'Spices';
//     }

//     if (value == 'pantry' ||
//         value == 'pantry & staples' ||
//         value == 'pantry and staples') {
//       return 'Pantry';
//     }

//     if (value == 'personal care') {
//       return 'Personal Care';
//     }

//     if (value == 'household' ||
//         value == 'household items') {
//       return 'Household';
//     }

//     if (value == 'other' ||
//         value == 'others') {
//       return 'Others';
//     }

//     return null;
//   }

//   // ============================================================
//   // MISSING FIELDS PROMPT
//   // ============================================================

//   void _showMissingFieldsPrompt(
//     List<String> missingFields,
//   ) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         title: const Row(
//           children: [
//             Icon(
//               Icons.info_outline_rounded,
//               color: AppTheme.warningOrange,
//             ),
//             SizedBox(width: 8),
//             Text('Complete Missing Details'),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment:
//               CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Gemini extracted most product details, but couldn\'t confidently identify the following required fields:',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: AppTheme.textSecondary,
//               ),
//             ),
//             const SizedBox(height: 12),
//             ...missingFields.map(
//               (field) => Padding(
//                 padding:
//                     const EdgeInsets.symmetric(
//                   vertical: 4.0,
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(
//                       Icons.check_circle_outline,
//                       size: 16,
//                       color: AppTheme.warningOrange,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       field,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             const Text(
//               'Please complete these fields in the form below before saving.',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: AppTheme.textMuted,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor:
//                   AppTheme.primaryGreen,
//             ),
//             onPressed: () =>
//                 Navigator.of(ctx).pop(),
//             child: const Text(
//               'OK, Fill Manually',
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // SUBMIT FORM
//   // ============================================================

//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please fill all required fields before saving.',
//           ),
//           backgroundColor: AppTheme.expiredRed,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );

//       return;
//     }

//     if (_expiryDate == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please select an Expiry Date for the product.',
//           ),
//           backgroundColor: AppTheme.expiredRed,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );

//       return;
//     }

//     // ----------------------------------------------------------
//     // Parse quantity
//     // ----------------------------------------------------------

//     int qty = 1;

//     final qtyMatches = RegExp(
//       r'\d+',
//     ).firstMatch(
//       _quantityController.text,
//     );

//     if (qtyMatches != null) {
//       qty = int.tryParse(
//             qtyMatches.group(0)!,
//           ) ??
//           1;
//     }

//     // ----------------------------------------------------------
//     // Parse price safely
//     // ----------------------------------------------------------

//     final price = double.tryParse(
//       _priceController.text.trim(),
//     );

//     if (price == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please enter a valid price.',
//           ),
//           backgroundColor: AppTheme.expiredRed,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );

//       return;
//     }

//     // ----------------------------------------------------------
//     // Create ProductModel
//     // ----------------------------------------------------------

//     final newProduct = ProductModel(
//       id: '',
//       name: _nameController.text.trim(),
//       category: _selectedCategory,
//       expiryDate: _expiryDate!,
//       originalPrice: price,
//       quantity: qty,
//       brand: _brandController.text.trim().isEmpty
//           ? null
//           : _brandController.text.trim(),
//       batchNumber:
//           _batchNumberController.text.trim(),
//     );

//     // ----------------------------------------------------------
//     // Save through ProductProvider
//     // ----------------------------------------------------------

//     final productProvider =
//         Provider.of<ProductProvider>(
//       context,
//       listen: false,
//     );

//     final success =
//         await productProvider.addProduct(
//       newProduct,
//     );

//     if (!mounted) return;

//     if (success) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Successfully added "${newProduct.name}" to inventory!',
//           ),
//           backgroundColor:
//               AppTheme.primaryGreen,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );

//       if (widget.onItemAdded != null) {
//         widget.onItemAdded!();
//       } else if (Navigator.of(context).canPop()) {
//         Navigator.of(context).pop();
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             productProvider.errorMessage ??
//                 'Failed to save product.',
//           ),
//           backgroundColor: AppTheme.expiredRed,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }

//   // ============================================================
//   // BUILD
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     final isDesktop = size.width > 900;

//     return SingleChildScrollView(
//       padding: EdgeInsets.symmetric(
//         horizontal:
//             isDesktop ? 32.0 : 16.0,
//         vertical: 24.0,
//       ),
//       child: Column(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Add New Item',
//             style: TextStyle(
//               fontSize: 26,
//               fontWeight: FontWeight.bold,
//               color: AppTheme.textPrimary,
//             ),
//           ),

//           const SizedBox(height: 4),

//           const Text(
//             'Add a new product to your inventory',
//             style: TextStyle(
//               fontSize: 14,
//               color: AppTheme.textSecondary,
//             ),
//           ),

//           const SizedBox(height: 24),

//           _buildMethodSelector(
//             isDesktop,
//           ),

//           const SizedBox(height: 28),

//           if (_isAnalyzing)
//             _buildAnalyzingOverlay()
//           else if (
//               _selectedMethod ==
//               ProductInputMethod.upload
//           )
//             _buildUploadView(isDesktop)
//           else
//             Form(
//               key: _formKey,
//               child: isDesktop
//                   ? _buildDesktopFormLayout()
//                   : _buildMobileFormLayout(),
//             ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // METHOD SELECTOR
//   // ============================================================

//   Widget _buildMethodSelector(
//     bool isDesktop,
//   ) {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Choose a method',
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: AppTheme.textPrimary,
//           ),
//         ),

//         const SizedBox(height: 12),

//         Row(
//           children: [
//             Expanded(
//               child: _buildMethodCard(
//                 method:
//                     ProductInputMethod.manual,
//                 icon: Icons.edit_outlined,
//                 activeIcon: Icons.edit,
//                 title: 'Add Manually',
//                 subtitle:
//                     'Enter product details manually',
//                 color:
//                     const Color(0xFF10B981),
//               ),
//             ),

//             const SizedBox(width: 12),

//             Expanded(
//               child: _buildMethodCard(
//                 method:
//                     ProductInputMethod.upload,
//                 icon:
//                     Icons.photo_camera_outlined,
//                 activeIcon:
//                     Icons.photo_camera,
//                 title: 'Upload Image',
//                 subtitle:
//                     'Upload image of product to extract',
//                 color:
//                     const Color(0xFF8B5CF6),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildMethodCard({
//     required ProductInputMethod method,
//     required IconData icon,
//     required IconData activeIcon,
//     required String title,
//     required String subtitle,
//     required Color color,
//   }) {
//     final isSelected =
//         _selectedMethod == method;

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _selectedMethod = method;
//         });
//       },
//       child: AnimatedContainer(
//         duration:
//             const Duration(milliseconds: 200),
//         padding:
//             const EdgeInsets.symmetric(
//           horizontal: 14,
//           vertical: 16,
//         ),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? color.withOpacity(0.06)
//               : Colors.white,
//           borderRadius:
//               BorderRadius.circular(16),
//           border: Border.all(
//             color: isSelected
//                 ? color
//                 : AppTheme.cardBorder,
//             width:
//                 isSelected ? 2 : 1,
//           ),
//           boxShadow: isSelected
//               ? [
//                   BoxShadow(
//                     color:
//                         color.withOpacity(0.12),
//                     blurRadius: 10,
//                     offset:
//                         const Offset(0, 4),
//                   ),
//                 ]
//               : [
//                   BoxShadow(
//                     color: Colors.black
//                         .withOpacity(0.02),
//                     blurRadius: 6,
//                     offset:
//                         const Offset(0, 2),
//                   ),
//                 ],
//         ),
//         child: Column(
//           mainAxisAlignment:
//               MainAxisAlignment.center,
//           children: [
//             Container(
//               padding:
//                   const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: isSelected
//                     ? color.withOpacity(0.15)
//                     : color.withOpacity(0.08),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 isSelected
//                     ? activeIcon
//                     : icon,
//                 color: color,
//                 size: 24,
//               ),
//             ),

//             const SizedBox(height: 10),

//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight:
//                     FontWeight.bold,
//                 color: isSelected
//                     ? AppTheme.textPrimary
//                     : AppTheme.textSecondary,
//               ),
//             ),

//             const SizedBox(height: 4),

//             Text(
//               subtitle,
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               style: TextStyle(
//                 fontSize: 11,
//                 color: isSelected
//                     ? AppTheme.textSecondary
//                     : AppTheme.textMuted,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // ANALYZING OVERLAY
//   // ============================================================

//   Widget _buildAnalyzingOverlay() {
//     return Container(
//       width: double.infinity,
//       padding:
//           const EdgeInsets.all(40),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.circular(16),
//         border: Border.all(
//           color: AppTheme.accentGreen
//               .withOpacity(0.5),
//         ),
//       ),
//       child: Column(
//         children: [
//           const CircularProgressIndicator(
//             color: AppTheme.primaryGreen,
//           ),

//           const SizedBox(height: 20),

//           Text(
//             _scanningStatusText ??
//                 'Extracting product information...',
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight:
//                   FontWeight.bold,
//               color:
//                   AppTheme.primaryGreen,
//             ),
//           ),

//           const SizedBox(height: 8),

//           const Text(
//             'Gemini AI is parsing product name, brand, prices, and expiry label variations...',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 13,
//               color:
//                   AppTheme.textSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // UPLOAD VIEW
//   // ============================================================

//   Widget _buildUploadView(
//     bool isDesktop,
//   ) {
//     return Container(
//       width: double.infinity,
//       padding:
//           const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.circular(16),
//         border: Border.all(
//           color: AppTheme.cardBorder,
//         ),
//       ),
//       child: Column(
//         children: [
//           InkWell(
//             onTap:
//                 () => _pickAndExtractImage(),
//             borderRadius:
//                 BorderRadius.circular(16),
//             child: Container(
//               width: double.infinity,
//               padding:
//                   const EdgeInsets.all(36),
//               decoration: BoxDecoration(
//                 color: AppTheme
//                     .backgroundMint
//                     .withOpacity(0.5),
//                 borderRadius:
//                     BorderRadius.circular(16),
//                 border: Border.all(
//                   color: AppTheme
//                       .primaryGreen
//                       .withOpacity(0.3),
//                   width: 1.5,
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   Container(
//                     padding:
//                         const EdgeInsets.all(16),
//                     decoration:
//                         const BoxDecoration(
//                       color: Colors.white,
//                       shape:
//                           BoxShape.circle,
//                     ),
//                     child:
//                         const Icon(
//                       Icons
//                           .cloud_upload_outlined,
//                       color: AppTheme
//                           .primaryGreen,
//                       size: 36,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   const Text(
//                     'Click to upload product image or select sample',
//                     style: TextStyle(
//                       fontSize: 15,
//                       fontWeight:
//                           FontWeight.w600,
//                       color: AppTheme
//                           .textPrimary,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 6,
//                   ),

//                   const Text(
//                     'Supports JPG, PNG • Gemini Developer API will extract details automatically',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color:
//                           AppTheme.textMuted,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 20),

//           if (_uploadedImages
//               .isNotEmpty) ...[
//             Align(
//               alignment:
//                   Alignment.centerLeft,
//               child: Text(
//                 'Selected Image (${_uploadedImages.length}):',
//                 style:
//                     const TextStyle(
//                   fontSize: 13,
//                   fontWeight:
//                       FontWeight.bold,
//                   color:
//                       AppTheme.textPrimary,
//                 ),
//               ),
//             ),

//             const SizedBox(height: 10),

//             Row(
//               children:
//                   _uploadedImages.map(
//                 (img) => Stack(
//                   children: [
//                     Container(
//                       margin:
//                           const EdgeInsets
//                               .only(
//                         right: 12,
//                       ),
//                       width: 90,
//                       height: 90,
//                       decoration:
//                           BoxDecoration(
//                         borderRadius:
//                             BorderRadius
//                                 .circular(
//                           12,
//                         ),
//                         border:
//                             Border.all(
//                           color: AppTheme
//                               .primaryGreen,
//                           width: 2,
//                         ),
//                         image:
//                             const DecorationImage(
//                           image: AssetImage(
//                             'assets/images/milk.png',
//                           ),
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),

//                     Positioned(
//                       top: 4,
//                       right: 16,
//                       child:
//                           GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             _uploadedImages
//                                 .remove(
//                               img,
//                             );

//                             if (_uploadedImages
//                                 .isEmpty) {
//                               _selectedImageBytes =
//                                   null;
//                             }
//                           });
//                         },
//                         child: Container(
//                           padding:
//                               const EdgeInsets
//                                   .all(2),
//                           decoration:
//                               const BoxDecoration(
//                             color:
//                                 Colors.black54,
//                             shape:
//                                 BoxShape
//                                     .circle,
//                           ),
//                           child:
//                               const Icon(
//                             Icons.close,
//                             size: 14,
//                             color:
//                                 Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ).toList(),
//             ),

//             const SizedBox(height: 20),
//           ],

//           Row(
//             mainAxisAlignment:
//                 MainAxisAlignment.center,
//             children: [
//               OutlinedButton.icon(
//                 style:
//                     OutlinedButton.styleFrom(
//                   minimumSize:
//                       const Size(
//                     160,
//                     48,
//                   ),
//                 ),
//                 onPressed:
//                     () => _pickAndExtractImage(),
//                 icon:
//                     const Icon(
//                   Icons
//                       .add_photo_alternate_outlined,
//                   color: AppTheme
//                       .primaryGreen,
//                 ),
//                 label:
//                     const Text(
//                   'Choose Image',
//                 ),
//               ),

//               const SizedBox(width: 16),

//               ElevatedButton.icon(
//                 style:
//                     ElevatedButton.styleFrom(
//                   backgroundColor:
//                       AppTheme
//                           .primaryGreen,
//                   minimumSize:
//                       const Size(
//                     200,
//                     48,
//                   ),
//                 ),
//                 onPressed:
//                     () => _triggerGeminiAIExtraction(
//                   'Uploaded Image',
//                 ),
//                 icon:
//                     const Icon(
//                   Icons.auto_awesome,
//                   color:
//                       Colors.white,
//                 ),
//                 label:
//                     const Text(
//                   'Extract with Gemini AI',
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // PICK IMAGE
//   // ============================================================

//   Future<void> _pickAndExtractImage() async {
//     showModalBottomSheet(
//       context: context,
//       shape:
//           const RoundedRectangleBorder(
//         borderRadius:
//             BorderRadius.vertical(
//           top: Radius.circular(20),
//         ),
//       ),
//       builder: (ctx) {
//         return Container(
//           padding:
//               const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize:
//                 MainAxisSize.min,
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Upload Product Image',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight:
//                       FontWeight.bold,
//                   color:
//                       AppTheme.textPrimary,
//                 ),
//               ),

//               const SizedBox(height: 8),

//               const Text(
//                 'Choose an option to pick image from your device for Gemini AI extraction:',
//                 style: TextStyle(
//                   fontSize: 13,
//                   color:
//                       AppTheme.textSecondary,
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // ------------------------------------------------
//               // GALLERY
//               // ------------------------------------------------

//               ListTile(
//                 leading: Container(
//                   padding:
//                       const EdgeInsets
//                           .all(8),
//                   decoration:
//                       BoxDecoration(
//                     color: AppTheme
//                         .primaryGreen
//                         .withOpacity(0.1),
//                     shape:
//                         BoxShape.circle,
//                   ),
//                   child:
//                       const Icon(
//                     Icons
//                         .photo_library_outlined,
//                     color: AppTheme
//                         .primaryGreen,
//                   ),
//                 ),
//                 title: const Text(
//                   'Choose from Gallery / Files',
//                 ),
//                 subtitle: const Text(
//                   'Select product image from device storage',
//                 ),
//                 onTap: () async {
//                   Navigator.pop(ctx);

//                   final picker =
//                       ImagePicker();

//                   final XFile? file =
//                       await picker.pickImage(
//                     source:
//                         ImageSource.gallery,
//                   );

//                   if (file == null) {
//                     return;
//                   }

//                   try {
//                     final bytes =
//                         await file
//                             .readAsBytes();

//                     final extension =
//                         file.name
//                             .split('.')
//                             .last
//                             .toLowerCase();

//                     String mimeType =
//                         'image/jpeg';

//                     if (extension ==
//                         'png') {
//                       mimeType =
//                           'image/png';
//                     } else if (extension ==
//                         'webp') {
//                       mimeType =
//                           'image/webp';
//                     } else if (extension ==
//                             'jpg' ||
//                         extension ==
//                             'jpeg') {
//                       mimeType =
//                           'image/jpeg';
//                     }

//                     setState(() {
//                       _selectedImageBytes =
//                           bytes;

//                       _selectedImageMimeType =
//                           mimeType;

//                       final imageName =
//                           file.name
//                                   .isNotEmpty
//                               ? file.name
//                               : 'Selected Gallery Image';

//                       if (!_uploadedImages
//                           .contains(
//                         imageName,
//                       )) {
//                         _uploadedImages
//                             .add(
//                           imageName,
//                         );
//                       }
//                     });

//                     await _triggerGeminiAIExtraction(
//                       file.name
//                               .isNotEmpty
//                           ? file.name
//                           : 'Selected Gallery Image',
//                     );
//                   } catch (e) {
//                     if (!mounted) {
//                       return;
//                     }

//                     ScaffoldMessenger
//                             .of(context)
//                         .showSnackBar(
//                       SnackBar(
//                         content: Text(
//                           'Unable to read image: $e',
//                         ),
//                         backgroundColor:
//                             AppTheme
//                                 .expiredRed,
//                       ),
//                     );
//                   }
//                 },
//               ),

//               const Divider(),

//               // ------------------------------------------------
//               // CAMERA
//               // ------------------------------------------------

//               ListTile(
//                 leading: Container(
//                   padding:
//                       const EdgeInsets
//                           .all(8),
//                   decoration:
//                       BoxDecoration(
//                     color: AppTheme
//                         .accentGreen
//                         .withOpacity(0.1),
//                     shape:
//                         BoxShape.circle,
//                   ),
//                   child:
//                       const Icon(
//                     Icons
//                         .camera_alt_outlined,
//                     color: AppTheme
//                         .accentGreen,
//                   ),
//                 ),
//                 title: const Text(
//                   'Take Photo with Camera',
//                 ),
//                 subtitle: const Text(
//                   'Capture product packaging immediately',
//                 ),
//                 onTap: () async {
//                   Navigator.pop(ctx);

//                   final picker =
//                       ImagePicker();

//                   final XFile? file =
//                       await picker.pickImage(
//                     source:
//                         ImageSource.camera,
//                   );

//                   if (file == null) {
//                     return;
//                   }

//                   try {
//                     final bytes =
//                         await file
//                             .readAsBytes();

//                     setState(() {
//                       _selectedImageBytes =
//                           bytes;

//                       _selectedImageMimeType =
//                           'image/jpeg';

//                       final imageName =
//                           file.name
//                                   .isNotEmpty
//                               ? file.name
//                               : 'Camera Photo';

//                       if (!_uploadedImages
//                           .contains(
//                         imageName,
//                       )) {
//                         _uploadedImages
//                             .add(
//                           imageName,
//                         );
//                       }
//                     });

//                     await _triggerGeminiAIExtraction(
//                       file.name
//                               .isNotEmpty
//                           ? file.name
//                           : 'Camera Photo',
//                     );
//                   } catch (e) {
//                     if (!mounted) {
//                       return;
//                     }

//                     ScaffoldMessenger
//                             .of(context)
//                         .showSnackBar(
//                       SnackBar(
//                         content: Text(
//                           'Unable to read camera image: $e',
//                         ),
//                         backgroundColor:
//                             AppTheme
//                                 .expiredRed,
//                       ),
//                     );
//                   }
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ============================================================
//   // DESKTOP FORM
//   // ============================================================

//   Widget _buildDesktopFormLayout() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         Row(
//           crossAxisAlignment:
//               CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               flex: 3,
//               child: Column(
//                 crossAxisAlignment:
//                     CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Item Details',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight:
//                           FontWeight.bold,
//                       color:
//                           AppTheme.textPrimary,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   _buildTextField(
//                     label:
//                         'Product Name *',
//                     controller:
//                         _nameController,
//                     hint:
//                         'e.g. Amul Milk',
//                     validator: (v) =>
//                         v == null ||
//                                 v.trim()
//                                     .isEmpty
//                             ? 'Product name is required'
//                             : null,
//                   ),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   _buildCategoryDropdown(),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   _buildTextField(
//                     label:
//                         'Brand (Optional)',
//                     controller:
//                         _brandController,
//                     hint:
//                         'e.g. Amul',
//                   ),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   _buildTextField(
//                     label:
//                         'Batch Number *',
//                     controller:
//                         _batchNumberController,
//                     hint:
//                         'e.g. B-99402',
//                     validator: (v) =>
//                         v == null ||
//                                 v.trim()
//                                     .isEmpty
//                             ? 'Batch number is required'
//                             : null,
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(width: 24),

//             Expanded(
//               flex: 3,
//               child: Column(
//                 crossAxisAlignment:
//                     CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(
//                     height: 38,
//                   ),

//                   _buildTextField(
//                     label:
//                         'Quantity / Size *',
//                     controller:
//                         _quantityController,
//                     hint:
//                         'e.g. 1 L, 500 g, 1 pack',
//                     validator: (v) =>
//                         v == null ||
//                                 v.trim()
//                                     .isEmpty
//                             ? 'Quantity is required'
//                             : null,
//                   ),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   _buildTextField(
//                     label:
//                         'Original Price (₹) *',
//                     controller:
//                         _priceController,
//                     keyboardType:
//                         TextInputType
//                             .number,
//                     hint:
//                         'e.g. 60',
//                     onChanged: (_) =>
//                         setState(() {}),
//                     validator: (v) {
//                       if (v == null ||
//                           v.trim()
//                               .isEmpty) {
//                         return 'Price is required';
//                       }

//                       if (double.tryParse(
//                               v) ==
//                           null) {
//                         return 'Enter a valid price number';
//                       }

//                       return null;
//                     },
//                   ),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   _buildDatePickerTile(
//                     label:
//                         'Expiry Date *',
//                     date: _expiryDate,
//                     onTap: () =>
//                         _selectDate(
//                       context,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   _buildSuggestedSellingPriceCard(),
//                 ],
//               ),
//             ),
//           ],
//         ),

//         const SizedBox(height: 24),

//         _buildImagesSection(),

//         const SizedBox(height: 32),

//         Row(
//           mainAxisAlignment:
//               MainAxisAlignment.end,
//           children: [
//             OutlinedButton(
//               style:
//                   OutlinedButton.styleFrom(
//                 minimumSize:
//                     const Size(
//                   120,
//                   48,
//                 ),
//               ),
//               onPressed: () {
//                 if (Navigator.of(
//                   context,
//                 ).canPop()) {
//                   Navigator.of(
//                     context,
//                   ).pop();
//                 }
//               },
//               child:
//                   const Text('Cancel'),
//             ),

//             const SizedBox(width: 16),

//             ElevatedButton.icon(
//               style:
//                   ElevatedButton.styleFrom(
//                 backgroundColor:
//                     AppTheme
//                         .primaryGreen,
//                 minimumSize:
//                     const Size(
//                   160,
//                   48,
//                 ),
//               ),
//               onPressed:
//                   _submitForm,
//               icon:
//                   const Icon(
//                 Icons.archive_outlined,
//                 color:
//                     Colors.white,
//               ),
//               label:
//                   const Text(
//                 'Save Item',
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   // ============================================================
//   // MOBILE FORM
//   // ============================================================

//   Widget _buildMobileFormLayout() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Item Details',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight:
//                 FontWeight.bold,
//             color:
//                 AppTheme.textPrimary,
//           ),
//         ),

//         const SizedBox(height: 16),

//         _buildTextField(
//           label:
//               'Product Name *',
//           controller:
//               _nameController,
//           hint:
//               'e.g. Amul Milk',
//           validator: (v) =>
//               v == null ||
//                       v.trim()
//                           .isEmpty
//                   ? 'Product name is required'
//                   : null,
//         ),

//         const SizedBox(height: 16),

//         _buildCategoryDropdown(),

//         const SizedBox(height: 16),

//         _buildTextField(
//           label:
//               'Brand (Optional)',
//           controller:
//               _brandController,
//           hint:
//               'e.g. Amul',
//         ),

//         const SizedBox(height: 16),

//         _buildTextField(
//           label:
//               'Batch Number *',
//           controller:
//               _batchNumberController,
//           hint:
//               'e.g. B-99402',
//           validator: (v) =>
//               v == null ||
//                       v.trim()
//                           .isEmpty
//                   ? 'Batch number is required'
//                   : null,
//         ),

//         const SizedBox(height: 16),

//         _buildTextField(
//           label:
//               'Quantity / Size *',
//           controller:
//               _quantityController,
//           hint:
//               'e.g. 1 L, 500 g, 1 pack',
//           validator: (v) =>
//               v == null ||
//                       v.trim()
//                           .isEmpty
//                   ? 'Quantity is required'
//                   : null,
//         ),

//         const SizedBox(height: 16),

//         _buildTextField(
//           label:
//               'Original Price (₹) *',
//           controller:
//               _priceController,
//           keyboardType:
//               TextInputType.number,
//           hint:
//               'e.g. 60',
//           onChanged: (_) =>
//               setState(() {}),
//           validator: (v) {
//             if (v == null ||
//                 v.trim().isEmpty) {
//               return 'Price is required';
//             }

//             if (double.tryParse(v) ==
//                 null) {
//               return 'Enter a valid price number';
//             }

//             return null;
//           },
//         ),

//         const SizedBox(height: 16),

//         _buildDatePickerTile(
//           label:
//               'Expiry Date *',
//           date: _expiryDate,
//           onTap: () =>
//               _selectDate(context),
//         ),

//         const SizedBox(height: 16),

//         _buildSuggestedSellingPriceCard(),

//         const SizedBox(height: 20),

//         _buildImagesSection(),

//         const SizedBox(height: 28),

//         ElevatedButton.icon(
//           style:
//               ElevatedButton.styleFrom(
//             backgroundColor:
//                 AppTheme
//                     .primaryGreen,
//             minimumSize:
//                 const Size(
//               double.infinity,
//               50,
//             ),
//           ),
//           onPressed:
//               _submitForm,
//           icon:
//               const Icon(
//             Icons.archive_outlined,
//             color:
//                 Colors.white,
//           ),
//           label:
//               const Text(
//             'Save Item',
//           ),
//         ),
//       ],
//     );
//   }

//   // ============================================================
//   // TEXT FIELD
//   // ============================================================

//   Widget _buildTextField({
//     required String label,
//     required TextEditingController
//         controller,
//     required String hint,
//     TextInputType keyboardType =
//         TextInputType.text,
//     int maxLines = 1,
//     ValueChanged<String>? onChanged,
//     FormFieldValidator<String>?
//         validator,
//   }) {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 13,
//             fontWeight:
//                 FontWeight.w600,
//             color:
//                 AppTheme.textPrimary,
//           ),
//         ),

//         const SizedBox(height: 6),

//         TextFormField(
//           controller: controller,
//           keyboardType:
//               keyboardType,
//           maxLines: maxLines,
//           onChanged: onChanged,
//           validator: validator,
//           style: const TextStyle(
//             fontSize: 14,
//           ),
//           decoration:
//               InputDecoration(
//             hintText: hint,
//           ),
//         ),
//       ],
//     );
//   }

//   // ============================================================
//   // CATEGORY DROPDOWN
//   // ============================================================

//   Widget _buildCategoryDropdown() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Category *',
//           style: TextStyle(
//             fontSize: 13,
//             fontWeight:
//                 FontWeight.w600,
//             color:
//                 AppTheme.textPrimary,
//           ),
//         ),

//         const SizedBox(height: 6),

//         DropdownButtonFormField<String>(
//           value: _selectedCategory,
//           items: _categories
//               .map(
//                 (cat) =>
//                     DropdownMenuItem(
//                   value: cat,
//                   child: Text(
//                     cat,
//                     style:
//                         const TextStyle(
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//               )
//               .toList(),
//           onChanged: (val) {
//             if (val != null) {
//               setState(() {
//                 _selectedCategory =
//                     val;
//               });
//             }
//           },
//           decoration:
//               const InputDecoration(
//             contentPadding:
//                 EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 14,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ============================================================
//   // DATE PICKER TILE
//   // ============================================================

//   Widget _buildDatePickerTile({
//     required String label,
//     required DateTime? date,
//     required VoidCallback onTap,
//   }) {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 13,
//             fontWeight:
//                 FontWeight.w600,
//             color:
//                 AppTheme.textPrimary,
//           ),
//         ),

//         const SizedBox(height: 6),

//         InkWell(
//           onTap: onTap,
//           borderRadius:
//               BorderRadius.circular(
//             12,
//           ),
//           child: Container(
//             padding:
//                 const EdgeInsets
//                     .symmetric(
//               horizontal: 16,
//               vertical: 14,
//             ),
//             decoration:
//                 BoxDecoration(
//               color: Colors.white,
//               borderRadius:
//                   BorderRadius.circular(
//                 12,
//               ),
//               border: Border.all(
//                 color:
//                     AppTheme.cardBorder,
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment:
//                   MainAxisAlignment
//                       .spaceBetween,
//               children: [
//                 Text(
//                   date == null
//                       ? 'Select Date'
//                       : DateFormat(
//                           'MMM dd, yyyy',
//                         ).format(date),
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: date == null
//                         ? AppTheme
//                             .textMuted
//                         : AppTheme
//                             .textPrimary,
//                   ),
//                 ),

//                 const Icon(
//                   Icons
//                       .calendar_month_outlined,
//                   size: 20,
//                   color:
//                       AppTheme.textSecondary,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ============================================================
//   // SUGGESTED SELLING PRICE CARD
//   // ============================================================

//   Widget _buildSuggestedSellingPriceCard() {
//     final suggested =
//         _suggestedSellingPrice;

//     return Container(
//       padding:
//           const EdgeInsets.all(16),
//       decoration:
//           BoxDecoration(
//         color:
//             const Color(0xFFF0FDF4),
//         borderRadius:
//             BorderRadius.circular(12),
//         border: Border.all(
//           color:
//               const Color(0xFFBBF7D0),
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding:
//                 const EdgeInsets.all(8),
//             decoration:
//                 const BoxDecoration(
//               color:
//                   Color(0xFFDCFCE7),
//               shape:
//                   BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.currency_rupee,
//               color:
//                   AppTheme.primaryGreen,
//               size: 20,
//             ),
//           ),

//           const SizedBox(width: 12),

//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment
//                       .start,
//               children: [
//                 const Text(
//                   'Suggested Selling Price',
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight:
//                         FontWeight.bold,
//                     color: AppTheme
//                         .primaryGreen,
//                   ),
//                 ),

//                 const SizedBox(height: 2),

//                 Text(
//                   'Calculated automatically based on days until expiry',
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: Colors
//                         .green
//                         .shade700,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           Text(
//             suggested != null
//                 ? '₹ ${suggested.toStringAsFixed(1)}'
//                 : '₹ --',
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight:
//                   FontWeight.bold,
//               color:
//                   AppTheme.primaryGreen,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // IMAGES SECTION
//   // ============================================================

//   Widget _buildImagesSection() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Images (Optional)',
//           style: TextStyle(
//             fontSize: 13,
//             fontWeight:
//                 FontWeight.w600,
//             color:
//                 AppTheme.textPrimary,
//           ),
//         ),

//         const SizedBox(height: 10),

//         Row(
//           children: [
//             InkWell(
//               onTap: () =>
//                   _triggerGeminiAIExtraction(
//                 'Uploaded Image',
//               ),
//               borderRadius:
//                   BorderRadius.circular(
//                 12,
//               ),
//               child: Container(
//                 width: 90,
//                 height: 90,
//                 decoration:
//                     BoxDecoration(
//                   color: Colors.white,
//                   borderRadius:
//                       BorderRadius.circular(
//                     12,
//                   ),
//                   border: Border.all(
//                     color:
//                         AppTheme.cardBorder,
//                   ),
//                 ),
//                 child: const Column(
//                   mainAxisAlignment:
//                       MainAxisAlignment
//                           .center,
//                   children: [
//                     Icon(
//                       Icons
//                           .add_a_photo_outlined,
//                       color: AppTheme
//                           .primaryGreen,
//                       size: 24,
//                     ),

//                     SizedBox(height: 4),

//                     Text(
//                       'Add more',
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: AppTheme
//                             .textSecondary,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(width: 12),

//             ..._uploadedImages.map(
//               (img) => Stack(
//                 children: [
//                   Container(
//                     margin:
//                         const EdgeInsets
//                             .only(
//                       right: 12,
//                     ),
//                     width: 90,
//                     height: 90,
//                     decoration:
//                         BoxDecoration(
//                       borderRadius:
//                           BorderRadius
//                               .circular(
//                         12,
//                       ),
//                       image:
//                           const DecorationImage(
//                         image: AssetImage(
//                           'assets/images/milk.png',
//                         ),
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   ),

//                   Positioned(
//                     top: 4,
//                     right: 16,
//                     child:
//                         GestureDetector(
//                       onTap: () {
//                         setState(() {
//                           _uploadedImages
//                               .remove(
//                             img,
//                           );

//                           if (_uploadedImages
//                               .isEmpty) {
//                             _selectedImageBytes =
//                                 null;
//                           }
//                         });
//                       },
//                       child: Container(
//                         padding:
//                             const EdgeInsets
//                                 .all(2),
//                         decoration:
//                             const BoxDecoration(
//                           color:
//                               Colors.black54,
//                           shape:
//                               BoxShape.circle,
//                         ),
//                         child:
//                             const Icon(
//                           Icons.close,
//                           size: 14,
//                           color:
//                               Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// versio 3 - fixing the data added

// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:image_picker/image_picker.dart';

// import '../models/product_model.dart';
// import '../providers/product_provider.dart';
// import '../services/gemini_extraction_service.dart';
// import '../theme/app_theme.dart';

// enum ProductInputMethod { manual, upload }

// class AddProductScreen extends StatefulWidget {
//   final VoidCallback? onItemAdded;

//   const AddProductScreen({
//     super.key,
//     this.onItemAdded,
//   });

//   @override
//   State<AddProductScreen> createState() => _AddProductScreenState();
// }

// class _AddProductScreenState extends State<AddProductScreen> {
//   final _formKey = GlobalKey<FormState>();

//   ProductInputMethod _selectedMethod =
//       ProductInputMethod.manual;

//   bool _isExtracting = false;
//   bool _isAnalyzing = false;

//   String? _scanningStatusText;

//   // ------------------------------------------------------------
//   // Form controllers
//   // ------------------------------------------------------------

//   final _nameController = TextEditingController();
//   final _brandController = TextEditingController();
//   final _quantityController = TextEditingController();
//   final _priceController = TextEditingController();
//   final _batchNumberController = TextEditingController();

//   String _selectedCategory = 'Dairy';

//   DateTime? _expiryDate;

//   // Image names are used only for the existing UI.
//   // Actual image bytes are kept separately for Gemini.
//   final List<String> _uploadedImages = [];

//   Uint8List? _selectedImageBytes;
//   String _selectedImageMimeType = 'image/jpeg';

//   // ------------------------------------------------------------
//   // Categories
//   // ------------------------------------------------------------

//   final List<String> _categories = [
//     'Dairy',
//     'Bakery',
//     'Beverages',
//     'Snacks',
//     'Produce',
//     'Pulses',
//     'Spices',
//     'Pantry',
//     'Personal Care',
//     'Household',
//     'Others',
//   ];

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _brandController.dispose();
//     _quantityController.dispose();
//     _priceController.dispose();
//     _batchNumberController.dispose();
//     super.dispose();
//   }

//   // ============================================================
//   // SUGGESTED SELLING PRICE
//   // ============================================================

//   double? get _suggestedSellingPrice {
//     final priceStr = _priceController.text.trim();

//     if (priceStr.isEmpty || _expiryDate == null) {
//       return null;
//     }

//     final price = double.tryParse(priceStr);

//     if (price == null) {
//       return null;
//     }

//     final now = DateTime.now();

//     final today = DateTime(
//       now.year,
//       now.month,
//       now.day,
//     );

//     final expiry = DateTime(
//       _expiryDate!.year,
//       _expiryDate!.month,
//       _expiryDate!.day,
//     );

//     final daysRemaining =
//         expiry.difference(today).inDays;

//     if (daysRemaining < 0) {
//       return 0.0;
//     }

//     if (daysRemaining <= 3) {
//       return price * 0.75;
//     }

//     if (daysRemaining <= 5) {
//       return price * 0.90;
//     }

//     if (daysRemaining <= 7) {
//       return price * 0.95;
//     }

//     return price;
//   }

//   // ============================================================
//   // DATE PICKER
//   // ============================================================

//   Future<void> _selectDate(BuildContext context) async {
//     final initialDate =
//         _expiryDate ??
//         DateTime.now().add(
//           const Duration(days: 14),
//         );

//     final picked = await showDatePicker(
//       context: context,
//       initialDate: initialDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2035),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: AppTheme.primaryGreen,
//               onPrimary: Colors.white,
//               onSurface: AppTheme.textPrimary,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null) {
//       setState(() {
//         _expiryDate = picked;
//       });
//     }
//   }

//   // ============================================================
//   // GEMINI EXTRACTION
//   // ============================================================

//   Future<void> _triggerGeminiAIExtraction(
//     String source,
//   ) async {
//     if (_selectedImageBytes == null) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please select an image first.',
//           ),
//           backgroundColor: AppTheme.expiredRed,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );

//       return;
//     }

//     setState(() {
//       _isExtracting = true;
//       _isAnalyzing = true;
//       _scanningStatusText =
//           'Extracting product information with Gemini AI...';
//     });

//     try {
//       final extracted =
//           await GeminiExtractionService.extractProductFromImage(
//         _selectedImageBytes!,
//         mimeType: _selectedImageMimeType,
//       );

//       if (!mounted) return;

//       if (extracted == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Could not extract product information from the image.',
//             ),
//             backgroundColor: AppTheme.expiredRed,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );

//         return;
//       }

//       setState(() {
//         // ========================================================
//         // IMPORTANT FIX
//         // ========================================================
//         // Gemini has successfully extracted the product data.
//         // Automatically switch from Upload Image to the
//         // Manual Data form so the user can immediately review
//         // and edit the extracted information.
//         _selectedMethod =
//             ProductInputMethod.manual;

//         // --------------------------------------------------------
//         // Product Name
//         // --------------------------------------------------------

//         if (extracted.productName.trim().isNotEmpty) {
//           _nameController.text =
//               extracted.productName.trim();
//         }

//         // --------------------------------------------------------
//         // Brand
//         // --------------------------------------------------------

//         if (extracted.brand.trim().isNotEmpty) {
//           _brandController.text =
//               extracted.brand.trim();
//         }

//         // --------------------------------------------------------
//         // Category
//         // --------------------------------------------------------

//         final mappedCategory =
//             _mapGeminiCategory(
//           extracted.category,
//         );

//         if (mappedCategory != null) {
//           _selectedCategory = mappedCategory;
//         }

//         // --------------------------------------------------------
//         // Quantity / Size
//         // --------------------------------------------------------

//         if (extracted.quantitySize.trim().isNotEmpty) {
//           _quantityController.text =
//               extracted.quantitySize.trim();
//         }

//         // --------------------------------------------------------
//         // Original Price
//         // --------------------------------------------------------

//         if (extracted.originalPrice > 0) {
//           _priceController.text =
//               extracted.originalPrice
//                   .toStringAsFixed(2);
//         }

//         // --------------------------------------------------------
//         // Expiry Date
//         // Gemini returns YYYY-MM-DD
//         // --------------------------------------------------------

//         if (extracted.expiryDate.trim().isNotEmpty) {
//           final parsedDate =
//               DateTime.tryParse(
//             extracted.expiryDate.trim(),
//           );

//           if (parsedDate != null) {
//             _expiryDate = parsedDate;
//           }
//         }

//         // --------------------------------------------------------
//         // Batch Number
//         // --------------------------------------------------------

//         if (extracted.batchNumber.trim().isNotEmpty) {
//           _batchNumberController.text =
//               extracted.batchNumber.trim();
//         }
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Details extracted successfully. Please review and save.',
//           ),
//           backgroundColor: AppTheme.primaryGreen,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Gemini extraction failed: $e',
//           ),
//           backgroundColor: AppTheme.expiredRed,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isExtracting = false;
//           _isAnalyzing = false;
//           _scanningStatusText = null;
//         });
//       }
//     }
//   }

//   // ============================================================
//   // GEMINI CATEGORY MAPPING
//   // ============================================================

//   String? _mapGeminiCategory(String category) {
//     final value = category.trim().toLowerCase();

//     if (value.isEmpty) {
//       return null;
//     }

//     if (value == 'dairy' ||
//         value == 'dairy & eggs' ||
//         value == 'dairy and eggs') {
//       return 'Dairy';
//     }

//     if (value == 'bakery' ||
//         value == 'bakery & bread' ||
//         value == 'bakery and bread') {
//       return 'Bakery';
//     }

//     if (value == 'beverages') {
//       return 'Beverages';
//     }

//     if (value == 'snacks' ||
//         value == 'snacks & confectionery' ||
//         value == 'snacks and confectionery') {
//       return 'Snacks';
//     }

//     if (value == 'produce' ||
//         value == 'fruits & vegetables' ||
//         value == 'fruits and vegetables') {
//       return 'Produce';
//     }

//     if (value == 'pulses') {
//       return 'Pulses';
//     }

//     if (value == 'spices') {
//       return 'Spices';
//     }

//     if (value == 'pantry' ||
//         value == 'pantry & staples' ||
//         value == 'pantry and staples') {
//       return 'Pantry';
//     }

//     if (value == 'personal care') {
//       return 'Personal Care';
//     }

//     if (value == 'household' ||
//         value == 'household items') {
//       return 'Household';
//     }

//     if (value == 'other' ||
//         value == 'others') {
//       return 'Others';
//     }

//     return null;
//   }

//   // ============================================================
//   // MISSING FIELDS PROMPT
//   // ============================================================

//   void _showMissingFieldsPrompt(
//     List<String> missingFields,
//   ) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         title: const Row(
//           children: [
//             Icon(
//               Icons.info_outline_rounded,
//               color: AppTheme.warningOrange,
//             ),
//             SizedBox(width: 8),
//             Text('Complete Missing Details'),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment:
//               CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Gemini extracted most product details, but couldn\'t confidently identify the following required fields:',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: AppTheme.textSecondary,
//               ),
//             ),
//             const SizedBox(height: 12),
//             ...missingFields.map(
//               (field) => Padding(
//                 padding:
//                     const EdgeInsets.symmetric(
//                   vertical: 4.0,
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(
//                       Icons.check_circle_outline,
//                       size: 16,
//                       color: AppTheme.warningOrange,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       field,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             const Text(
//               'Please complete these fields in the form below before saving.',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: AppTheme.textMuted,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor:
//                   AppTheme.primaryGreen,
//             ),
//             onPressed: () =>
//                 Navigator.of(ctx).pop(),
//             child: const Text(
//               'OK, Fill Manually',
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // SUBMIT FORM
//   // ============================================================

//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please fill all required fields before saving.',
//           ),
//           backgroundColor: AppTheme.expiredRed,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );

//       return;
//     }

//     if (_expiryDate == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please select an Expiry Date for the product.',
//           ),
//           backgroundColor: AppTheme.expiredRed,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );

//       return;
//     }

//     // ----------------------------------------------------------
//     // Parse quantity
//     // ----------------------------------------------------------

//     int qty = 1;

//     final qtyMatches = RegExp(
//       r'\d+',
//     ).firstMatch(
//       _quantityController.text,
//     );

//     if (qtyMatches != null) {
//       qty = int.tryParse(
//             qtyMatches.group(0)!,
//           ) ??
//           1;
//     }

//     // ----------------------------------------------------------
//     // Parse price safely
//     // ----------------------------------------------------------

//     final price = double.tryParse(
//       _priceController.text.trim(),
//     );

//     if (price == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please enter a valid price.',
//           ),
//           backgroundColor: AppTheme.expiredRed,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );

//       return;
//     }

//     // ----------------------------------------------------------
//     // Create ProductModel
//     // ----------------------------------------------------------

//     final newProduct = ProductModel(
//       id: '',
//       name: _nameController.text.trim(),
//       category: _selectedCategory,
//       expiryDate: _expiryDate!,
//       originalPrice: price,
//       quantity: qty,
//       brand: _brandController.text.trim().isEmpty
//           ? null
//           : _brandController.text.trim(),
//       batchNumber:
//           _batchNumberController.text.trim(),
//     );

//     // ----------------------------------------------------------
//     // Save through ProductProvider
//     // ----------------------------------------------------------

//     final productProvider =
//         Provider.of<ProductProvider>(
//       context,
//       listen: false,
//     );

//     final success =
//         await productProvider.addProduct(
//       newProduct,
//     );

//     if (!mounted) return;

//     if (success) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Successfully added "${newProduct.name}" to inventory!',
//           ),
//           backgroundColor:
//               AppTheme.primaryGreen,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );

//       if (widget.onItemAdded != null) {
//         widget.onItemAdded!();
//       } else if (Navigator.of(context).canPop()) {
//         Navigator.of(context).pop();
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             productProvider.errorMessage ??
//                 'Failed to save product.',
//           ),
//           backgroundColor: AppTheme.expiredRed,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }

//   // ============================================================
//   // BUILD
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     final isDesktop = size.width > 900;

//     return SingleChildScrollView(
//       padding: EdgeInsets.symmetric(
//         horizontal:
//             isDesktop ? 32.0 : 16.0,
//         vertical: 24.0,
//       ),
//       child: Column(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Add New Item',
//             style: TextStyle(
//               fontSize: 26,
//               fontWeight: FontWeight.bold,
//               color: AppTheme.textPrimary,
//             ),
//           ),

//           const SizedBox(height: 4),

//           const Text(
//             'Add a new product to your inventory',
//             style: TextStyle(
//               fontSize: 14,
//               color: AppTheme.textSecondary,
//             ),
//           ),

//           const SizedBox(height: 24),

//           _buildMethodSelector(
//             isDesktop,
//           ),

//           const SizedBox(height: 28),

//           if (_isAnalyzing)
//             _buildAnalyzingOverlay()
//           else if (
//               _selectedMethod ==
//               ProductInputMethod.upload
//           )
//             _buildUploadView(isDesktop)
//           else
//             Form(
//               key: _formKey,
//               child: isDesktop
//                   ? _buildDesktopFormLayout()
//                   : _buildMobileFormLayout(),
//             ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // METHOD SELECTOR
//   // ============================================================

//   Widget _buildMethodSelector(
//     bool isDesktop,
//   ) {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Choose a method',
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: AppTheme.textPrimary,
//           ),
//         ),

//         const SizedBox(height: 12),

//         Row(
//           children: [
//             Expanded(
//               child: _buildMethodCard(
//                 method:
//                     ProductInputMethod.manual,
//                 icon: Icons.edit_outlined,
//                 activeIcon: Icons.edit,
//                 title: 'Add Manually',
//                 subtitle:
//                     'Enter product details manually',
//                 color:
//                     const Color(0xFF10B981),
//               ),
//             ),

//             const SizedBox(width: 12),

//             Expanded(
//               child: _buildMethodCard(
//                 method:
//                     ProductInputMethod.upload,
//                 icon:
//                     Icons.photo_camera_outlined,
//                 activeIcon:
//                     Icons.photo_camera,
//                 title: 'Upload Image',
//                 subtitle:
//                     'Upload image of product to extract',
//                 color:
//                     const Color(0xFF8B5CF6),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildMethodCard({
//     required ProductInputMethod method,
//     required IconData icon,
//     required IconData activeIcon,
//     required String title,
//     required String subtitle,
//     required Color color,
//   }) {
//     final isSelected =
//         _selectedMethod == method;

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _selectedMethod = method;
//         });
//       },
//       child: AnimatedContainer(
//         duration:
//             const Duration(milliseconds: 200),
//         padding:
//             const EdgeInsets.symmetric(
//           horizontal: 14,
//           vertical: 16,
//         ),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? color.withOpacity(0.06)
//               : Colors.white,
//           borderRadius:
//               BorderRadius.circular(16),
//           border: Border.all(
//             color: isSelected
//                 ? color
//                 : AppTheme.cardBorder,
//             width:
//                 isSelected ? 2 : 1,
//           ),
//           boxShadow: isSelected
//               ? [
//                   BoxShadow(
//                     color:
//                         color.withOpacity(0.12),
//                     blurRadius: 10,
//                     offset:
//                         const Offset(0, 4),
//                   ),
//                 ]
//               : [
//                   BoxShadow(
//                     color: Colors.black
//                         .withOpacity(0.02),
//                     blurRadius: 6,
//                     offset:
//                         const Offset(0, 2),
//                   ),
//                 ],
//         ),
//         child: Column(
//           mainAxisAlignment:
//               MainAxisAlignment.center,
//           children: [
//             Container(
//               padding:
//                   const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: isSelected
//                     ? color.withOpacity(0.15)
//                     : color.withOpacity(0.08),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 isSelected
//                     ? activeIcon
//                     : icon,
//                 color: color,
//                 size: 24,
//               ),
//             ),

//             const SizedBox(height: 10),

//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight:
//                     FontWeight.bold,
//                 color: isSelected
//                     ? AppTheme.textPrimary
//                     : AppTheme.textSecondary,
//               ),
//             ),

//             const SizedBox(height: 4),

//             Text(
//               subtitle,
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               style: TextStyle(
//                 fontSize: 11,
//                 color: isSelected
//                     ? AppTheme.textSecondary
//                     : AppTheme.textMuted,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // ANALYZING OVERLAY
//   // ============================================================

//   Widget _buildAnalyzingOverlay() {
//     return Container(
//       width: double.infinity,
//       padding:
//           const EdgeInsets.all(40),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.circular(16),
//         border: Border.all(
//           color: AppTheme.accentGreen
//               .withOpacity(0.5),
//         ),
//       ),
//       child: Column(
//         children: [
//           const CircularProgressIndicator(
//             color: AppTheme.primaryGreen,
//           ),

//           const SizedBox(height: 20),

//           Text(
//             _scanningStatusText ??
//                 'Extracting product information...',
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight:
//                   FontWeight.bold,
//               color:
//                   AppTheme.primaryGreen,
//             ),
//           ),

//           const SizedBox(height: 8),

//           const Text(
//             'Gemini AI is parsing product name, brand, prices, and expiry label variations...',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 13,
//               color:
//                   AppTheme.textSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // UPLOAD VIEW
//   // ============================================================

//   Widget _buildUploadView(
//     bool isDesktop,
//   ) {
//     return Container(
//       width: double.infinity,
//       padding:
//           const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.circular(16),
//         border: Border.all(
//           color: AppTheme.cardBorder,
//         ),
//       ),
//       child: Column(
//         children: [
//           InkWell(
//             onTap:
//                 () => _pickAndExtractImage(),
//             borderRadius:
//                 BorderRadius.circular(16),
//             child: Container(
//               width: double.infinity,
//               padding:
//                   const EdgeInsets.all(36),
//               decoration: BoxDecoration(
//                 color: AppTheme
//                     .backgroundMint
//                     .withOpacity(0.5),
//                 borderRadius:
//                     BorderRadius.circular(16),
//                 border: Border.all(
//                   color: AppTheme
//                       .primaryGreen
//                       .withOpacity(0.3),
//                   width: 1.5,
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   Container(
//                     padding:
//                         const EdgeInsets.all(16),
//                     decoration:
//                         const BoxDecoration(
//                       color: Colors.white,
//                       shape:
//                           BoxShape.circle,
//                     ),
//                     child:
//                         const Icon(
//                       Icons
//                           .cloud_upload_outlined,
//                       color: AppTheme
//                           .primaryGreen,
//                       size: 36,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   const Text(
//                     'Click to upload product image or select sample',
//                     style: TextStyle(
//                       fontSize: 15,
//                       fontWeight:
//                           FontWeight.w600,
//                       color: AppTheme
//                           .textPrimary,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 6,
//                   ),

//                   const Text(
//                     'Supports JPG, PNG • Gemini Developer API will extract details automatically',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color:
//                           AppTheme.textMuted,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 20),

//           if (_uploadedImages
//               .isNotEmpty) ...[
//             Align(
//               alignment:
//                   Alignment.centerLeft,
//               child: Text(
//                 'Selected Image (${_uploadedImages.length}):',
//                 style:
//                     const TextStyle(
//                   fontSize: 13,
//                   fontWeight:
//                       FontWeight.bold,
//                   color:
//                       AppTheme.textPrimary,
//                 ),
//               ),
//             ),

//             const SizedBox(height: 10),

//             Row(
//               children:
//                   _uploadedImages.map(
//                 (img) => Stack(
//                   children: [
//                     Container(
//                       margin:
//                           const EdgeInsets
//                               .only(
//                         right: 12,
//                       ),
//                       width: 90,
//                       height: 90,
//                       decoration:
//                           BoxDecoration(
//                         borderRadius:
//                             BorderRadius
//                                 .circular(
//                           12,
//                         ),
//                         border:
//                             Border.all(
//                           color: AppTheme
//                               .primaryGreen,
//                           width: 2,
//                         ),
//                         image:
//                             const DecorationImage(
//                           image: AssetImage(
//                             'assets/images/milk.png',
//                           ),
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),

//                     Positioned(
//                       top: 4,
//                       right: 16,
//                       child:
//                           GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             _uploadedImages
//                                 .remove(
//                               img,
//                             );

//                             if (_uploadedImages
//                                 .isEmpty) {
//                               _selectedImageBytes =
//                                   null;
//                             }
//                           });
//                         },
//                         child: Container(
//                           padding:
//                               const EdgeInsets
//                                   .all(2),
//                           decoration:
//                               const BoxDecoration(
//                             color:
//                                 Colors.black54,
//                             shape:
//                                 BoxShape
//                                     .circle,
//                           ),
//                           child:
//                               const Icon(
//                             Icons.close,
//                             size: 14,
//                             color:
//                                 Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ).toList(),
//             ),

//             const SizedBox(height: 20),
//           ],

//           Row(
//             mainAxisAlignment:
//                 MainAxisAlignment.center,
//             children: [
//               OutlinedButton.icon(
//                 style:
//                     OutlinedButton.styleFrom(
//                   minimumSize:
//                       const Size(
//                     160,
//                     48,
//                   ),
//                 ),
//                 onPressed:
//                     () => _pickAndExtractImage(),
//                 icon:
//                     const Icon(
//                   Icons
//                       .add_photo_alternate_outlined,
//                   color: AppTheme
//                       .primaryGreen,
//                 ),
//                 label:
//                     const Text(
//                   'Choose Image',
//                 ),
//               ),

//               const SizedBox(width: 16),

//               ElevatedButton.icon(
//                 style:
//                     ElevatedButton.styleFrom(
//                   backgroundColor:
//                       AppTheme
//                           .primaryGreen,
//                   minimumSize:
//                       const Size(
//                     200,
//                     48,
//                   ),
//                 ),
//                 onPressed:
//                     () => _triggerGeminiAIExtraction(
//                   'Uploaded Image',
//                 ),
//                 icon:
//                     const Icon(
//                   Icons.auto_awesome,
//                   color:
//                       Colors.white,
//                 ),
//                 label:
//                     const Text(
//                   'Extract with Gemini AI',
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // PICK IMAGE
//   // ============================================================

//   Future<void> _pickAndExtractImage() async {
//     showModalBottomSheet(
//       context: context,
//       shape:
//           const RoundedRectangleBorder(
//         borderRadius:
//             BorderRadius.vertical(
//           top: Radius.circular(20),
//         ),
//       ),
//       builder: (ctx) {
//         return Container(
//           padding:
//               const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize:
//                 MainAxisSize.min,
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Upload Product Image',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight:
//                       FontWeight.bold,
//                   color:
//                       AppTheme.textPrimary,
//                 ),
//               ),

//               const SizedBox(height: 8),

//               const Text(
//                 'Choose an option to pick image from your device for Gemini AI extraction:',
//                 style: TextStyle(
//                   fontSize: 13,
//                   color:
//                       AppTheme.textSecondary,
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // ------------------------------------------------
//               // GALLERY
//               // ------------------------------------------------

//               ListTile(
//                 leading: Container(
//                   padding:
//                       const EdgeInsets
//                           .all(8),
//                   decoration:
//                       BoxDecoration(
//                     color: AppTheme
//                         .primaryGreen
//                         .withOpacity(0.1),
//                     shape:
//                         BoxShape.circle,
//                   ),
//                   child:
//                       const Icon(
//                     Icons
//                         .photo_library_outlined,
//                     color: AppTheme
//                         .primaryGreen,
//                   ),
//                 ),
//                 title: const Text(
//                   'Choose from Gallery / Files',
//                 ),
//                 subtitle: const Text(
//                   'Select product image from device storage',
//                 ),
//                 onTap: () async {
//                   Navigator.pop(ctx);

//                   final picker =
//                       ImagePicker();

//                   final XFile? file =
//                       await picker.pickImage(
//                     source:
//                         ImageSource.gallery,
//                   );

//                   if (file == null) {
//                     return;
//                   }

//                   try {
//                     final bytes =
//                         await file
//                             .readAsBytes();

//                     final extension =
//                         file.name
//                             .split('.')
//                             .last
//                             .toLowerCase();

//                     String mimeType =
//                         'image/jpeg';

//                     if (extension ==
//                         'png') {
//                       mimeType =
//                           'image/png';
//                     } else if (extension ==
//                         'webp') {
//                       mimeType =
//                           'image/webp';
//                     } else if (extension ==
//                             'jpg' ||
//                         extension ==
//                             'jpeg') {
//                       mimeType =
//                           'image/jpeg';
//                     }

//                     setState(() {
//                       _selectedImageBytes =
//                           bytes;

//                       _selectedImageMimeType =
//                           mimeType;

//                       final imageName =
//                           file.name
//                                   .isNotEmpty
//                               ? file.name
//                               : 'Selected Gallery Image';

//                       if (!_uploadedImages
//                           .contains(
//                         imageName,
//                       )) {
//                         _uploadedImages
//                             .add(
//                           imageName,
//                         );
//                       }
//                     });

//                     await _triggerGeminiAIExtraction(
//                       file.name
//                               .isNotEmpty
//                           ? file.name
//                           : 'Selected Gallery Image',
//                     );
//                   } catch (e) {
//                     if (!mounted) {
//                       return;
//                     }

//                     ScaffoldMessenger
//                             .of(context)
//                         .showSnackBar(
//                       SnackBar(
//                         content: Text(
//                           'Unable to read image: $e',
//                         ),
//                         backgroundColor:
//                             AppTheme
//                                 .expiredRed,
//                       ),
//                     );
//                   }
//                 },
//               ),

//               const Divider(),

//               // ------------------------------------------------
//               // CAMERA
//               // ------------------------------------------------

//               ListTile(
//                 leading: Container(
//                   padding:
//                       const EdgeInsets
//                           .all(8),
//                   decoration:
//                       BoxDecoration(
//                     color: AppTheme
//                         .accentGreen
//                         .withOpacity(0.1),
//                     shape:
//                         BoxShape.circle,
//                   ),
//                   child:
//                       const Icon(
//                     Icons
//                         .camera_alt_outlined,
//                     color: AppTheme
//                         .accentGreen,
//                   ),
//                 ),
//                 title: const Text(
//                   'Take Photo with Camera',
//                 ),
//                 subtitle: const Text(
//                   'Capture product packaging immediately',
//                 ),
//                 onTap: () async {
//                   Navigator.pop(ctx);

//                   final picker =
//                       ImagePicker();

//                   final XFile? file =
//                       await picker.pickImage(
//                     source:
//                         ImageSource.camera,
//                   );

//                   if (file == null) {
//                     return;
//                   }

//                   try {
//                     final bytes =
//                         await file
//                             .readAsBytes();

//                     setState(() {
//                       _selectedImageBytes =
//                           bytes;

//                       _selectedImageMimeType =
//                           'image/jpeg';

//                       final imageName =
//                           file.name
//                                   .isNotEmpty
//                               ? file.name
//                               : 'Camera Photo';

//                       if (!_uploadedImages
//                           .contains(
//                         imageName,
//                       )) {
//                         _uploadedImages
//                             .add(
//                           imageName,
//                         );
//                       }
//                     });

//                     await _triggerGeminiAIExtraction(
//                       file.name
//                               .isNotEmpty
//                           ? file.name
//                           : 'Camera Photo',
//                     );
//                   } catch (e) {
//                     if (!mounted) {
//                       return;
//                     }

//                     ScaffoldMessenger
//                             .of(context)
//                         .showSnackBar(
//                       SnackBar(
//                         content: Text(
//                           'Unable to read camera image: $e',
//                         ),
//                         backgroundColor:
//                             AppTheme
//                                 .expiredRed,
//                       ),
//                     );
//                   }
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ============================================================
//   // DESKTOP FORM
//   // ============================================================

//   Widget _buildDesktopFormLayout() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         Row(
//           crossAxisAlignment:
//               CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               flex: 3,
//               child: Column(
//                 crossAxisAlignment:
//                     CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Item Details',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight:
//                           FontWeight.bold,
//                       color:
//                           AppTheme.textPrimary,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   _buildTextField(
//                     label:
//                         'Product Name *',
//                     controller:
//                         _nameController,
//                     hint:
//                         'e.g. Amul Milk',
//                     validator: (v) =>
//                         v == null ||
//                                 v.trim()
//                                     .isEmpty
//                             ? 'Product name is required'
//                             : null,
//                   ),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   _buildCategoryDropdown(),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   _buildTextField(
//                     label:
//                         'Brand (Optional)',
//                     controller:
//                         _brandController,
//                     hint:
//                         'e.g. Amul',
//                   ),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   _buildTextField(
//                     label:
//                         'Batch Number *',
//                     controller:
//                         _batchNumberController,
//                     hint:
//                         'e.g. B-99402',
//                     validator: (v) =>
//                         v == null ||
//                                 v.trim()
//                                     .isEmpty
//                             ? 'Batch number is required'
//                             : null,
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(width: 24),

//             Expanded(
//               flex: 3,
//               child: Column(
//                 crossAxisAlignment:
//                     CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(
//                     height: 38,
//                   ),

//                   _buildTextField(
//                     label:
//                         'Quantity / Size *',
//                     controller:
//                         _quantityController,
//                     hint:
//                         'e.g. 1 L, 500 g, 1 pack',
//                     validator: (v) =>
//                         v == null ||
//                                 v.trim()
//                                     .isEmpty
//                             ? 'Quantity is required'
//                             : null,
//                   ),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   _buildTextField(
//                     label:
//                         'Original Price (₹) *',
//                     controller:
//                         _priceController,
//                     keyboardType:
//                         TextInputType
//                             .number,
//                     hint:
//                         'e.g. 60',
//                     onChanged: (_) =>
//                         setState(() {}),
//                     validator: (v) {
//                       if (v == null ||
//                           v.trim()
//                               .isEmpty) {
//                         return 'Price is required';
//                       }

//                       if (double.tryParse(
//                               v) ==
//                           null) {
//                         return 'Enter a valid price number';
//                       }

//                       return null;
//                     },
//                   ),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   _buildDatePickerTile(
//                     label:
//                         'Expiry Date *',
//                     date: _expiryDate,
//                     onTap: () =>
//                         _selectDate(
//                       context,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 16,
//                   ),

//                   _buildSuggestedSellingPriceCard(),
//                 ],
//               ),
//             ),
//           ],
//         ),

//         const SizedBox(height: 24),

//         _buildImagesSection(),

//         const SizedBox(height: 32),

//         Row(
//           mainAxisAlignment:
//               MainAxisAlignment.end,
//           children: [
//             OutlinedButton(
//               style:
//                   OutlinedButton.styleFrom(
//                 minimumSize:
//                     const Size(
//                   120,
//                   48,
//                 ),
//               ),
//               onPressed: () {
//                 if (Navigator.of(
//                   context,
//                 ).canPop()) {
//                   Navigator.of(
//                     context,
//                   ).pop();
//                 }
//               },
//               child:
//                   const Text('Cancel'),
//             ),

//             const SizedBox(width: 16),

//             ElevatedButton.icon(
//               style:
//                   ElevatedButton.styleFrom(
//                 backgroundColor:
//                     AppTheme
//                         .primaryGreen,
//                 minimumSize:
//                     const Size(
//                   160,
//                   48,
//                 ),
//               ),
//               onPressed:
//                   _submitForm,
//               icon:
//                   const Icon(
//                 Icons.archive_outlined,
//                 color:
//                     Colors.white,
//               ),
//               label:
//                   const Text(
//                 'Save Item',
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   // ============================================================
//   // MOBILE FORM
//   // ============================================================

//   Widget _buildMobileFormLayout() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Item Details',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight:
//                 FontWeight.bold,
//             color:
//                 AppTheme.textPrimary,
//           ),
//         ),

//         const SizedBox(height: 16),

//         _buildTextField(
//           label:
//               'Product Name *',
//           controller:
//               _nameController,
//           hint:
//               'e.g. Amul Milk',
//           validator: (v) =>
//               v == null ||
//                       v.trim()
//                           .isEmpty
//                   ? 'Product name is required'
//                   : null,
//         ),

//         const SizedBox(height: 16),

//         _buildCategoryDropdown(),

//         const SizedBox(height: 16),

//         _buildTextField(
//           label:
//               'Brand (Optional)',
//           controller:
//               _brandController,
//           hint:
//               'e.g. Amul',
//         ),

//         const SizedBox(height: 16),

//         _buildTextField(
//           label:
//               'Batch Number *',
//           controller:
//               _batchNumberController,
//           hint:
//               'e.g. B-99402',
//           validator: (v) =>
//               v == null ||
//                       v.trim()
//                           .isEmpty
//                   ? 'Batch number is required'
//                   : null,
//         ),

//         const SizedBox(height: 16),

//         _buildTextField(
//           label:
//               'Quantity / Size *',
//           controller:
//               _quantityController,
//           hint:
//               'e.g. 1 L, 500 g, 1 pack',
//           validator: (v) =>
//               v == null ||
//                       v.trim()
//                           .isEmpty
//                   ? 'Quantity is required'
//                   : null,
//         ),

//         const SizedBox(height: 16),

//         _buildTextField(
//           label:
//               'Original Price (₹) *',
//           controller:
//               _priceController,
//           keyboardType:
//               TextInputType.number,
//           hint:
//               'e.g. 60',
//           onChanged: (_) =>
//               setState(() {}),
//           validator: (v) {
//             if (v == null ||
//                 v.trim().isEmpty) {
//               return 'Price is required';
//             }

//             if (double.tryParse(v) ==
//                 null) {
//               return 'Enter a valid price number';
//             }

//             return null;
//           },
//         ),

//         const SizedBox(height: 16),

//         _buildDatePickerTile(
//           label:
//               'Expiry Date *',
//           date: _expiryDate,
//           onTap: () =>
//               _selectDate(context),
//         ),

//         const SizedBox(height: 16),

//         _buildSuggestedSellingPriceCard(),

//         const SizedBox(height: 20),

//         _buildImagesSection(),

//         const SizedBox(height: 28),

//         ElevatedButton.icon(
//           style:
//               ElevatedButton.styleFrom(
//             backgroundColor:
//                 AppTheme
//                     .primaryGreen,
//             minimumSize:
//                 const Size(
//               double.infinity,
//               50,
//             ),
//           ),
//           onPressed:
//               _submitForm,
//           icon:
//               const Icon(
//             Icons.archive_outlined,
//             color:
//                 Colors.white,
//           ),
//           label:
//               const Text(
//             'Save Item',
//           ),
//         ),
//       ],
//     );
//   }

//   // ============================================================
//   // TEXT FIELD
//   // ============================================================

//   Widget _buildTextField({
//     required String label,
//     required TextEditingController
//         controller,
//     required String hint,
//     TextInputType keyboardType =
//         TextInputType.text,
//     int maxLines = 1,
//     ValueChanged<String>? onChanged,
//     FormFieldValidator<String>?
//         validator,
//   }) {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 13,
//             fontWeight:
//                 FontWeight.w600,
//             color:
//                 AppTheme.textPrimary,
//           ),
//         ),

//         const SizedBox(height: 6),

//         TextFormField(
//           controller: controller,
//           keyboardType:
//               keyboardType,
//           maxLines: maxLines,
//           onChanged: onChanged,
//           validator: validator,
//           style: const TextStyle(
//             fontSize: 14,
//           ),
//           decoration:
//               InputDecoration(
//             hintText: hint,
//           ),
//         ),
//       ],
//     );
//   }

//   // ============================================================
//   // CATEGORY DROPDOWN
//   // ============================================================

//   Widget _buildCategoryDropdown() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Category *',
//           style: TextStyle(
//             fontSize: 13,
//             fontWeight:
//                 FontWeight.w600,
//             color:
//                 AppTheme.textPrimary,
//           ),
//         ),

//         const SizedBox(height: 6),

//         DropdownButtonFormField<String>(
//           value: _selectedCategory,
//           items: _categories
//               .map(
//                 (cat) =>
//                     DropdownMenuItem(
//                   value: cat,
//                   child: Text(
//                     cat,
//                     style:
//                         const TextStyle(
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//               )
//               .toList(),
//           onChanged: (val) {
//             if (val != null) {
//               setState(() {
//                 _selectedCategory =
//                     val;
//               });
//             }
//           },
//           decoration:
//               const InputDecoration(
//             contentPadding:
//                 EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 14,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ============================================================
//   // DATE PICKER TILE
//   // ============================================================

//   Widget _buildDatePickerTile({
//     required String label,
//     required DateTime? date,
//     required VoidCallback onTap,
//   }) {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 13,
//             fontWeight:
//                 FontWeight.w600,
//             color:
//                 AppTheme.textPrimary,
//           ),
//         ),

//         const SizedBox(height: 6),

//         InkWell(
//           onTap: onTap,
//           borderRadius:
//               BorderRadius.circular(
//             12,
//           ),
//           child: Container(
//             padding:
//                 const EdgeInsets
//                     .symmetric(
//               horizontal: 16,
//               vertical: 14,
//             ),
//             decoration:
//                 BoxDecoration(
//               color: Colors.white,
//               borderRadius:
//                   BorderRadius.circular(
//                 12,
//               ),
//               border: Border.all(
//                 color:
//                     AppTheme.cardBorder,
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment:
//                   MainAxisAlignment
//                       .spaceBetween,
//               children: [
//                 Text(
//                   date == null
//                       ? 'Select Date'
//                       : DateFormat(
//                           'MMM dd, yyyy',
//                         ).format(date),
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: date == null
//                         ? AppTheme
//                             .textMuted
//                         : AppTheme
//                             .textPrimary,
//                   ),
//                 ),

//                 const Icon(
//                   Icons
//                       .calendar_month_outlined,
//                   size: 20,
//                   color:
//                       AppTheme.textSecondary,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ============================================================
//   // SUGGESTED SELLING PRICE CARD
//   // ============================================================

//   Widget _buildSuggestedSellingPriceCard() {
//     final suggested =
//         _suggestedSellingPrice;

//     return Container(
//       padding:
//           const EdgeInsets.all(16),
//       decoration:
//           BoxDecoration(
//         color:
//             const Color(0xFFF0FDF4),
//         borderRadius:
//             BorderRadius.circular(12),
//         border: Border.all(
//           color:
//               const Color(0xFFBBF7D0),
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding:
//                 const EdgeInsets.all(8),
//             decoration:
//                 const BoxDecoration(
//               color:
//                   Color(0xFFDCFCE7),
//               shape:
//                   BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.currency_rupee,
//               color:
//                   AppTheme.primaryGreen,
//               size: 20,
//             ),
//           ),

//           const SizedBox(width: 12),

//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment
//                       .start,
//               children: [
//                 const Text(
//                   'Suggested Selling Price',
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight:
//                         FontWeight.bold,
//                     color: AppTheme
//                         .primaryGreen,
//                   ),
//                 ),

//                 const SizedBox(height: 2),

//                 Text(
//                   'Calculated automatically based on days until expiry',
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: Colors
//                         .green
//                         .shade700,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           Text(
//             suggested != null
//                 ? '₹ ${suggested.toStringAsFixed(1)}'
//                 : '₹ --',
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight:
//                   FontWeight.bold,
//               color:
//                   AppTheme.primaryGreen,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // IMAGES SECTION
//   // ============================================================

//   Widget _buildImagesSection() {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Images (Optional)',
//           style: TextStyle(
//             fontSize: 13,
//             fontWeight:
//                 FontWeight.w600,
//             color:
//                 AppTheme.textPrimary,
//           ),
//         ),

//         const SizedBox(height: 10),

//         Row(
//           children: [
//             InkWell(
//               onTap: () =>
//                   _triggerGeminiAIExtraction(
//                 'Uploaded Image',
//               ),
//               borderRadius:
//                   BorderRadius.circular(
//                 12,
//               ),
//               child: Container(
//                 width: 90,
//                 height: 90,
//                 decoration:
//                     BoxDecoration(
//                   color: Colors.white,
//                   borderRadius:
//                       BorderRadius.circular(
//                     12,
//                   ),
//                   border: Border.all(
//                     color:
//                         AppTheme.cardBorder,
//                   ),
//                 ),
//                 child: const Column(
//                   mainAxisAlignment:
//                       MainAxisAlignment
//                           .center,
//                   children: [
//                     Icon(
//                       Icons
//                           .add_a_photo_outlined,
//                       color: AppTheme
//                           .primaryGreen,
//                       size: 24,
//                     ),

//                     SizedBox(height: 4),

//                     Text(
//                       'Add more',
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: AppTheme
//                             .textSecondary,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(width: 12),

//             ..._uploadedImages.map(
//               (img) => Stack(
//                 children: [
//                   Container(
//                     margin:
//                         const EdgeInsets
//                             .only(
//                       right: 12,
//                     ),
//                     width: 90,
//                     height: 90,
//                     decoration:
//                         BoxDecoration(
//                       borderRadius:
//                           BorderRadius
//                               .circular(
//                         12,
//                       ),
//                       image:
//                           const DecorationImage(
//                         image: AssetImage(
//                           'assets/images/milk.png',
//                         ),
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   ),

//                   Positioned(
//                     top: 4,
//                     right: 16,
//                     child:
//                         GestureDetector(
//                       onTap: () {
//                         setState(() {
//                           _uploadedImages
//                               .remove(
//                             img,
//                           );

//                           if (_uploadedImages
//                               .isEmpty) {
//                             _selectedImageBytes =
//                                 null;
//                           }
//                         });
//                       },
//                       child: Container(
//                         padding:
//                             const EdgeInsets
//                                 .all(2),
//                         decoration:
//                             const BoxDecoration(
//                           color:
//                               Colors.black54,
//                           shape:
//                               BoxShape.circle,
//                         ),
//                         child:
//                             const Icon(
//                           Icons.close,
//                           size: 14,
//                           color:
//                               Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

//version 4 - fixing calendar

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../services/gemini_extraction_service.dart';
import '../theme/app_theme.dart';

enum ProductInputMethod { manual, upload }

class AddProductScreen extends StatefulWidget {
  final VoidCallback? onItemAdded;

  const AddProductScreen({
    super.key,
    this.onItemAdded,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  ProductInputMethod _selectedMethod =
      ProductInputMethod.manual;

  bool _isExtracting = false;
  bool _isAnalyzing = false;

  String? _scanningStatusText;

  // ------------------------------------------------------------
  // Form controllers
  // ------------------------------------------------------------

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _batchNumberController = TextEditingController();

  String _selectedCategory = 'Dairy';

  DateTime? _expiryDate;

  // Image names are used only for the existing UI.
  // Actual image bytes are kept separately for Gemini.
  final List<String> _uploadedImages = [];

  Uint8List? _selectedImageBytes;
  String _selectedImageMimeType = 'image/jpeg';

  // ------------------------------------------------------------
  // Categories
  // ------------------------------------------------------------

  final List<String> _categories = [
    'Dairy',
    'Bakery',
    'Beverages',
    'Snacks',
    'Produce',
    'Pulses',
    'Spices',
    'Pantry',
    'Personal Care',
    'Household',
    'Others',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _batchNumberController.dispose();
    super.dispose();
  }

  // ============================================================
  // SUGGESTED SELLING PRICE
  // ============================================================

  double? get _suggestedSellingPrice {
    final priceStr = _priceController.text.trim();

    if (priceStr.isEmpty || _expiryDate == null) {
      return null;
    }

    final price = double.tryParse(priceStr);

    if (price == null) {
      return null;
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final expiry = DateTime(
      _expiryDate!.year,
      _expiryDate!.month,
      _expiryDate!.day,
    );

    final daysRemaining =
        expiry.difference(today).inDays;

    if (daysRemaining < 0) {
      return 0.0;
    }

    if (daysRemaining <= 3) {
      return price * 0.75;
    }

    if (daysRemaining <= 5) {
      return price * 0.90;
    }

    if (daysRemaining <= 7) {
      return price * 0.95;
    }

    return price;
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  // ============================================================
  // CUSTOM SMARTSHELF DATE PICKER
  // ============================================================

  Future<void> _selectDate(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());

    DateTime initialDate = _expiryDate != null
        ? DateUtils.dateOnly(_expiryDate!)
        : today;

    const firstAllowedYear = 2020;
    const lastAllowedYear = 2100;

    final firstDate = DateTime(firstAllowedYear, 1, 1);
    final lastDate = DateTime(lastAllowedYear, 12, 31);

    // Keep the initial date inside the selectable range.
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    } else if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final picked = await showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (dialogContext) {
        DateTime selectedDate = initialDate;
        DateTime visibleMonth = DateTime(
          initialDate.year,
          initialDate.month,
          1,
        );

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final screenWidth = MediaQuery.sizeOf(context).width;
            final screenHeight = MediaQuery.sizeOf(context).height;

            // Reference design is a wide desktop/web dialog.
            // On smaller screens we switch to a compact version
            // while keeping the same visual language.
            final isCompact = screenWidth < 700;

            final dialogWidth = isCompact
                ? screenWidth - 28
                : 780.0;

            final dialogHeight = isCompact
                ? (screenHeight * 0.78).clamp(440.0, 620.0)
                : 570.0;

            final monthName =
                DateFormat('MMMM yyyy').format(visibleMonth);

            final daysInMonth = DateTime(
              visibleMonth.year,
              visibleMonth.month + 1,
              0,
            ).day;

            // DateTime.weekday = Monday 1 ... Sunday 7.
            // Convert to Sunday 0 ... Saturday 6.
            final firstWeekday = DateTime(
              visibleMonth.year,
              visibleMonth.month,
              1,
            ).weekday % 7;

            final totalCells =
                ((firstWeekday + daysInMonth + 6) ~/ 7) * 7;

            final canGoPrevious =
                visibleMonth.year > firstAllowedYear ||
                (visibleMonth.year == firstAllowedYear &&
                    visibleMonth.month > 1);

            final canGoNext =
                visibleMonth.year < lastAllowedYear ||
                (visibleMonth.year == lastAllowedYear &&
                    visibleMonth.month < 12);

            final selectedDateText =
                DateFormat('EEEE, d MMMM').format(selectedDate);
            final selectedYearText =
                DateFormat('yyyy').format(selectedDate);

            final weekdayLabels = const [
              'Sun',
              'Mon',
              'Tue',
              'Wed',
              'Thu',
              'Fri',
              'Sat',
            ];

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isCompact ? 14 : 20,
                vertical: isCompact ? 14 : 20,
              ),
              child: SizedBox(
                width: dialogWidth,
                height: dialogHeight,
                child: Material(
                  color: Colors.white,
                  elevation: 18,
                  shadowColor: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(
                    isCompact ? 24 : 30,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isCompact
                      ? _buildCompactCalendarContent(
                          context: context,
                          dialogContext: dialogContext,
                          selectedDate: selectedDate,
                          selectedDateText: selectedDateText,
                          selectedYearText: selectedYearText,
                          visibleMonth: visibleMonth,
                          monthName: monthName,
                          firstWeekday: firstWeekday,
                          daysInMonth: daysInMonth,
                          totalCells: totalCells,
                          weekdayLabels: weekdayLabels,
                          today: today,
                          firstDate: firstDate,
                          lastDate: lastDate,
                          canGoPrevious: canGoPrevious,
                          canGoNext: canGoNext,
                          setDialogState: setDialogState,
                          onSelectedDate: (date) {
                            setDialogState(() {
                              selectedDate = date;
                            });
                          },
                          onVisibleMonthChanged: (month) {
                            setDialogState(() {
                              visibleMonth = month;
                            });
                          },
                        )
                      : Row(
                          children: [
                            // ==================================================
                            // LEFT DATE PANEL
                            // ==================================================
                            SizedBox(
                              width: dialogWidth * 0.30,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen
                                      .withValues(alpha: 0.055),
                                  border: Border(
                                    right: BorderSide(
                                      color: AppTheme.primaryGreen
                                          .withValues(alpha: 0.10),
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  28,
                                  30,
                                  20,
                                  24,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SELECT DATE',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.7,
                                        color:
                                            AppTheme.primaryGreen,
                                      ),
                                    ),

                                    const SizedBox(height: 26),

                                    Text(
                                      selectedDateText
                                          .split(', ')
                                          .first,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        height: 1.08,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            AppTheme.textPrimary,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      '${selectedDate.day} ${DateFormat('MMMM').format(selectedDate)}',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        height: 1.08,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            AppTheme.textPrimary,
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    Text(
                                      selectedYearText,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            AppTheme.primaryGreen,
                                      ),
                                    ),

                                    const Spacer(),

                                    // Decorative date/edit icon matching
                                    // the reference calendar.
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen
                                            .withValues(alpha: 0.09),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.edit_calendar_rounded,
                                        size: 25,
                                        color:
                                            AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ==================================================
                            // RIGHT CALENDAR PANEL
                            // ==================================================
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  22,
                                  24,
                                  0,
                                ),
                                child: Column(
                                  children: [
                                    // Month + navigation
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Text(
                                                monthName,
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: AppTheme
                                                      .textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
                                                size: 20,
                                                color: AppTheme
                                                    .primaryGreen,
                                              ),
                                            ],
                                          ),
                                        ),

                                        _calendarNavButton(
                                          icon: Icons
                                              .chevron_left_rounded,
                                          enabled: canGoPrevious,
                                          large: true,
                                          onTap: () {
                                            if (!canGoPrevious) return;

                                            setDialogState(() {
                                              visibleMonth = DateTime(
                                                visibleMonth.year,
                                                visibleMonth.month - 1,
                                                1,
                                              );
                                            });
                                          },
                                        ),

                                        const SizedBox(width: 12),

                                        _calendarNavButton(
                                          icon: Icons
                                              .chevron_right_rounded,
                                          enabled: canGoNext,
                                          large: true,
                                          onTap: () {
                                            if (!canGoNext) return;

                                            setDialogState(() {
                                              visibleMonth = DateTime(
                                                visibleMonth.year,
                                                visibleMonth.month + 1,
                                                1,
                                              );
                                            });
                                          },
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 18),

                                    // Weekday labels
                                    Row(
                                      children: weekdayLabels
                                          .map(
                                            (day) => Expanded(
                                              child: Center(
                                                child: Text(
                                                  day,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w500,
                                                    color: AppTheme
                                                        .textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),

                                    const SizedBox(height: 8),

                                    // Calendar grid
                                    Expanded(
                                      child: GridView.builder(
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        padding: EdgeInsets.zero,
                                        itemCount: totalCells,
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 7,
                                          childAspectRatio: 1.45,
                                          mainAxisSpacing: 2,
                                          crossAxisSpacing: 0,
                                        ),
                                        itemBuilder:
                                            (context, index) {
                                          final dayNumber =
                                              index -
                                                  firstWeekday +
                                                  1;

                                          if (dayNumber < 1 ||
                                              dayNumber >
                                                  daysInMonth) {
                                            // Show adjacent month dates
                                            // in a muted style like the
                                            // reference image.
                                            final previousMonthDays =
                                                firstWeekday -
                                                index;

                                            if (index <
                                                firstWeekday) {
                                              final previousMonth =
                                                  DateTime(
                                                visibleMonth.year,
                                                visibleMonth.month,
                                                0,
                                              );

                                              final adjacentDay =
                                                  previousMonth.day -
                                                  previousMonthDays +
                                                  1;

                                              return _buildAdjacentDay(
                                                adjacentDay,
                                              );
                                            }

                                            final nextDay =
                                                dayNumber -
                                                    daysInMonth;

                                            return _buildAdjacentDay(
                                              nextDay,
                                            );
                                          }

                                          final date = DateTime(
                                            visibleMonth.year,
                                            visibleMonth.month,
                                            dayNumber,
                                          );

                                          final isSelected =
                                              selectedDate.year ==
                                                      date.year &&
                                                  selectedDate.month ==
                                                      date.month &&
                                                  selectedDate.day ==
                                                      date.day;

                                          final isToday =
                                              today.year ==
                                                      date.year &&
                                                  today.month ==
                                                      date.month &&
                                                  today.day ==
                                                      date.day;

                                          final disabled =
                                              date.isBefore(
                                                    firstDate,
                                                  ) ||
                                                  date.isAfter(
                                                    lastDate,
                                                  );

                                          return Center(
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: disabled
                                                    ? null
                                                    : () {
                                                        setDialogState(
                                                          () {
                                                            selectedDate =
                                                                date;
                                                          },
                                                        );
                                                      },
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  30,
                                                ),
                                                child:
                                                    AnimatedContainer(
                                                  duration:
                                                      const Duration(
                                                    milliseconds: 150,
                                                  ),
                                                  width: 38,
                                                  height: 38,
                                                  alignment:
                                                      Alignment.center,
                                                  decoration:
                                                      BoxDecoration(
                                                    shape:
                                                        BoxShape.circle,
                                                    color: isSelected
                                                        ? AppTheme
                                                            .primaryGreen
                                                        : Colors
                                                            .transparent,
                                                    border: isToday &&
                                                            !isSelected
                                                        ? Border.all(
                                                            color: AppTheme
                                                                .primaryGreen,
                                                            width: 1.5,
                                                          )
                                                        : null,
                                                    boxShadow:
                                                        isSelected
                                                            ? [
                                                                BoxShadow(
                                                                  color: AppTheme
                                                                      .primaryGreen
                                                                      .withValues(
                                                                    alpha:
                                                                        0.20,
                                                                  ),
                                                                  blurRadius:
                                                                      0,
                                                                  spreadRadius:
                                                                      7,
                                                                ),
                                                              ]
                                                            : null,
                                                  ),
                                                  child: Text(
                                                    '$dayNumber',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          isSelected
                                                              ? FontWeight
                                                                  .w700
                                                              : FontWeight
                                                                  .w500,
                                                      color: disabled
                                                          ? AppTheme
                                                              .textMuted
                                                          : isSelected
                                                              ? Colors
                                                                  .white
                                                              : AppTheme
                                                                  .textPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    // Divider + footer
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: AppTheme.cardBorder,
                                          ),
                                        ),
                                      ),
                                      padding:
                                          const EdgeInsets.fromLTRB(
                                        0,
                                        18,
                                        0,
                                        26,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(
                                              dialogContext,
                                            ).pop(),
                                            style:
                                                TextButton.styleFrom(
                                              foregroundColor:
                                                  AppTheme.primaryGreen,
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal: 22,
                                                vertical: 14,
                                              ),
                                            ),
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 18),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.of(
                                              dialogContext,
                                            ).pop(
                                              DateUtils.dateOnly(
                                                selectedDate,
                                              ),
                                            ),
                                            style:
                                                FilledButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.primaryGreen,
                                              foregroundColor:
                                                  Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal: 34,
                                                vertical: 15,
                                              ),
                                              shape:
                                                  RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                  28,
                                                ),
                                              ),
                                            ),
                                            child: const Text(
                                              'OK',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _expiryDate = DateUtils.dateOnly(picked);
      });
    }
  }

  // ============================================================
  // COMPACT CALENDAR FOR SMALLER SCREENS
  // ============================================================

  Widget _buildCompactCalendarContent({
    required BuildContext context,
    required BuildContext dialogContext,
    required DateTime selectedDate,
    required String selectedDateText,
    required String selectedYearText,
    required DateTime visibleMonth,
    required String monthName,
    required int firstWeekday,
    required int daysInMonth,
    required int totalCells,
    required List<String> weekdayLabels,
    required DateTime today,
    required DateTime firstDate,
    required DateTime lastDate,
    required bool canGoPrevious,
    required bool canGoNext,
    required StateSetter setDialogState,
    required ValueChanged<DateTime> onSelectedDate,
    required ValueChanged<DateTime> onVisibleMonthChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen
                      .withValues(alpha: 0.09),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: AppTheme.primaryGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECT DATE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$selectedDateText $selectedYearText',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: Text(
                  monthName,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              _calendarNavButton(
                icon: Icons.chevron_left_rounded,
                enabled: canGoPrevious,
                onTap: () {
                  if (!canGoPrevious) return;
                  onVisibleMonthChanged(
                    DateTime(
                      visibleMonth.year,
                      visibleMonth.month - 1,
                      1,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _calendarNavButton(
                icon: Icons.chevron_right_rounded,
                enabled: canGoNext,
                onTap: () {
                  if (!canGoNext) return;
                  onVisibleMonthChanged(
                    DateTime(
                      visibleMonth.year,
                      visibleMonth.month + 1,
                      1,
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: weekdayLabels
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day.substring(0, 1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: GridView.builder(
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final dayNumber =
                    index - firstWeekday + 1;

                if (dayNumber < 1 ||
                    dayNumber > daysInMonth) {
                  return const SizedBox();
                }

                final date = DateTime(
                  visibleMonth.year,
                  visibleMonth.month,
                  dayNumber,
                );

                final isSelected =
                    selectedDate.year == date.year &&
                        selectedDate.month ==
                            date.month &&
                        selectedDate.day == date.day;

                final isToday =
                    today.year == date.year &&
                        today.month == date.month &&
                        today.day == date.day;

                final disabled =
                    date.isBefore(firstDate) ||
                        date.isAfter(lastDate);

                return Center(
                  child: InkWell(
                    onTap: disabled
                        ? null
                        : () => onSelectedDate(date),
                    borderRadius:
                        BorderRadius.circular(30),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : Colors.transparent,
                        border: isToday && !isSelected
                            ? Border.all(
                                color:
                                    AppTheme.primaryGreen,
                              )
                            : null,
                      ),
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: disabled
                              ? AppTheme.textMuted
                              : isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(
                  DateUtils.dateOnly(selectedDate),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdjacentDay(int day) {
    return Center(
      child: Text(
        '$day',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.textMuted.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  Widget _calendarNavButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    bool large = false,
  }) {
    final size = large ? 52.0 : 40.0;

    return Material(
      color: enabled
          ? AppTheme.primaryGreen.withValues(alpha: 0.07)
          : Colors.grey.withValues(alpha: 0.05),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: large ? 30 : 22,
            color: enabled
                ? AppTheme.textPrimary
                : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GEMINI EXTRACTION
  // ============================================================

  Future<void> _triggerGeminiAIExtraction(
    String source,
  ) async {
    if (_selectedImageBytes == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select an image first.',
          ),
          backgroundColor: AppTheme.expiredRed,
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      _isExtracting = true;
      _isAnalyzing = true;
      _scanningStatusText =
          'Extracting product information with Gemini AI...';
    });

    try {
      final extracted =
          await GeminiExtractionService.extractProductFromImage(
        _selectedImageBytes!,
        mimeType: _selectedImageMimeType,
      );

      if (!mounted) return;

      if (extracted == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not extract product information from the image.',
            ),
            backgroundColor: AppTheme.expiredRed,
            behavior: SnackBarBehavior.floating,
          ),
        );

        return;
      }

      setState(() {
        // ========================================================
        // IMPORTANT FIX
        // ========================================================
        // Gemini has successfully extracted the product data.
        // Automatically switch from Upload Image to the
        // Manual Data form so the user can immediately review
        // and edit the extracted information.
        _selectedMethod =
            ProductInputMethod.manual;

        // --------------------------------------------------------
        // Product Name
        // --------------------------------------------------------

        if (extracted.productName.trim().isNotEmpty) {
          _nameController.text =
              extracted.productName.trim();
        }

        // --------------------------------------------------------
        // Brand
        // --------------------------------------------------------

        if (extracted.brand.trim().isNotEmpty) {
          _brandController.text =
              extracted.brand.trim();
        }

        // --------------------------------------------------------
        // Category
        // --------------------------------------------------------

        final mappedCategory =
            _mapGeminiCategory(
          extracted.category,
        );

        if (mappedCategory != null) {
          _selectedCategory = mappedCategory;
        }

        // --------------------------------------------------------
        // Quantity / Size
        // --------------------------------------------------------

        if (extracted.quantitySize.trim().isNotEmpty) {
          _quantityController.text =
              extracted.quantitySize.trim();
        }

        // --------------------------------------------------------
        // Original Price
        // --------------------------------------------------------

        if (extracted.originalPrice > 0) {
          _priceController.text =
              extracted.originalPrice
                  .toStringAsFixed(2);
        }

        // --------------------------------------------------------
        // Expiry Date
        // Gemini returns YYYY-MM-DD
        // --------------------------------------------------------

        if (extracted.expiryDate.trim().isNotEmpty) {
          final parsedDate =
              DateTime.tryParse(
            extracted.expiryDate.trim(),
          );

          if (parsedDate != null) {
            _expiryDate = DateUtils.dateOnly(parsedDate);
          }
        }

        // --------------------------------------------------------
        // Batch Number
        // --------------------------------------------------------

        if (extracted.batchNumber.trim().isNotEmpty) {
          _batchNumberController.text =
              extracted.batchNumber.trim();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Details extracted successfully. Please review and save.',
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gemini extraction failed: $e',
          ),
          backgroundColor: AppTheme.expiredRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExtracting = false;
          _isAnalyzing = false;
          _scanningStatusText = null;
        });
      }
    }
  }

  // ============================================================
  // GEMINI CATEGORY MAPPING
  // ============================================================

  String? _mapGeminiCategory(String category) {
    final value = category.trim().toLowerCase();

    if (value.isEmpty) {
      return null;
    }

    if (value == 'dairy' ||
        value == 'dairy & eggs' ||
        value == 'dairy and eggs') {
      return 'Dairy';
    }

    if (value == 'bakery' ||
        value == 'bakery & bread' ||
        value == 'bakery and bread') {
      return 'Bakery';
    }

    if (value == 'beverages') {
      return 'Beverages';
    }

    if (value == 'snacks' ||
        value == 'snacks & confectionery' ||
        value == 'snacks and confectionery') {
      return 'Snacks';
    }

    if (value == 'produce' ||
        value == 'fruits & vegetables' ||
        value == 'fruits and vegetables') {
      return 'Produce';
    }

    if (value == 'pulses') {
      return 'Pulses';
    }

    if (value == 'spices') {
      return 'Spices';
    }

    if (value == 'pantry' ||
        value == 'pantry & staples' ||
        value == 'pantry and staples') {
      return 'Pantry';
    }

    if (value == 'personal care') {
      return 'Personal Care';
    }

    if (value == 'household' ||
        value == 'household items') {
      return 'Household';
    }

    if (value == 'other' ||
        value == 'others') {
      return 'Others';
    }

    return null;
  }

  // ============================================================
  // MISSING FIELDS PROMPT
  // ============================================================

  void _showMissingFieldsPrompt(
    List<String> missingFields,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppTheme.warningOrange,
            ),
            SizedBox(width: 8),
            Text('Complete Missing Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Gemini extracted most product details, but couldn\'t confidently identify the following required fields:',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ...missingFields.map(
              (field) => Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 4.0,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppTheme.warningOrange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      field,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please complete these fields in the form below before saving.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppTheme.primaryGreen,
            ),
            onPressed: () =>
                Navigator.of(ctx).pop(),
            child: const Text(
              'OK, Fill Manually',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBMIT FORM
  // ============================================================

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required fields before saving.',
          ),
          backgroundColor: AppTheme.expiredRed,
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select an Expiry Date for the product.',
          ),
          backgroundColor: AppTheme.expiredRed,
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // Parse quantity
    // ----------------------------------------------------------

    int qty = 1;

    final qtyMatches = RegExp(
      r'\d+',
    ).firstMatch(
      _quantityController.text,
    );

    if (qtyMatches != null) {
      qty = int.tryParse(
            qtyMatches.group(0)!,
          ) ??
          1;
    }

    // ----------------------------------------------------------
    // Parse price safely
    // ----------------------------------------------------------

    final price = double.tryParse(
      _priceController.text.trim(),
    );

    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid price.',
          ),
          backgroundColor: AppTheme.expiredRed,
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // Create ProductModel
    // ----------------------------------------------------------

    final newProduct = ProductModel(
      id: '',
      name: _nameController.text.trim(),
      category: _selectedCategory,
      expiryDate: _expiryDate!,
      originalPrice: price,
      quantity: qty,
      brand: _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      batchNumber:
          _batchNumberController.text.trim(),
    );

    // ----------------------------------------------------------
    // Save through ProductProvider
    // ----------------------------------------------------------

    final productProvider =
        Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    final success =
        await productProvider.addProduct(
      newProduct,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully added "${newProduct.name}" to inventory!',
          ),
          backgroundColor:
              AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (widget.onItemAdded != null) {
        widget.onItemAdded!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            productProvider.errorMessage ??
                'Failed to save product.',
          ),
          backgroundColor: AppTheme.expiredRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final isDesktop = size.width > 900;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal:
            isDesktop ? 32.0 : 16.0,
        vertical: 24.0,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Item',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Add a new product to your inventory',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          _buildMethodSelector(
            isDesktop,
          ),

          const SizedBox(height: 28),

          if (_isAnalyzing)
            _buildAnalyzingOverlay()
          else if (
              _selectedMethod ==
              ProductInputMethod.upload
          )
            _buildUploadView(isDesktop)
          else
            Form(
              key: _formKey,
              child: isDesktop
                  ? _buildDesktopFormLayout()
                  : _buildMobileFormLayout(),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // METHOD SELECTOR
  // ============================================================

  Widget _buildMethodSelector(
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a method',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildMethodCard(
                method:
                    ProductInputMethod.manual,
                icon: Icons.edit_outlined,
                activeIcon: Icons.edit,
                title: 'Add Manually',
                subtitle:
                    'Enter product details manually',
                color:
                    const Color(0xFF10B981),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildMethodCard(
                method:
                    ProductInputMethod.upload,
                icon:
                    Icons.photo_camera_outlined,
                activeIcon:
                    Icons.photo_camera,
                title: 'Upload Image',
                subtitle:
                    'Upload image of product to extract',
                color:
                    const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMethodCard({
    required ProductInputMethod method,
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected =
        _selectedMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.06)
              : Colors.white,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : AppTheme.cardBorder,
            width:
                isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        color.withOpacity(0.12),
                    blurRadius: 10,
                    offset:
                        const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.02),
                    blurRadius: 6,
                    offset:
                        const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected
                    ? activeIcon
                    : icon,
                color: color,
                size: 24,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.bold,
                color: isSelected
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? AppTheme.textSecondary
                    : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ANALYZING OVERLAY
  // ============================================================

  Widget _buildAnalyzingOverlay() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGreen
              .withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: AppTheme.primaryGreen,
          ),

          const SizedBox(height: 20),

          Text(
            _scanningStatusText ??
                'Extracting product information...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppTheme.primaryGreen,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Gemini AI is parsing product name, brand, prices, and expiry label variations...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color:
                  AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UPLOAD VIEW
  // ============================================================

  Widget _buildUploadView(
    bool isDesktop,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cardBorder,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap:
                () => _pickAndExtractImage(),
            borderRadius:
                BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: AppTheme
                    .backgroundMint
                    .withOpacity(0.5),
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme
                      .primaryGreen
                      .withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.all(16),
                    decoration:
                        const BoxDecoration(
                      color: Colors.white,
                      shape:
                          BoxShape.circle,
                    ),
                    child:
                        const Icon(
                      Icons
                          .cloud_upload_outlined,
                      color: AppTheme
                          .primaryGreen,
                      size: 36,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  const Text(
                    'Click to upload product image or select sample',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w600,
                      color: AppTheme
                          .textPrimary,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  const Text(
                    'Supports JPG, PNG • Gemini Developer API will extract details automatically',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (_uploadedImages
              .isNotEmpty) ...[
            Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                'Selected Image (${_uploadedImages.length}):',
                style:
                    const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppTheme.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children:
                  _uploadedImages.map(
                (img) => Stack(
                  children: [
                    Container(
                      margin:
                          const EdgeInsets
                              .only(
                        right: 12,
                      ),
                      width: 90,
                      height: 90,
                      decoration:
                          BoxDecoration(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                        border:
                            Border.all(
                          color: AppTheme
                              .primaryGreen,
                          width: 2,
                        ),
                        image:
                            const DecorationImage(
                          image: AssetImage(
                            'assets/images/milk.png',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    Positioned(
                      top: 4,
                      right: 16,
                      child:
                          GestureDetector(
                        onTap: () {
                          setState(() {
                            _uploadedImages
                                .remove(
                              img,
                            );

                            if (_uploadedImages
                                .isEmpty) {
                              _selectedImageBytes =
                                  null;
                            }
                          });
                        },
                        child: Container(
                          padding:
                              const EdgeInsets
                                  .all(2),
                          decoration:
                              const BoxDecoration(
                            color:
                                Colors.black54,
                            shape:
                                BoxShape
                                    .circle,
                          ),
                          child:
                              const Icon(
                            Icons.close,
                            size: 14,
                            color:
                                Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).toList(),
            ),

            const SizedBox(height: 20),
          ],

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                style:
                    OutlinedButton.styleFrom(
                  minimumSize:
                      const Size(
                    160,
                    48,
                  ),
                ),
                onPressed:
                    () => _pickAndExtractImage(),
                icon:
                    const Icon(
                  Icons
                      .add_photo_alternate_outlined,
                  color: AppTheme
                      .primaryGreen,
                ),
                label:
                    const Text(
                  'Choose Image',
                ),
              ),

              const SizedBox(width: 16),

              ElevatedButton.icon(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppTheme
                          .primaryGreen,
                  minimumSize:
                      const Size(
                    200,
                    48,
                  ),
                ),
                onPressed:
                    () => _triggerGeminiAIExtraction(
                  'Uploaded Image',
                ),
                icon:
                    const Icon(
                  Icons.auto_awesome,
                  color:
                      Colors.white,
                ),
                label:
                    const Text(
                  'Extract with Gemini AI',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickAndExtractImage() async {
    showModalBottomSheet(
      context: context,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return Container(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload Product Image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Choose an option to pick image from your device for Gemini AI extraction:',
                style: TextStyle(
                  fontSize: 13,
                  color:
                      AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // GALLERY
              // ------------------------------------------------

              ListTile(
                leading: Container(
                  padding:
                      const EdgeInsets
                          .all(8),
                  decoration:
                      BoxDecoration(
                    color: AppTheme
                        .primaryGreen
                        .withOpacity(0.1),
                    shape:
                        BoxShape.circle,
                  ),
                  child:
                      const Icon(
                    Icons
                        .photo_library_outlined,
                    color: AppTheme
                        .primaryGreen,
                  ),
                ),
                title: const Text(
                  'Choose from Gallery / Files',
                ),
                subtitle: const Text(
                  'Select product image from device storage',
                ),
                onTap: () async {
                  Navigator.pop(ctx);

                  final picker =
                      ImagePicker();

                  final XFile? file =
                      await picker.pickImage(
                    source:
                        ImageSource.gallery,
                  );

                  if (file == null) {
                    return;
                  }

                  try {
                    final bytes =
                        await file
                            .readAsBytes();

                    final extension =
                        file.name
                            .split('.')
                            .last
                            .toLowerCase();

                    String mimeType =
                        'image/jpeg';

                    if (extension ==
                        'png') {
                      mimeType =
                          'image/png';
                    } else if (extension ==
                        'webp') {
                      mimeType =
                          'image/webp';
                    } else if (extension ==
                            'jpg' ||
                        extension ==
                            'jpeg') {
                      mimeType =
                          'image/jpeg';
                    }

                    setState(() {
                      _selectedImageBytes =
                          bytes;

                      _selectedImageMimeType =
                          mimeType;

                      final imageName =
                          file.name
                                  .isNotEmpty
                              ? file.name
                              : 'Selected Gallery Image';

                      if (!_uploadedImages
                          .contains(
                        imageName,
                      )) {
                        _uploadedImages
                            .add(
                          imageName,
                        );
                      }
                    });

                    await _triggerGeminiAIExtraction(
                      file.name
                              .isNotEmpty
                          ? file.name
                          : 'Selected Gallery Image',
                    );
                  } catch (e) {
                    if (!mounted) {
                      return;
                    }

                    ScaffoldMessenger
                            .of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          'Unable to read image: $e',
                        ),
                        backgroundColor:
                            AppTheme
                                .expiredRed,
                      ),
                    );
                  }
                },
              ),

              const Divider(),

              // ------------------------------------------------
              // CAMERA
              // ------------------------------------------------

              ListTile(
                leading: Container(
                  padding:
                      const EdgeInsets
                          .all(8),
                  decoration:
                      BoxDecoration(
                    color: AppTheme
                        .accentGreen
                        .withOpacity(0.1),
                    shape:
                        BoxShape.circle,
                  ),
                  child:
                      const Icon(
                    Icons
                        .camera_alt_outlined,
                    color: AppTheme
                        .accentGreen,
                  ),
                ),
                title: const Text(
                  'Take Photo with Camera',
                ),
                subtitle: const Text(
                  'Capture product packaging immediately',
                ),
                onTap: () async {
                  Navigator.pop(ctx);

                  final picker =
                      ImagePicker();

                  final XFile? file =
                      await picker.pickImage(
                    source:
                        ImageSource.camera,
                  );

                  if (file == null) {
                    return;
                  }

                  try {
                    final bytes =
                        await file
                            .readAsBytes();

                    setState(() {
                      _selectedImageBytes =
                          bytes;

                      _selectedImageMimeType =
                          'image/jpeg';

                      final imageName =
                          file.name
                                  .isNotEmpty
                              ? file.name
                              : 'Camera Photo';

                      if (!_uploadedImages
                          .contains(
                        imageName,
                      )) {
                        _uploadedImages
                            .add(
                          imageName,
                        );
                      }
                    });

                    await _triggerGeminiAIExtraction(
                      file.name
                              .isNotEmpty
                          ? file.name
                          : 'Camera Photo',
                    );
                  } catch (e) {
                    if (!mounted) {
                      return;
                    }

                    ScaffoldMessenger
                            .of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          'Unable to read camera image: $e',
                        ),
                        backgroundColor:
                            AppTheme
                                .expiredRed,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // DESKTOP FORM
  // ============================================================

  Widget _buildDesktopFormLayout() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Item Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          AppTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  _buildTextField(
                    label:
                        'Product Name *',
                    controller:
                        _nameController,
                    hint:
                        'e.g. Amul Milk',
                    validator: (v) =>
                        v == null ||
                                v.trim()
                                    .isEmpty
                            ? 'Product name is required'
                            : null,
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  _buildCategoryDropdown(),

                  const SizedBox(
                    height: 16,
                  ),

                  _buildTextField(
                    label:
                        'Brand (Optional)',
                    controller:
                        _brandController,
                    hint:
                        'e.g. Amul',
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  _buildTextField(
                    label:
                        'Batch Number *',
                    controller:
                        _batchNumberController,
                    hint:
                        'e.g. B-99402',
                    validator: (v) =>
                        v == null ||
                                v.trim()
                                    .isEmpty
                            ? 'Batch number is required'
                            : null,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 24),

            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 38,
                  ),

                  _buildTextField(
                    label:
                        'Quantity / Size *',
                    controller:
                        _quantityController,
                    hint:
                        'e.g. 1 L, 500 g, 1 pack',
                    validator: (v) =>
                        v == null ||
                                v.trim()
                                    .isEmpty
                            ? 'Quantity is required'
                            : null,
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  _buildTextField(
                    label:
                        'Original Price (₹) *',
                    controller:
                        _priceController,
                    keyboardType:
                        TextInputType
                            .number,
                    hint:
                        'e.g. 60',
                    onChanged: (_) =>
                        setState(() {}),
                    validator: (v) {
                      if (v == null ||
                          v.trim()
                              .isEmpty) {
                        return 'Price is required';
                      }

                      if (double.tryParse(
                              v) ==
                          null) {
                        return 'Enter a valid price number';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  _buildDatePickerTile(
                    label:
                        'Expiry Date *',
                    date: _expiryDate,
                    onTap: () =>
                        _selectDate(
                      context,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  _buildSuggestedSellingPriceCard(),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        _buildImagesSection(),

        const SizedBox(height: 32),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.end,
          children: [
            OutlinedButton(
              style:
                  OutlinedButton.styleFrom(
                minimumSize:
                    const Size(
                  120,
                  48,
                ),
              ),
              onPressed: () {
                if (Navigator.of(
                  context,
                ).canPop()) {
                  Navigator.of(
                    context,
                  ).pop();
                }
              },
              child:
                  const Text('Cancel'),
            ),

            const SizedBox(width: 16),

            ElevatedButton.icon(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppTheme
                        .primaryGreen,
                minimumSize:
                    const Size(
                  160,
                  48,
                ),
              ),
              onPressed:
                  _submitForm,
              icon:
                  const Icon(
                Icons.archive_outlined,
                color:
                    Colors.white,
              ),
              label:
                  const Text(
                'Save Item',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE FORM
  // ============================================================

  Widget _buildMobileFormLayout() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Item Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.bold,
            color:
                AppTheme.textPrimary,
          ),
        ),

        const SizedBox(height: 16),

        _buildTextField(
          label:
              'Product Name *',
          controller:
              _nameController,
          hint:
              'e.g. Amul Milk',
          validator: (v) =>
              v == null ||
                      v.trim()
                          .isEmpty
                  ? 'Product name is required'
                  : null,
        ),

        const SizedBox(height: 16),

        _buildCategoryDropdown(),

        const SizedBox(height: 16),

        _buildTextField(
          label:
              'Brand (Optional)',
          controller:
              _brandController,
          hint:
              'e.g. Amul',
        ),

        const SizedBox(height: 16),

        _buildTextField(
          label:
              'Batch Number *',
          controller:
              _batchNumberController,
          hint:
              'e.g. B-99402',
          validator: (v) =>
              v == null ||
                      v.trim()
                          .isEmpty
                  ? 'Batch number is required'
                  : null,
        ),

        const SizedBox(height: 16),

        _buildTextField(
          label:
              'Quantity / Size *',
          controller:
              _quantityController,
          hint:
              'e.g. 1 L, 500 g, 1 pack',
          validator: (v) =>
              v == null ||
                      v.trim()
                          .isEmpty
                  ? 'Quantity is required'
                  : null,
        ),

        const SizedBox(height: 16),

        _buildTextField(
          label:
              'Original Price (₹) *',
          controller:
              _priceController,
          keyboardType:
              TextInputType.number,
          hint:
              'e.g. 60',
          onChanged: (_) =>
              setState(() {}),
          validator: (v) {
            if (v == null ||
                v.trim().isEmpty) {
              return 'Price is required';
            }

            if (double.tryParse(v) ==
                null) {
              return 'Enter a valid price number';
            }

            return null;
          },
        ),

        const SizedBox(height: 16),

        _buildDatePickerTile(
          label:
              'Expiry Date *',
          date: _expiryDate,
          onTap: () =>
              _selectDate(context),
        ),

        const SizedBox(height: 16),

        _buildSuggestedSellingPriceCard(),

        const SizedBox(height: 20),

        _buildImagesSection(),

        const SizedBox(height: 28),

        ElevatedButton.icon(
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                AppTheme
                    .primaryGreen,
            minimumSize:
                const Size(
              double.infinity,
              50,
            ),
          ),
          onPressed:
              _submitForm,
          icon:
              const Icon(
            Icons.archive_outlined,
            color:
                Colors.white,
          ),
          label:
              const Text(
            'Save Item',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required String label,
    required TextEditingController
        controller,
    required String hint,
    TextInputType keyboardType =
        TextInputType.text,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>?
        validator,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
            color:
                AppTheme.textPrimary,
          ),
        ),

        const SizedBox(height: 6),

        TextFormField(
          controller: controller,
          keyboardType:
              keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
          ),
          decoration:
              InputDecoration(
            hintText: hint,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CATEGORY DROPDOWN
  // ============================================================

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Category *',
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
            color:
                AppTheme.textPrimary,
          ),
        ),

        const SizedBox(height: 6),

        DropdownButtonFormField<String>(
          value: _selectedCategory,
          items: _categories
              .map(
                (cat) =>
                    DropdownMenuItem(
                  value: cat,
                  child: Text(
                    cat,
                    style:
                        const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedCategory =
                    val;
              });
            }
          },
          decoration:
              const InputDecoration(
            contentPadding:
                EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DATE PICKER TILE
  // ============================================================

  Widget _buildDatePickerTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),

        const SizedBox(height: 6),

        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: date != null
                      ? AppTheme.primaryGreen.withValues(alpha: 0.35)
                      : AppTheme.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      date == null
                          ? 'Select Date'
                          : DateFormat(
                              'dd MMM yyyy',
                            ).format(date),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: date == null
                            ? FontWeight.w400
                            : FontWeight.w600,
                        color: date == null
                            ? AppTheme.textMuted
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),

                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUGGESTED SELLING PRICE CARD
  // ============================================================

  Widget _buildSuggestedSellingPriceCard() {
    final suggested =
        _suggestedSellingPrice;

    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF0FDF4),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.all(8),
            decoration:
                const BoxDecoration(
              color:
                  Color(0xFFDCFCE7),
              shape:
                  BoxShape.circle,
            ),
            child: const Icon(
              Icons.currency_rupee,
              color:
                  AppTheme.primaryGreen,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  'Suggested Selling Price',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.bold,
                    color: AppTheme
                        .primaryGreen,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  'Calculated automatically based on days until expiry',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors
                        .green
                        .shade700,
                  ),
                ),
              ],
            ),
          ),

          Text(
            suggested != null
                ? '₹ ${suggested.toStringAsFixed(1)}'
                : '₹ --',
            style: const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IMAGES SECTION
  // ============================================================

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Images (Optional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
            color:
                AppTheme.textPrimary,
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            InkWell(
              onTap: () =>
                  _triggerGeminiAIExtraction(
                'Uploaded Image',
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              child: Container(
                width: 90,
                height: 90,
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  border: Border.all(
                    color:
                        AppTheme.cardBorder,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Icon(
                      Icons
                          .add_a_photo_outlined,
                      color: AppTheme
                          .primaryGreen,
                      size: 24,
                    ),

                    SizedBox(height: 4),

                    Text(
                      'Add more',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme
                            .textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            ..._uploadedImages.map(
              (img) => Stack(
                children: [
                  Container(
                    margin:
                        const EdgeInsets
                            .only(
                      right: 12,
                    ),
                    width: 90,
                    height: 90,
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                      image:
                          const DecorationImage(
                        image: AssetImage(
                          'assets/images/milk.png',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  Positioned(
                    top: 4,
                    right: 16,
                    child:
                        GestureDetector(
                      onTap: () {
                        setState(() {
                          _uploadedImages
                              .remove(
                            img,
                          );

                          if (_uploadedImages
                              .isEmpty) {
                            _selectedImageBytes =
                                null;
                          }
                        });
                      },
                      child: Container(
                        padding:
                            const EdgeInsets
                                .all(2),
                        decoration:
                            const BoxDecoration(
                          color:
                              Colors.black54,
                          shape:
                              BoxShape.circle,
                        ),
                        child:
                            const Icon(
                          Icons.close,
                          size: 14,
                          color:
                              Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}