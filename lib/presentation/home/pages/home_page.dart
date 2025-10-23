import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_absensi_app/core/helper/radius_calculate.dart';
import 'package:flutter_absensi_app/data/datasources/auth_local_datasource.dart';
import 'package:flutter_absensi_app/presentation/home/bloc/get_company/get_company_bloc.dart';
import 'package:flutter_absensi_app/presentation/home/bloc/is_checkedin/is_checkedin_bloc.dart';
import 'package:flutter_absensi_app/presentation/home/pages/attandences/face_detector_checkin_page.dart';
import 'package:flutter_absensi_app/presentation/home/pages/attandences/attendance_result_page.dart';
// import 'package:flutter_absensi_app/presentation/home/pages/attandences/scanner_page.dart';
import 'package:flutter_absensi_app/presentation/leaves/pages/leave_page.dart';
import 'package:flutter_absensi_app/presentation/overtimes/pages/overtime_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/core.dart';
import '../../../data/datasources/attendance_remote_datasource.dart';
import '../../../data/models/response/company_locations_response_model.dart';
import '../../history/pages/history_page.dart';
import '../../permits/pages/permits_page.dart';
import '../../profile/bloc/get_user/get_user_bloc.dart';
import 'register_face_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<CompanyLocation> _companyLocations = [];
  CompanyLocation? _selectedCompanyLocation;
  bool _isCompanyLocationsLoading = false;
  String? _companyLocationsError;
  String? faceEmbedding;
  double? latitude;
  double? longitude;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _cardController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();

    _initializeAnimations();
    _initializeFaceEmbedding();

    context.read<IsCheckedinBloc>().add(const IsCheckedinEvent.isCheckedIn());
    context.read<GetCompanyBloc>().add(const GetCompanyEvent.getCompany());
    context.read<GetUserBloc>().add(const GetUserEvent.getUser());

    getCurrentPosition();
    _startAnimations();

    // Run fetch dropdown after first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCompanyLocations();
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _cardAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _slideController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        _cardController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> getCurrentPosition() async {
    try {
      Location location = Location();
      bool serviceEnabled;
      PermissionStatus permissionGranted;
      LocationData locationData;

      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }

      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      locationData = await location.getLocation();
      latitude = locationData.latitude;
      longitude = locationData.longitude;
      setState(() {});
    } on PlatformException catch (e) {
      if (e.code == 'IO_ERROR') {
        debugPrint('Network error occurred: ${e.message}');
      } else {
        debugPrint('Failed to lookup coordinates: ${e.message}');
      }
    } catch (e) {
      debugPrint('Unknown error occurred: $e');
    }
  }

  Future<void> _initializeFaceEmbedding() async {
    try {
      final authData = await AuthLocalDatasource().getAuthData();
      setState(() {
        faceEmbedding = authData?.user?.faceEmbedding;
      });
    } catch (e) {
      debugPrint('Error fetching auth data: $e');
      setState(() {
        faceEmbedding = null;
      });
    }
  }

  Future<void> _onRefresh() async {
    // Refresh all data
    context.read<GetUserBloc>().add(const GetUserEvent.getUser());
    context.read<GetCompanyBloc>().add(const GetCompanyEvent.getCompany());
    context.read<IsCheckedinBloc>().add(const IsCheckedinEvent.isCheckedIn());

    // Refresh face embedding
    await _initializeFaceEmbedding();

    // Wait a bit for the blocs to process
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.4, 1.0],
            colors: [
              Color(0xFF1e3c72), // Deep professional blue
              Color(0xFF2a5298), // Professional blue
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: const Color(0xFF1e3c72),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Header Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 16.0),
                      child: _buildHeader(),
                    ),
                  ),

                  const SpaceHeight(10),

                  // Time Card Section
                  SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _cardAnimation,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: _buildTimeCard(),
                      ),
                    ),
                  ),

                  const SpaceHeight(2),

                  // Location Dropdown Section
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildLocationDropdown(),
                  ),

                  const SpaceHeight(8),

                  // Menu Grid Section
                  SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _buildMenuGrid(),
                    ),
                  ),

                  const SpaceHeight(24),

                  // // Face Attendance Button
                  // if (faceEmbedding != null)
                  //   ScaleTransition(
                  //     scale: _cardAnimation,
                  //     child: Container(
                  //       margin: const EdgeInsets.symmetric(horizontal: 24.0),
                  //       child: _buildFaceAttendanceButton(),
                  //     ),
                  //   ),

                  // const SpaceHeight(24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FutureBuilder(
      future: AuthLocalDatasource().getAuthData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingHeader();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildFallbackHeader();
        }

        final authData = snapshot.data!;
        final user = authData.user;
        final role = authData.role ?? user?.role ?? '-';
        final position = authData.position ?? user?.position ?? '-';
        final departmentName =
            authData.department?.name ?? user?.departemen?.name ?? '-';
        final shiftName =
            authData.defaultShift?.name ?? user?.shiftKerja?.name ?? '-';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child:
                          user?.imageUrl != null && user!.imageUrl!.isNotEmpty
                              ? Image.network(
                                  user.imageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        size: 28,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                    ),
                  ),
                  const SpaceWidth(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, ${user?.name ?? 'User'}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SpaceHeight(2),
                        Text(
                          position == '-' ? '' : position,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SpaceHeight(12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Icon(
                        //   Icons.badge_rounded,
                        //   size: 16,
                        //   color: Colors.white.withOpacity(0.9),
                        // ),
                        // const SpaceWidth(8),
                        // Expanded(
                        //   child: Text(
                        //     'Role: $role',
                        //     style: GoogleFonts.poppins(
                        //       fontSize: 11,
                        //       fontWeight: FontWeight.w500,
                        //       color: Colors.white.withOpacity(0.9),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                    const SpaceHeight(6),
                    Row(
                      children: [
                        Icon(
                          Icons.business_rounded,
                          size: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SpaceWidth(8),
                        Expanded(
                          child: Text(
                            'Lembaga: $departmentName',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SpaceHeight(6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SpaceWidth(8),
                        Expanded(
                          child: Text(
                            'Shift: $shiftName',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                            ),
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
      },
    );
  }

  Widget _buildFallbackHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.person,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SpaceWidth(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, User',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SpaceHeight(4),
                Text(
                  'Have a productive day!',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
          const SpaceWidth(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SpaceHeight(8),
                Container(
                  height: 14,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchCompanyLocations() async {
    setState(() {
      _isCompanyLocationsLoading = true;
      _companyLocationsError = null;
    });

    // Get current user id from local auth
    final auth = await AuthLocalDatasource().getAuthData();
    final userId = auth?.user?.id?.toString() ?? '';

    final result =
        await AttendanceRemoteDatasource().getCompanyLocations(userId);

    result.fold(
      (err) {
        setState(() {
          _companyLocationsError = err;
          _isCompanyLocationsLoading = false;
        });
      },
      (resp) {
        setState(() {
          _companyLocations = resp.data ?? [];
          _selectedCompanyLocation =
              _companyLocations.isNotEmpty ? _companyLocations.first : null;
          _isCompanyLocationsLoading = false;
        });
      },
    );
  }

  Widget _buildLocationDropdown() {
    if (_isCompanyLocationsLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24.0),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_companyLocationsError != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red[700]),
            const SpaceWidth(8),
            Expanded(
              child: Text(
                _companyLocationsError!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.red[800],
                ),
              ),
            ),
            TextButton(
              onPressed: _fetchCompanyLocations,
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    if (_companyLocations.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.blue[700]),
            const SpaceWidth(8),
            Expanded(
              child: Text(
                'Belum di set',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[800],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Safely set current value only if present in the items
    final currentValue = (_selectedCompanyLocation != null &&
            _companyLocations.any(
              (e) => e.id == _selectedCompanyLocation!.id,
            ))
        ? _selectedCompanyLocation!.id
        : null;

    return SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24.0),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: DropdownButtonFormField<int>(
            isExpanded: true,
            value: currentValue,
            dropdownColor: const Color(0xFFFFFFFF),
            style: GoogleFonts.poppins(color: const Color(0xFF000000)),
            iconEnabledColor: const Color(0xFF000000),
            iconDisabledColor: const Color(0xFF000000),
            decoration: InputDecoration(
              labelText: 'Lokasi Absensi',
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF000000),
                backgroundColor: const Color(0xFFFFFFFF),
              ),
              floatingLabelStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF000000),
                backgroundColor: const Color(0xFFFFFFFF),
              ),
              hintText: 'Pilih lokasi',
              hintStyle: GoogleFonts.poppins(fontSize: 12),
              filled: true,
              fillColor: const Color(0xFFFFFFFF),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _companyLocations
                .map(
                  (loc) => DropdownMenuItem<int>(
                    value: loc.id,
                    child: Text(
                      loc.name ?? '-',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF000000),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val == null) {
                setState(() => _selectedCompanyLocation = null);
                return;
              }
              final match = _companyLocations.firstWhere(
                (e) => e.id == val,
                orElse: () => _companyLocations.first,
              );
              setState(() {
                _selectedCompanyLocation = match;
              });
            },
          ),
        ));
  }

  // Build jadwal sholat yang mengambil API dari indonesia
  Widget _buildTimeCard() {
    return FutureBuilder(
      future: AuthLocalDatasource().getAuthData(),
      builder: (context, snapshot) {
        String startTime = '08:00';
        String endTime = '17:00';

        if (snapshot.hasData && snapshot.data != null) {
          final authData = snapshot.data!;
          startTime = authData.user?.shiftKerja?.startTime ??
              authData.defaultShiftDetail?.startTime?.toFormattedTime() ??
              '08:00';
          endTime = authData.user?.shiftKerja?.endTime ??
              authData.defaultShiftDetail?.endTime?.toFormattedTime() ??
              '17:00';
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1e3c72), Color(0xFF3b82c9)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.access_time_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SpaceWidth(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Waktu saat ini',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          DateTime.now().toFormattedDate(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SpaceHeight(12),
              Text(
                DateTime.now().toFormattedTime(),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 30,
                  color: const Color(0xFF1e3c72),
                ),
              ),
              const SpaceHeight(12),
              Container(
                width: double.infinity,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.grey[300]!,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SpaceHeight(10),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jam Kerja',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '$startTime - $endTime',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              //Dropdown lokasi absensi
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuGrid() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1e3c72), Color(0xFF3b82c9)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.apps_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SpaceWidth(16),
              Text(
                'Silahkan Pilih',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SpaceHeight(15),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
            children: [
              _buildAttendanceButton(isCheckIn: true),
              _buildAttendanceButton(isCheckIn: false),
            ],
          ),
          const SpaceHeight(15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildModernMenuButton(
                icon: Icons.perm_identity,
                label: 'Izin',
                subtitle: '-------',
                gradient: const LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                ),
                onPressed: () async {
                  await _checkBackendAndNavigate(() {
                    context.push(const PermitsPage());
                  });
                },
              ),
              _buildModernMenuButton(
                icon: Icons.time_to_leave,
                label: 'Cuti',
                subtitle: '-------',
                gradient: const LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                ),
                onPressed: () async {
                  await _checkBackendAndNavigate(() {
                    context.push(const LeavePage());
                  });
                },
              ),
              _buildModernMenuButton(
                icon: Icons.history_rounded,
                label: 'History',
                subtitle: '-------',
                gradient: const LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                ),
                onPressed: () async {
                  await _checkBackendAndNavigate(() {
                    context.push(const HistoryPage());
                  });
                },
              ),
              _buildModernMenuButton(
                icon: Icons.access_time_filled_rounded,
                label: 'Lembur',
                subtitle: '------',
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                ),
                onPressed: () async {
                  await _checkBackendAndNavigate(() {
                    context.push(const OvertimePage());
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceButton({required bool isCheckIn}) {
    return BlocBuilder<GetCompanyBloc, GetCompanyState>(
      builder: (context, state) {
        final fallbackLat = state.maybeWhen(
          orElse: () => 0.0,
          success: (data) => double.tryParse(data.latitude ?? '0') ?? 0.0,
        );
        final fallbackLng = state.maybeWhen(
          orElse: () => 0.0,
          success: (data) => double.tryParse(data.longitude ?? '0') ?? 0.0,
        );
        final fallbackRadius = state.maybeWhen(
          orElse: () => 0.0,
          success: (data) => double.tryParse(data.radiusKm ?? '0') ?? 0.0,
        );
        final fallbackAttendanceType = state.maybeWhen(
          orElse: () => 'Location',
          success: (data) => data.attendanceType ?? 'Location',
        );

        final latitudePoint = _selectedCompanyLocation != null
            ? double.tryParse(_selectedCompanyLocation!.latitude ?? '0') ?? 0.0
            : fallbackLat;
        final longitudePoint = _selectedCompanyLocation != null
            ? double.tryParse(_selectedCompanyLocation!.longitude ?? '0') ?? 0.0
            : fallbackLng;
        final radiusPoint = _selectedCompanyLocation != null
            ? double.tryParse(_selectedCompanyLocation!.radiusKm ?? '0') ?? 0.0
            : fallbackRadius;
        final attendanceType =
            _selectedCompanyLocation?.attendanceType ?? fallbackAttendanceType;

        print('latitudePoint: $latitudePoint');
        print('longitudePoint: $longitudePoint');
        print('radiusPoint: $radiusPoint');
        print('attendanceType: $attendanceType');

        return BlocBuilder<IsCheckedinBloc, IsCheckedinState>(
          builder: (context, state) {
            final isCheckedin = state.maybeWhen(
              orElse: () => false,
              success: (data) => data.isCheckedin,
            );
            final isCheckout = state.maybeWhen(
              orElse: () => false,
              success: (data) => data.isCheckedout,
            );

            return _buildModernAttendanceButton(
              isCheckIn: isCheckIn,
              isCheckedin: isCheckedin,
              isCheckout: isCheckout,
              onPressed: () => _handleAttendance(
                isCheckIn: isCheckIn,
                isCheckedin: isCheckedin,
                isCheckout: isCheckout,
                latitudePoint: latitudePoint,
                longitudePoint: longitudePoint,
                radiusPoint: radiusPoint,
                attendanceType: attendanceType,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFaceAttendanceButton() {
    return BlocBuilder<IsCheckedinBloc, IsCheckedinState>(
      builder: (context, state) {
        final isCheckout = state.maybeWhen(
          orElse: () => false,
          success: (data) => data.isCheckedout,
        );
        final isCheckIn = state.maybeWhen(
          orElse: () => false,
          success: (data) => data.isCheckedin,
        );

        return BlocBuilder<GetCompanyBloc, GetCompanyState>(
          builder: (context, state) {
            final latitudePoint = state.maybeWhen(
              orElse: () => 0.0,
              success: (data) => double.parse(data.latitude!),
            );
            final longitudePoint = state.maybeWhen(
              orElse: () => 0.0,
              success: (data) => double.parse(data.longitude!),
            );
            final radiusPoint = state.maybeWhen(
              orElse: () => 0.0,
              success: (data) => double.parse(data.radiusKm!),
            );

            String buttonText = 'Absen dengan Wajah';
            if (!isCheckIn) {
              buttonText = 'Check In dengan Wajah';
            } else if (!isCheckout) {
              buttonText = 'Check Out dengan Wajah';
            } else {
              buttonText = 'Absensi Selesai';
            }

            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1e3c72),
                    Color(0xFF3b82c9),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1e3c72).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _handleFaceAttendance(
                    isCheckIn: isCheckIn,
                    isCheckout: isCheckout,
                    latitudePoint: latitudePoint,
                    longitudePoint: longitudePoint,
                    radiusPoint: radiusPoint,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Assets.icons.attendance.svg(
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          width: 24,
                          height: 24,
                        ),
                        const SpaceWidth(12),
                        Text(
                          buttonText,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleAttendance({
    required bool isCheckIn,
    required bool isCheckedin,
    required bool isCheckout,
    required double latitudePoint,
    required double longitudePoint,
    required double radiusPoint,
    required String attendanceType,
  }) async {
    try {
      // Check face embedding FIRST for Face attendance type
      if (attendanceType == 'face_recognition_only' ||
          attendanceType == 'hybrid') {
        if (faceEmbedding == null || faceEmbedding!.isEmpty) {
          _showRegisterFaceDialog();
          return;
        }
      }

      // THEN check location and other validations
      final distanceKm = RadiusCalculate.calculateDistance(
        latitude ?? 0.0,
        longitude ?? 0.0,
        latitudePoint,
        longitudePoint,
      );

      final position = await Geolocator.getCurrentPosition();

      if (position.isMocked) {
        _showFakeGpsDialog();
        return;
      }

      if (distanceKm > radiusPoint) {
        _showOutOfAreaDialog(
          distance: distanceKm,
          allowedRadius: radiusPoint,
        );
        return;
      }

      if (isCheckIn) {
        if (isCheckedin) {
          _showModernDialog(
            'Sudah Checked In',
            'Anda sudah check-in hari ini.',
            Icons.check_circle_rounded,
            Colors.green,
          );
          return;
        }
      } else {
        if (!isCheckedin) {
          _showModernDialog(
            'Check In diperlukan',
            'Anda perlu check-in terlebih dahulu sebelum check-out.',
            Icons.info_rounded,
            Colors.blue,
          );
          return;
        }
        if (isCheckout) {
          _showModernDialog(
            'Sudah Checked Out',
            'Anda sudah check-out hari ini.',
            Icons.check_circle_rounded,
            Colors.green,
          );
          return;
        }
      }

      _navigateToAttendance(attendanceType, isCheckIn);
    } catch (e) {
      _showModernDialog(
        'Error',
        'An error occurred: $e',
        Icons.error_rounded,
        Colors.red,
      );
    }
  }

  Future<void> _handleFaceAttendance({
    required bool isCheckIn,
    required bool isCheckout,
    required double latitudePoint,
    required double longitudePoint,
    required double radiusPoint,
  }) async {
    try {
      final distanceKm = RadiusCalculate.calculateDistance(
        latitude ?? 0.0,
        longitude ?? 0.0,
        latitudePoint,
        longitudePoint,
      );

      final position = await Geolocator.getCurrentPosition();

      if (position.isMocked) {
        _showModernSnackBar(
          'Anda menggunakan aplikasi GPS palsu',
          Icons.error_outline,
          Colors.red,
        );
        return;
      }

      if (distanceKm > radiusPoint) {
        _showModernSnackBar(
          'Anda berada di luar area absensi',
          Icons.location_off,
          Colors.orange,
        );
        return;
      }

      if (!isCheckIn) {
        await _checkBackendAndNavigate(() {
          context.push(FaceDetectorCheckinPage(
            isCheckedIn: true,
            latitude: latitude,
            longitude: longitude,
          ));
        });
      } else if (!isCheckout) {
        await _checkBackendAndNavigate(() {
          context.push(FaceDetectorCheckinPage(
            isCheckedIn: false,
            latitude: latitude,
            longitude: longitude,
          ));
        });
      } else {
        _showModernSnackBar(
          'Anda sudah absen hari ini',
          Icons.check_circle,
          Colors.green,
        );
      }
    } catch (e) {
      _showModernSnackBar(
        'Error: $e',
        Icons.error,
        Colors.red,
      );
    }
  }

  void _showModernDialog(
      String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SpaceHeight(16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SpaceHeight(8),
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SpaceHeight(24),
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(context),
                    child: Center(
                      child: Text(
                        'OK',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModernSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SpaceWidth(8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _checkBackendAndNavigate(Function navigate) async {
    // Show loading indicator
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );

    // Check backend connection
    final isConnected = await BackendConnectionHelper.checkBackendSocket();

    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);
    }

    if (!mounted) return;

    if (isConnected) {
      // Backend is reachable, proceed with navigation
      navigate();
    } else {
      // Backend is not reachable, show error dialog
      BackendConnectionDialog.show(
        context,
        customMessage: 'Tidak dapat terhubung ke backend saat ini',
      );
    }
  }

  Future<void> _navigateToAttendance(
      String attendanceType, bool isCheckIn) async {
    await _checkBackendAndNavigate(() {
      if (attendanceType == 'face_recognition_only' ||
          attendanceType == 'hybrid') {
        context.push(FaceDetectorCheckinPage(
          isCheckedIn: isCheckIn,
          latitude: latitude,
          longitude: longitude,
        ));
      } else {
        // For location_based_only and other types, pass lat/long
        context.push(AttendanceResultPage(
          isCheckin: isCheckIn,
          isMatch: true,
          attendanceType: attendanceType,
          latitude: latitude,
          longitude: longitude,
        ));
      }
    });
  }

  void _showRegisterFaceDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1e3c72).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.face_rounded,
                  color: Color(0xFF1e3c72),
                  size: 32,
                ),
              ),
              const SpaceHeight(16),
              Text(
                'Pendaftaran wajah',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SpaceHeight(8),
              Text(
                'Anda perlu mendaftarkan wajah terlebih dahulu sebelum menggunakan absensi wajah. Apakah Anda ingin mendaftarkannya sekarang?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SpaceHeight(24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context),
                          child: Center(
                            child: Text(
                              'Nanti',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SpaceWidth(12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1e3c72), Color(0xFF3b82c9)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.pop(context);
                            context.push(const RegisterFacePage());
                          },
                          child: Center(
                            child: Text(
                              'Daftar',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFakeGpsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.1),
                      Colors.red.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.gps_off_rounded,
                  color: Colors.red[700],
                  size: 48,
                ),
              ),
              const SpaceHeight(24),
              Text(
                'Fake GPS Terdeteksi!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SpaceHeight(12),
              Text(
                'Sistem mendeteksi bahwa HP Anda menggunakan aplikasi fake GPS atau mock location.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SpaceHeight(8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SpaceWidth(12),
                    Expanded(
                      child: Text(
                        'Harap nonaktifkan fake GPS terlebih dahulu untuk melanjutkan absensi.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange[800],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SpaceHeight(28),
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red[600]!,
                      Colors.red[700]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context),
                    child: Center(
                      child: Text(
                        'Mengerti',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOutOfAreaDialog({
    required double distance,
    required double allowedRadius,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.1),
                      Colors.orange.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.location_off_rounded,
                  color: Colors.orange[700],
                  size: 48,
                ),
              ),
              const SpaceHeight(24),
              Text(
                'Lokasi Di Luar Area!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SpaceHeight(12),
              Text(
                'Anda berada di luar jangkauan area absensi yang telah ditentukan oleh kantor.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SpaceHeight(16),
              // Distance information box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.straighten_rounded,
                          color: Colors.red[700],
                          size: 20,
                        ),
                        const SpaceWidth(8),
                        Text(
                          'Informasi Jarak',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[800],
                          ),
                        ),
                      ],
                    ),
                    const SpaceHeight(12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jarak Anda:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${distance.toStringAsFixed(2)} km',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SpaceHeight(6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Radius Maksimal:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${allowedRadius.toStringAsFixed(2)} km',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SpaceHeight(6),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.red.withOpacity(0.2),
                    ),
                    const SpaceHeight(6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kelebihan Jarak:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${(distance - allowedRadius).toStringAsFixed(2)} km',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.red[900],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SpaceHeight(12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SpaceWidth(12),
                    Expanded(
                      child: Text(
                        'Harap mendekat ke lokasi kantor untuk dapat melakukan absensi.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[800],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SpaceHeight(28),
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange[600]!,
                      Colors.orange[700]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context),
                    child: Center(
                      child: Text(
                        'Mengerti',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernMenuButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onPressed,
  }) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        tween: Tween(begin: 0.96, end: 1.0),
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: child,
        ),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '------',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.92),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernAttendanceButton({
    required bool isCheckIn,
    required bool isCheckedin,
    required bool isCheckout,
    required VoidCallback onPressed,
  }) {
    final bool isDisabled =
        isCheckIn ? isCheckedin : !isCheckedin || isCheckout;

    final String label = isCheckIn ? 'Absensi' : 'Keluar';
    final String subtitle = isCheckIn ? 'Start your day' : 'End your day';
    final IconData icon =
        isCheckIn ? Icons.login_rounded : Icons.logout_rounded;

    final LinearGradient gradient = isCheckIn
        ? const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF45A049)])
        : const LinearGradient(colors: [Color(0xFFF44336), Color(0xFFE57373)]);

    final LinearGradient disabledGradient =
        const LinearGradient(colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)]);

    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isDisabled ? disabledGradient : gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDisabled
                  ? Colors.grey.withOpacity(0.3)
                  : gradient.colors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SpaceHeight(8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SpaceHeight(2),
          ],
        ),
      ),
    );
  }
}
