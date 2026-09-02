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

  const AddProductScreen({super.key, this.onItemAdded});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  ProductInputMethod _selectedMethod = ProductInputMethod.manual;

  // Form Field Controllers
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _batchNumberController = TextEditingController();

  String _selectedCategory = 'Dairy';
  DateTime? _expiryDate;
  final List<String> _uploadedImages = [];

  bool _isAnalyzing = false;
  String? _scanningStatusText;

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
    'Others'
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

  // Calculate dynamic suggested selling price card details
  double? get _suggestedSellingPrice {
    final priceStr = _priceController.text.trim();
    if (priceStr.isEmpty || _expiryDate == null) return null;
    final price = double.tryParse(priceStr);
    if (price == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(_expiryDate!.year, _expiryDate!.month, _expiryDate!.day);
    final daysRemaining = expiry.difference(today).inDays;

    if (daysRemaining < 0) return 0.0;
    if (daysRemaining <= 3) return price * 0.75;
    if (daysRemaining <= 5) return price * 0.90;
    if (daysRemaining <= 7) return price * 0.95;
    return price;
  }

  Future<void> _selectDate(BuildContext context) async {
    final initialDate = _expiryDate ?? DateTime.now().add(const Duration(days: 14));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  // Run Gemini Extraction logic
  Future<void> _triggerGeminiAIExtraction(String source) async {
    setState(() {
      _isAnalyzing = true;
      _scanningStatusText = 'Analyzing $source with Gemini AI...';
    });

    try {
      final extracted = await GeminiExtractionService.extractProductFromImage(source);

      if (!mounted) return;

      setState(() {
        if (extracted.productName != null) _nameController.text = extracted.productName!;
        if (extracted.brand != null) _brandController.text = extracted.brand!;
        if (extracted.category != null && _categories.contains(extracted.category)) {
          _selectedCategory = extracted.category!;
        }
        if (extracted.quantitySize != null) _quantityController.text = extracted.quantitySize!;
        if (extracted.price != null) _priceController.text = extracted.price.toString();
        if (extracted.expiryDate != null) _expiryDate = extracted.expiryDate;
        if (extracted.batchNumber != null) _batchNumberController.text = extracted.batchNumber!;

        // Add a demo mock image if non uploaded
        if (_uploadedImages.isEmpty) {
          _uploadedImages.add('assets/images/milk.png');
        }

        _isAnalyzing = false;
        _selectedMethod = ProductInputMethod.manual; // Switch back to form preview
      });

      final missing = extracted.missingRequiredFields;
      if (missing.isNotEmpty) {
        _showMissingFieldsPrompt(missing);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Product details extracted successfully via Gemini AI!'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Extraction failed: $e'),
          backgroundColor: AppTheme.expiredRed,
        ),
      );
    }
  }

  void _showMissingFieldsPrompt(List<String> missingFields) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppTheme.warningOrange),
            SizedBox(width: 8),
            Text('Complete Missing Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gemini extracted most product details, but couldn\'t confidently identify the following required fields:',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            ...missingFields.map((field) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.warningOrange),
                      const SizedBox(width: 8),
                      Text(field, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            const Text(
              'Please complete these fields in the form below before saving.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK, Fill Manually'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields before saving.'),
          backgroundColor: AppTheme.expiredRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an Expiry Date for the product.'),
          backgroundColor: AppTheme.expiredRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Parse quantity
    int qty = 1;
    final qtyMatches = RegExp(r'\d+').firstMatch(_quantityController.text);
    if (qtyMatches != null) {
      qty = int.tryParse(qtyMatches.group(0)!) ?? 1;
    }

    final newProduct = ProductModel(
      id: '',
      name: _nameController.text.trim(),
      category: _selectedCategory,
      expiryDate: _expiryDate!,
      originalPrice: double.parse(_priceController.text.trim()),
      quantity: qty,
      brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      batchNumber: _batchNumberController.text.trim(),
      images: List.from(_uploadedImages),
    );

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final success = await productProvider.addProduct(newProduct);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully added "${newProduct.name}" to inventory!'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (widget.onItemAdded != null) {
          widget.onItemAdded!();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32.0 : 16.0,
        vertical: 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // ── Method Selector Cards ──
          _buildMethodSelector(isDesktop),
          const SizedBox(height: 28),

          // Render Scanning / Analyzing State Overlay if active
          if (_isAnalyzing)
            _buildAnalyzingOverlay()
          else if (_selectedMethod == ProductInputMethod.upload)
            _buildUploadView(isDesktop)
          else
            // Main Form View
            Form(
              key: _formKey,
              child: isDesktop ? _buildDesktopFormLayout() : _buildMobileFormLayout(),
            ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                method: ProductInputMethod.manual,
                icon: Icons.edit_outlined,
                activeIcon: Icons.edit,
                title: 'Add Manually',
                subtitle: 'Enter product details manually',
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMethodCard(
                method: ProductInputMethod.upload,
                icon: Icons.photo_camera_outlined,
                activeIcon: Icons.photo_camera,
                title: 'Upload Image',
                subtitle: 'Upload image of product to extract',
                color: const Color(0xFF8B5CF6),
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
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMethod = method);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppTheme.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
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
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppTheme.textSecondary : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. Upload View Dropzone ──
  Widget _buildUploadView(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _pickAndExtractImage(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: AppTheme.backgroundMint.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_upload_outlined, color: AppTheme.primaryGreen, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Click to upload product image or select sample',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Supports JPG, PNG • Gemini Developer API will extract details automatically',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_uploadedImages.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Selected Image (${_uploadedImages.length}):',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ..._uploadedImages.map(
                  (img) => Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryGreen, width: 2),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/milk.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => setState(() => _uploadedImages.remove(img)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 48),
                ),
                onPressed: () => _pickAndExtractImage(),
                icon: const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primaryGreen),
                label: const Text('Choose Image'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  minimumSize: const Size(200, 48),
                ),
                onPressed: () => _triggerGeminiAIExtraction('Uploaded Image'),
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: const Text('Extract with Gemini AI'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _pickAndExtractImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Product Image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose an option to pick image from your device for Gemini AI extraction:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryGreen),
              ),
              title: const Text('Choose from Gallery / Files'),
              subtitle: const Text('Select product image from device storage'),
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final XFile? file = await picker.pickImage(source: ImageSource.gallery);
                if (file != null) {
                  _triggerGeminiAIExtraction(file.name.isNotEmpty ? file.name : 'Selected Gallery Image');
                } else {
                  _triggerGeminiAIExtraction('Selected Device Image');
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined, color: AppTheme.accentGreen),
              ),
              title: const Text('Take Photo with Camera'),
              subtitle: const Text('Capture product packaging immediately'),
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final XFile? file = await picker.pickImage(source: ImageSource.camera);
                if (file != null) {
                  _triggerGeminiAIExtraction(file.name.isNotEmpty ? file.name : 'Camera Photo');
                } else {
                  _triggerGeminiAIExtraction('Camera Photo');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingOverlay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryGreen),
          const SizedBox(height: 20),
          Text(
            _scanningStatusText ?? 'Extracting product information...',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gemini AI is parsing product name, brand, prices, and expiry label variations...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFormLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Item Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Product Name *',
                    controller: _nameController,
                    hint: 'e.g. Amul Milk',
                    validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Brand (Optional)',
                    controller: _brandController,
                    hint: 'e.g. Amul',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Batch Number *',
                    controller: _batchNumberController,
                    hint: 'e.g. B-99402',
                    validator: (v) => v == null || v.trim().isEmpty ? 'Batch number is required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 38),
                  _buildTextField(
                    label: 'Quantity / Size *',
                    controller: _quantityController,
                    hint: 'e.g. 1 L, 500 g, 1 pack',
                    validator: (v) => v == null || v.trim().isEmpty ? 'Quantity is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Original Price (₹) *',
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    hint: 'e.g. 60',
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Price is required';
                      if (double.tryParse(v) == null) return 'Enter a valid price number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDatePickerTile(
                    label: 'Expiry Date *',
                    date: _expiryDate,
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 16),
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
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(120, 48),
              ),
              onPressed: () {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                minimumSize: const Size(160, 48),
              ),
              onPressed: _submitForm,
              icon: const Icon(Icons.archive_outlined, color: Colors.white),
              label: const Text('Save Item'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileFormLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Product Name *',
          controller: _nameController,
          hint: 'e.g. Amul Milk',
          validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required' : null,
        ),
        const SizedBox(height: 16),
        _buildCategoryDropdown(),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Brand (Optional)',
          controller: _brandController,
          hint: 'e.g. Amul',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Batch Number *',
          controller: _batchNumberController,
          hint: 'e.g. B-99402',
          validator: (v) => v == null || v.trim().isEmpty ? 'Batch number is required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Quantity / Size *',
          controller: _quantityController,
          hint: 'e.g. 1 L, 500 g, 1 pack',
          validator: (v) => v == null || v.trim().isEmpty ? 'Quantity is required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Original Price (₹) *',
          controller: _priceController,
          keyboardType: TextInputType.number,
          hint: 'e.g. 60',
          onChanged: (_) => setState(() {}),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Price is required';
            if (double.tryParse(v) == null) return 'Enter a valid price number';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildDatePickerTile(
          label: 'Expiry Date *',
          date: _expiryDate,
          onTap: () => _selectDate(context),
        ),
        const SizedBox(height: 16),
        _buildSuggestedSellingPriceCard(),
        const SizedBox(height: 20),
        _buildImagesSection(),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: _submitForm,
          icon: const Icon(Icons.archive_outlined, color: Colors.white),
          label: const Text('Save Item'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category *',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          items: _categories
              .map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat, style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedCategory = val);
          },
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

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
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(date),
                  style: TextStyle(
                    fontSize: 14,
                    color: date == null ? AppTheme.textMuted : AppTheme.textPrimary,
                  ),
                ),
                const Icon(Icons.calendar_month_outlined, size: 20, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedSellingPriceCard() {
    final suggested = _suggestedSellingPrice;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.currency_rupee, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suggested Selling Price',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
                const SizedBox(height: 2),
                Text(
                  'Calculated automatically based on days until expiry',
                  style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                ),
              ],
            ),
          ),
          Text(
            suggested != null ? '₹ ${suggested.toStringAsFixed(1)}' : '₹ --',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Images (Optional)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            InkWell(
              onTap: () => _triggerGeminiAIExtraction('Uploaded Image'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder, style: BorderStyle.solid),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryGreen, size: 24),
                    SizedBox(height: 4),
                    Text('Add more', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            ..._uploadedImages.map(
              (img) => Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/milk.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => setState(() => _uploadedImages.remove(img)),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
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
