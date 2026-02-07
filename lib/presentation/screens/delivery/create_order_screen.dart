import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gozapper/core/constants/app_colors.dart';
import 'package:gozapper/core/constants/app_constants.dart';
import 'package:gozapper/core/constants/app_routes.dart';
import 'package:gozapper/core/extension/inbuilt_ext.dart';
import 'package:gozapper/core/services/cloudinary_service.dart';
import 'package:gozapper/core/utils/geocoding_helper.dart';
import 'package:gozapper/core/utils/snackbar_utils.dart';
import 'package:gozapper/data/models/quote_request_model.dart';
import 'package:gozapper/presentation/providers/auth_provider.dart';
import 'package:gozapper/presentation/providers/credential_provider.dart';
import 'package:gozapper/presentation/providers/delivery_provider.dart';
import 'package:gozapper/presentation/widgets/custom_app_bar.dart';
import 'package:gozapper/presentation/widgets/location_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isUploading = false;

  // Services
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

  // Pickup details controllers
  final _pickupNameController = TextEditingController();
  final _pickupPhoneController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  final _pickupInstructionController = TextEditingController();

  // Dropoff details controllers
  final _dropOffNameController = TextEditingController();
  final _dropOffPhoneController = TextEditingController();
  final _dropOffAddressController = TextEditingController();
  final _dropOffInstructionController = TextEditingController();

  // Location coordinates (from geocoding or map picker)
  double? _pickupLatitude;
  double? _pickupLongitude;
  double? _dropOffLatitude;
  double? _dropOffLongitude;

  bool _isGeocodingPickup = false;
  bool _isGeocodingDropOff = false;

  // Items
  final List<ItemData> _items = [];

  // Options
  bool _contactlessDropOff = false;
  bool _signatureRequired = false;
  String _actionIfUndeliverable = 'return_to_pickup';
  String _selectedCountry = 'nigeria';
  String? _selectedVehicleType;
  final _tipController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePickupDetails();
    });
  }

  void _initializePickupDetails() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user != null) {
      _pickupNameController.text = '${user.firstName} ${user.lastName}';
      _pickupPhoneController.text = user.phoneNumber!;
    }
  }

  // Geocode pickup address
  Future<void> _geocodePickupAddress() async {
    var address = _pickupAddressController.text.trim();
    if (address.isEmpty) {
      SnackBarUtils.showInfo(context, "Validating address...");
      var getMyCity = await GeocodingHelper.getUserCity(context);
      _pickupAddressController.text = getMyCity ?? '';
      address = getMyCity ?? address;
    }

    setState(() => _isGeocodingPickup = true);

    final coordinates =
        await GeocodingHelper.getCoordinatesFromAddress(address);

    setState(() => _isGeocodingPickup = false);

    if (coordinates != null) {
      setState(() {
        _pickupLatitude = coordinates.latitude;
        _pickupLongitude = coordinates.longitude;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not find location. Please use map picker or check address.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Geocode drop-off address
  Future<void> _geocodeDropOffAddress() async {
    var address = _dropOffAddressController.text.trim();
    if (address.isEmpty) {
      SnackBarUtils.showInfo(context, "Validating address...");
      var getMyCity = await GeocodingHelper.getUserCity(context);
      _dropOffAddressController.text = getMyCity ?? '';
      address = getMyCity ?? address;
    }

    setState(() => _isGeocodingDropOff = true);

    final coordinates =
        await GeocodingHelper.getCoordinatesFromAddress(address);

    setState(() => _isGeocodingDropOff = false);

    if (coordinates != null) {
      setState(() {
        _dropOffLatitude = coordinates.latitude;
        _dropOffLongitude = coordinates.longitude;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not find location. Please use map picker or check address.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Show map picker for pickup
  Future<void> _pickPickupLocation() async {
    context.hideKeyboard();
    // Always try to geocode the current address before opening map
    setState(() => _isGeocodingPickup = true);
    await _geocodePickupAddress();
    // Wait a bit for geocoding to complete
    await Future.delayed(const Duration(milliseconds: 700));

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context1) => LocationPickerDialog(
        initialLatitude: _pickupLatitude,
        initialLongitude: _pickupLongitude,
        initialAddress: _pickupAddressController.text,
      ),
    );

    context.hideKeyboard();

    if (result != null) {
      setState(() {
        _pickupLatitude = result['latitude'];
        _pickupLongitude = result['longitude'];
        if (result['address'] != null && result['address'].isNotEmpty) {
          _pickupAddressController.text = result['address'];
        }
      });
    }
  }

  // Show map picker for drop-off
  Future<void> _pickDropOffLocation() async {
    context.hideKeyboard();
    setState(() => _isGeocodingDropOff = true);

    await _geocodeDropOffAddress();
    // Wait a bit for geocoding to complete
    await Future.delayed(const Duration(milliseconds: 700));

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => LocationPickerDialog(
        initialLatitude: _dropOffLatitude,
        initialLongitude: _dropOffLongitude,
        initialAddress: _dropOffAddressController.text,
      ),
    );

    context.hideKeyboard();

    if (result != null) {
      setState(() {
        _dropOffLatitude = result['latitude'];
        _dropOffLongitude = result['longitude'];
        if (result['address'] != null && result['address'].isNotEmpty) {
          _dropOffAddressController.text = result['address'];
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pickupNameController.dispose();
    _pickupPhoneController.dispose();
    _pickupAddressController.dispose();
    _pickupInstructionController.dispose();
    _dropOffNameController.dispose();
    _dropOffPhoneController.dispose();
    _dropOffAddressController.dispose();
    _dropOffInstructionController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();

    // Validate current step before moving to next
    if (_currentStep == 0) {
      // Validate pickup details
      if (!_validatePickupDetails()) {
        return;
      }
    } else if (_currentStep == 1) {
      // Validate dropoff details
      if (!_validateDropOffDetails()) {
        return;
      }
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    if (_currentStep == 2 && _items.isEmpty) {
      _addItem();
    }
  }

  bool _validatePickupDetails() {
    if (_pickupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter pickup contact name'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (_pickupPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter pickup phone number'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (_pickupAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter pickup address'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (_pickupLatitude == null || _pickupLongitude == null) {
      _pickPickupLocation();
      return false;
    }

    return true;
  }

  bool _validateDropOffDetails() {
    if (_dropOffNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter recipient name'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (_dropOffPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter recipient phone number'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (_dropOffAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter drop-off address'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (_dropOffLatitude == null || _dropOffLongitude == null) {
      _pickDropOffLocation();
      return false;
    }

    return true;
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _addItem() async {
    final result = await showDialog<ItemData>(
      context: context,
      builder: (context) => const _AddItemDialog(),
    );
    if (result != null) {
      setState(() => _items.add(result));
    }
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _reselectItemImage(int itemIndex) async {
    context.hideKeyboard();

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() => _isUploading = true);

      final imageUrl = await _cloudinaryService.uploadImage(File(image.path));

      if (imageUrl != null) {
        setState(() {
          _items[itemIndex].imageUrl = imageUrl;
          _items[itemIndex].localImagePath = image.path;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
      }

      setState(() => _isUploading = false);
    }
  }

  Future<void> _generateQuote() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }
    if (_selectedVehicleType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select vehicle type')),
      );
      return;
    }

    // Validate coordinates are set
    if (_pickupLatitude == null || _pickupLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please set pickup location using map or enter a valid address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_dropOffLatitude == null || _dropOffLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please set drop-off location using map or enter a valid address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if user has credentials before generating quote (API key required)
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final credentialProvider = context.read<CredentialProvider>();

    if (user != null &&
        user.sandboxCredential == false &&
        user.productionCredential == false) {
      context.showLoadingDialog();
      // No credentials exist, create sandbox credential automatically
      final credentialCreated =
          await credentialProvider.createSandboxCredential(
        'Auto-generated Sandbox Credential',
      );
      if (mounted) context.hideLoadingDialog();

      if (!credentialCreated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              credentialProvider.errorMessage ??
                  'Failed to create API credential',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Refresh user profile to update credential flags
      await authProvider.refreshProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sandbox API credential created automatically!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    final request = QuoteRequestModel(
      country: _selectedCountry,
      tip: _tipController.text.isEmpty ? null : _tipController.text,
      items: _items
          .map((item) => QuoteItemModel(
                name: item.name,
                description: item.description,
                imageUrl: item.imageUrl,
                quantity: item.quantity,
                price: item.price,
                weight: item.weight,
              ))
          .toList(),
      contactlessDropOff: _contactlessDropOff,
      signatureRequired: _signatureRequired,
      dropOffLatitude: _dropOffLatitude!,
      dropOffLongitude: _dropOffLongitude!,
      dropOffInstruction: _dropOffInstructionController.text,
      dropOffDetails: ContactDetailsModel(
        address: _dropOffAddressController.text,
        name: _dropOffNameController.text,
        phone: _dropOffPhoneController.text,
      ),
      pickupLatitude: _pickupLatitude!,
      pickupLongitude: _pickupLongitude!,
      pickupInstruction: _pickupInstructionController.text,
      pickupDetails: ContactDetailsModel(
        address: _pickupAddressController.text,
        name: _pickupNameController.text,
        phone: _pickupPhoneController.text,
      ),
      actionIfUndeliverable: _actionIfUndeliverable,
      requiredVehicleType:
          _selectedVehicleType == AppConstants.vehicleTypeMotorcycle
              ? "motorcycle"
              : (_selectedVehicleType ?? AppConstants.vehicleTypeMotorcycle)
                  .toLowerCase(),
    );

    final provider = context.read<DeliveryProvider>();
    final success = await provider.generateQuote(request);

    if (success && mounted) {
      _showQuoteBottomSheet();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to generate quote'),
        ),
      );
    }
  }

  void _showQuoteBottomSheet() {
    final provider = context.read<DeliveryProvider>();
    final quote = provider.currentQuote;

    if (quote == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery Quote',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildQuoteRow('Delivery Fee', '${quote.currency} ${quote.fee}'),
            _buildQuoteRow('Tax', '${quote.currency} ${quote.tax}'),
            const Divider(height: 24),
            _buildQuoteRow(
              'Total',
              '${quote.currency} ${quote.totalFee.toStringAsFixed(2)}',
              isBold: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _acceptQuote();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Accept & Create Delivery',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptQuote() async {
    // First, check if user is logged in
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Step 1: Check if user has credentials (sandbox or production)
    // If both are false, auto-create sandbox credential
    final credentialProvider = context.read<CredentialProvider>();

    if (user.sandboxCredential == false && user.productionCredential == false) {
      // No credentials exist, create sandbox credential automatically
      final credentialCreated =
          await credentialProvider.createSandboxCredential(
        'Auto-generated Sandbox Credential',
      );

      if (!credentialCreated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              credentialProvider.errorMessage ??
                  'Failed to create API credential',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Refresh user profile to update credential flags
      await authProvider.refreshProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sandbox API credential created automatically!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    // Step 2: Check if user has payment method (paymentId)
    if (user.paymentId == null || user.paymentId!.isEmpty) {
      // Show dialog to add payment method
      if (mounted) {
        _showAddPaymentMethodDialog();
      }
      return;
    }

    // Step 3: User has both credentials and payment method, proceed with accepting quote
    // The backend will automatically charge when quote is accepted
    final deliveryProvider = context.read<DeliveryProvider>();
    final success = await deliveryProvider.acceptQuote();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery created and payment processed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      deliveryProvider.resetQuote();
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              deliveryProvider.errorMessage ?? 'Failed to create delivery'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Payment Method Required'),
        content: const Text(
          'You need to add a payment method before creating a delivery. Would you like to add one now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Navigate to add payment method screen
              final result = await context.push(AppRoutes.addPaymentMethod);

              // If payment method was added successfully, try to accept quote again
              if (result == true && mounted) {
                await _acceptQuote();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              'Add Payment Method',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Create Delivery',
        titleColor: AppColors.white,
        backgroundColor: AppColors.primary,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Step indicator
            _buildStepIndicator(),

            // Form pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPickupDetailsPage(),
                  _buildDropOffDetailsPage(),
                  _buildItemsPage(),
                  _buildOptionsPage(),
                ],
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Pickup', 'Drop-off', 'Items', 'Options'];
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index <= _currentStep;
          final isLast = index == steps.length - 1;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color:
                              isActive ? AppColors.primary : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isActive && index < _currentStep
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 16)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color:
                                        isActive ? Colors.white : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? AppColors.primary : Colors.grey,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: index < _currentStep
                          ? AppColors.primary
                          : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPickupDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pickup Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _pickupNameController,
            label: 'Contact Name',
            hint: 'Enter pickup contact name',
            prefixIcon: Icons.person,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _pickupPhoneController,
            label: 'Phone Number',
            hint: 'Enter phone number',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildAddressField(
            controller: _pickupAddressController,
            label: 'Pickup address and city name',
            hint: 'e.g, 123 Main St, Lagos',
            onMapPicker: _pickPickupLocation,
            onGeocodeAddress: _geocodePickupAddress,
            isGeocoding: _isGeocodingPickup,
            hasCoordinates: _pickupLatitude != null && _pickupLongitude != null,
          ),
          const Text(
            "Ensure you enter city name seperated by comma",
            style: TextStyle(color: Colors.blue, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _pickupInstructionController,
            label: 'Pickup Instructions (Optional)',
            hint: 'Any special instructions for pickup',
            prefixIcon: Icons.note,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDropOffDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Drop-off Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _dropOffNameController,
            label: 'Recipient Name',
            hint: 'Enter recipient name',
            prefixIcon: Icons.person,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _dropOffPhoneController,
            label: 'Phone Number',
            hint: 'Enter recipient phone',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildAddressField(
            controller: _dropOffAddressController,
            label: 'Drop-off address and city name',
            hint: 'e.g, 123 Main St, Lagos',
            onMapPicker: _pickDropOffLocation,
            onGeocodeAddress: _geocodeDropOffAddress,
            isGeocoding: _isGeocodingDropOff,
            hasCoordinates:
                _dropOffLatitude != null && _dropOffLongitude != null,
          ),
          const Text(
            "Ensure you enter city name separated by comma",
            style: TextStyle(color: Colors.blue, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _dropOffInstructionController,
            label: 'Drop-off Instructions (Optional)',
            hint: 'Any special instructions for delivery',
            prefixIcon: Icons.note,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items to Deliver',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No items added yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Add Item" to add items for delivery',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Image
                            GestureDetector(
                              // when item image is tapped
                              onTap: () => _reselectItemImage(index),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: item.localImagePath != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(item.localImagePath!),
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Icon(
                                        Icons.add_photo_alternate,
                                        color: Colors.grey[400],
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Qty: ${item.quantity} | Price: ${item.price}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (item.description != null &&
                                      item.description!.isNotEmpty)
                                    Text(
                                      item.description!,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            // Delete button
                            IconButton(
                              onPressed: () => _removeItem(index),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_isUploading)
          Container(
            padding: const EdgeInsets.all(16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Uploading image...'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOptionsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Country selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Country',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'nigeria', child: Text('Nigeria')),
                    DropdownMenuItem(value: 'us', child: Text('United States')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCountry = value!);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Vehicle Type selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Required Vehicle Type',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedVehicleType,
                  decoration: InputDecoration(
                    hintText: 'Select vehicle type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: AppConstants.vehicleTypes.map((vehicleType) {
                    return DropdownMenuItem(
                      value: vehicleType,
                      child: Text(AppConstants.vehicleTypeLabels[vehicleType] ??
                          vehicleType),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedVehicleType = value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tip
          _buildTextField(
            controller: _tipController,
            label: '₦ Tip (Optional)',
            hint: '₦ Enter tip amount',
            prefixIcon: Icons.navigation_rounded,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 16),

          // Toggles
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Contactless Drop-off'),
                  subtitle: const Text('Leave package at the door'),
                  value: _contactlessDropOff,
                  onChanged: (value) {
                    setState(() => _contactlessDropOff = value);
                  },
                  activeColor: AppColors.primary,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Signature Required'),
                  subtitle: const Text('Recipient must sign for delivery'),
                  value: _signatureRequired,
                  onChanged: (value) {
                    setState(() => _signatureRequired = value);
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action if undeliverable
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'If Undeliverable',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text('Return to Pickup'),
                  value: 'return_to_pickup',
                  groupValue: _actionIfUndeliverable,
                  onChanged: (value) {
                    setState(() => _actionIfUndeliverable = value!);
                  },
                  activeColor: AppColors.primary,
                ),
                RadioListTile<String>(
                  title: const Text('Dispose'),
                  value: 'dispose',
                  groupValue: _actionIfUndeliverable,
                  onChanged: (value) {
                    setState(() => _actionIfUndeliverable = value!);
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(prefixIcon, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAddressField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required VoidCallback onMapPicker,
    required Future<void> Function() onGeocodeAddress,
    required bool isGeocoding,
    required bool hasCoordinates,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: 2,
            onEditingComplete: onGeocodeAddress,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon:
                  const Icon(Icons.location_on, color: AppColors.primary),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isGeocoding)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (hasCoordinates)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                    ),
                  IconButton(
                    onPressed: onMapPicker,
                    icon: const Icon(Icons.map, color: AppColors.primary),
                    tooltip: 'Pick on map',
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        if (hasCoordinates)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              'Location verified ✓',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    final provider = context.watch<DeliveryProvider>();
    final isLoading = provider.isGeneratingQuote || provider.isAcceptingQuote;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : _currentStep == 3
                      ? _generateQuote
                      : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _currentStep == 3 ? 'Get Quote' : 'Continue',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for item data
class ItemData {
  String name;
  String? description;
  int quantity;
  String price;
  double? weight;
  String? imageUrl;
  String? localImagePath;

  ItemData({
    required this.name,
    this.description,
    required this.quantity,
    required this.price,
    this.weight,
    this.imageUrl,
    this.localImagePath,
  });
}

// Dialog for adding items
class _AddItemDialog extends StatefulWidget {
  const _AddItemDialog();

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _weightController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isUploading = true;
      });

      // Upload to Cloudinary
      final imageUrl = await _cloudinaryService.uploadImage(File(image.path));

      setState(() {
        _uploadedImageUrl = imageUrl;
        _isUploading = false;
      });

      if (imageUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    context.hideKeyboard();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Camera'),
                subtitle: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: const Text('Gallery'),
                subtitle: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Item'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '₦ Item cost*',
                        hintText: 'Declared value',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Image picker section
              GestureDetector(
                onTap: _isUploading ? null : _showImageSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: _isUploading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Uploading...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _selectedImage != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _selectedImage!,
                                    width: double.infinity,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImage = null;
                                        _uploadedImageUrl = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_uploadedImageUrl != null)
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Uploaded',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add Item Photo',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Tap to select from camera or gallery',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 11,
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUploading
              ? null
              : () {
                  // Validate item name
                  if (_nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter item name'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  // Validate quantity
                  final quantity = int.tryParse(_quantityController.text);
                  if (quantity == null || quantity <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Please enter a valid quantity (must be greater than 0)'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  // Validate item cost/price
                  if (_priceController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter item cost'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  final price = double.tryParse(_priceController.text);
                  if (price == null || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Please enter a valid item cost (must be greater than 0)'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  final item = ItemData(
                    name: _nameController.text,
                    description: _descriptionController.text.isEmpty
                        ? null
                        : _descriptionController.text,
                    quantity: quantity,
                    price: _priceController.text,
                    weight: double.tryParse(_weightController.text),
                    imageUrl: _uploadedImageUrl,
                    localImagePath: _selectedImage?.path,
                  );

                  Navigator.pop(context, item);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: const Text(
            'Add',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
