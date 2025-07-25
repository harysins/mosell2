import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController(); // New
  final _phoneNumberController =
      TextEditingController(); // New (for Google sign-up)
  final _smsCodeController = TextEditingController();

  UserType _selectedUserType = UserType.buyer;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  bool _isPhoneVerificationSent = false;

  get image => null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose(); // Dispose new controller
    _phoneNumberController.dispose(); // Dispose new controller
    _smsCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_selectedImage != null && _selectedUserType == UserType.broker) {}

    String? location =
        _selectedUserType == UserType.broker &&
            _locationController.text.isNotEmpty
        ? _locationController.text.trim()
        : null;
    String? address =
        _selectedUserType == UserType.broker &&
            _addressController.text.isNotEmpty
        ? _addressController.text.trim()
        : null;
    String? phoneNumber =
        _selectedUserType == UserType.broker &&
            _phoneNumberController.text.isNotEmpty
        ? _phoneNumberController.text.trim()
        : null;

    bool success = await authProvider.signInWithGoogle(
      _selectedUserType,
      location,
      address,
      phoneNumber,
    );

    if (success) {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل في تسجيل الدخول عبر Google'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _sendPhoneVerification() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String phoneNumber = _phoneController.text.trim();

    // Add country code if not present (assuming Iraq +964)
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+964$phoneNumber';
    }

    bool success = await authProvider.sendPhoneVerificationCode(phoneNumber);

    if (success) {
      setState(() {
        _isPhoneVerificationSent = true;
      });
      // ignore: use_build_context_synchronously
      // ignore: use_build_context_synchronously
      // ignore: use_build_context_synchronously
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال رمز التحقق إلى هاتفك'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل في إرسال رمز التحقق'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _verifyPhoneAndSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    String? photoUrl;
    if (_selectedImage != null && _selectedUserType == UserType.broker) {
      photoUrl = await _storageService.uploadFile(
        _selectedImage!,
        'profile_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    }

    String? location =
        _selectedUserType == UserType.broker &&
            _locationController.text.isNotEmpty
        ? _locationController.text.trim()
        : null;
    String? address =
        _selectedUserType == UserType.broker &&
            _addressController.text.isNotEmpty
        ? _addressController.text.trim()
        : null;

    bool success = await authProvider.verifyPhoneCodeAndSignIn(
      _smsCodeController.text.trim(),
      _nameController.text.trim(),
      _selectedUserType,
      photoUrl,
      location,
      address,
    );

    if (success) {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رمز التحقق غير صحيح'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          // ignore: deprecated_member_use
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Google'),
            Tab(text: 'رقم الهاتف'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildGoogleSignInTab(), _buildPhoneSignInTab()],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.grey,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('متابعة كمشتري'),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),

            // User Type Selection
            const Text(
              'نوع الحساب',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: RadioListTile<UserType>(
                    title: const Text('مشتري'),
                    value: UserType.buyer,
                    groupValue: _selectedUserType,
                    onChanged: (UserType? value) {
                      setState(() {
                        _selectedUserType = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<UserType>(
                    title: const Text('سمسار'),
                    value: UserType.broker,
                    groupValue: _selectedUserType,
                    onChanged: (UserType? value) {
                      setState(() {
                        _selectedUserType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Broker-specific fields
            if (_selectedUserType == UserType.broker) ...[
              // Profile Image
              const Text(
                'الصورة الشخصية',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(color: AppColors.grey),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          size: 40,
                          color: AppColors.grey,
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'الموقع (اختياري)',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),

              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'العنوان الكامل (اختياري)',
                  prefixIcon: Icon(Icons.home),
                ),
              ),

              const SizedBox(height: 16),

              // Phone Number (for Google Sign-In)
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف (اختياري)',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '07901234567',
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),
            ],

            // Google Sign-In Button
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: authProvider.isLoading
                        ? null
                        : _signInWithGoogle,
                    icon: authProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Image.asset(
                            'assets/images/google_icon.jpg',
                            height: 20,
                            width: 24,
                          ),
                    label: Text(
                      authProvider.isLoading
                          ? 'جاري التسجيل...'
                          : 'تسجيل الدخول عبر Google',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 2, 5, 12),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneSignInTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),

            if (!_isPhoneVerificationSent) ...[
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال الاسم';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '7901234567',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال رقم الهاتف';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // User Type Selection
              const Text(
                'نوع الحساب',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: RadioListTile<UserType>(
                      title: const Text('مشتري'),
                      value: UserType.buyer,
                      groupValue: _selectedUserType,
                      onChanged: (UserType? value) {
                        setState(() {
                          _selectedUserType = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<UserType>(
                      title: const Text('سمسار'),
                      value: UserType.broker,
                      groupValue: _selectedUserType,
                      onChanged: (UserType? value) {
                        setState(() {
                          _selectedUserType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Broker-specific fields
              if (_selectedUserType == UserType.broker) ...[
                // Profile Image
                const Text(
                  'الصورة الشخصية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(color: AppColors.grey),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: AppColors.grey,
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'الموقع (اختياري)',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),

                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان الكامل (اختياري)',
                    prefixIcon: Icon(Icons.home),
                  ),
                ),

                const SizedBox(height: 24),
              ],

              // Send Verification Code Button
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : _sendPhoneVerification,
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator(
                              color: AppColors.white,
                            )
                          : const Text('إرسال رمز التحقق'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  );
                },
              ),
            ] else ...[
              // SMS Code Input
              const Text(
                'أدخل رمز التحقق المرسل إلى هاتفك',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _smsCodeController,
                decoration: const InputDecoration(
                  labelText: 'رمز التحقق',
                  prefixIcon: Icon(Icons.sms),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال رمز التحقق';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Verify and Sign In Button
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : _verifyPhoneAndSignIn,
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator(
                              color: AppColors.white,
                            )
                          : const Text('تأكيد وتسجيل الدخول'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Back Button
              TextButton(
                onPressed: () {
                  setState(() {
                    _isPhoneVerificationSent = false;
                    _smsCodeController.clear();
                  });
                },
                child: const Text('العودة لتغيير رقم الهاتف'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
