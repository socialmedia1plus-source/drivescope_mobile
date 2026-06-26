import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_model.dart';
import '../services/trip_service.dart';
import '../services/ai_copilot_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TripService _tripService = TripService();

  int _todayTripsCount = 0;
  double _todayEarnings = 0.0;
  double _totalWalletBalance = 0.0;
  List<TripModel> _allTrips = [];

  void _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _calculateStats(List<TripModel> trips) {
    int tripsCount = 0;
    double earnings = 0.0;
    double walletBalance = 0.0;
    final now = DateTime.now();

    for (var trip in trips) {
      walletBalance += trip.netEarnings;
      if (trip.startTime.year == now.year &&
          trip.startTime.month == now.month &&
          trip.startTime.day == now.day) {
        tripsCount++;
        earnings += trip.fareAmount;
      }
    }

    _todayTripsCount = tripsCount;
    _todayEarnings = earnings;
    _totalWalletBalance = walletBalance;
    _allTrips = trips;
  }

  void _showAddTripSheet(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String _selectedPlatform = 'Uber';
    double _distance = 0.0;
    double _fare = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24, left: 24, right: 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'تسجيل رحلة مكتملة',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _selectedPlatform,
                    decoration: InputDecoration(
                      labelText: 'المنصة',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Uber', 'Careem', 'InDrive', 'Other'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (value) => _selectedPlatform = value ?? 'Uber',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'إجمالي الأجرة المستلمة (ج.م)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => (val == null || val.isEmpty) ? 'مطلوب' : null,
                    onSaved: (val) => _fare = double.tryParse(val ?? '0') ?? 0.0,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'المسافة المقطوعة (كم)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => (val == null || val.isEmpty) ? 'مطلوب' : null,
                    onSaved: (val) => _distance = double.tryParse(val ?? '0') ?? 0.0,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        double net = _fare * 0.75; 

                        final newTrip = TripModel(
                          driverId: _auth.currentUser?.uid ?? '',
                          startTime: DateTime.now(),
                          distanceKm: _distance,
                          fareAmount: _fare,
                          netEarnings: net,
                          platform: _selectedPlatform,
                        );

                        await _tripService.saveNewTrip(newTrip);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تسجيل وحفظ الرحلة سحابياً بنجاح!')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('تأكيد وحفظ الرحلة', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String currentDriverId = _auth.currentUser?.uid ?? '';

    return StreamBuilder<List<TripModel>>(
      stream: _tripService.getDriverTrips(currentDriverId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _calculateStats(snapshot.data!);
        }

        final List<Widget> pages = [
          _buildDashboardHome(isDark, context),
          _buildAICopilot(isDark),
          _buildWallet(isDark),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'DriveScope',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                onPressed: _logout,
              ),
            ],
          ),
          body: pages[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: isDark ? Colors.white : Colors.black,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'الرئيسية'),
              BottomNavigationBarItem(icon: Icon(Icons.psychology_outlined), label: 'AI Copilot'),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'المحفظة'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardHome(bool isDark, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'مرحباً بك كابتن 👋',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _auth.currentUser?.phoneNumber ?? '',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('رحلات اليوم', '$_todayTripsCount', isDark),
                Container(width: 1, height: 40, color: Colors.grey[400]),
                _buildStatItem('أرباح اليوم', '${_todayEarnings.toStringAsFixed(2)} ج.م', isDark),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddTripSheet(context),
            icon: const Icon(Icons.add_road_outlined),
            label: const Text('تسجيل رحلة مكتملة', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAICopilot(bool isDark) {
    final AICopilotService _copilotService = AICopilotService();
    final analysis = _copilotService.analyzeDriverPerformance(_allTrips);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, size: 36, color: isDark ? Colors.white : Colors.black),
              const SizedBox(width: 12),
              // تم تصحيح الـ FontWeight هنا لتجنب خطأ الـ .black القديم
              const Text('AI Copilot', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              children: [
                const Text('مؤشر كفاءة الأرباح الحالية', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 12),
                Text(
                  '${analysis['efficiencyScore']}%',
                  style: TextStyle(
                    fontSize: 48, 
                    fontWeight: FontWeight.w900, 
                    color: analysis['efficiencyScore'] > 70 ? Colors.green : Colors.orange
                  ),
                ),
                if (analysis['status'] == 'success') ...[
                  const SizedBox(height: 8),
                  Text(
                    'معدل الدخل الحقيقي: ${analysis['earningsPerKm'].toStringAsFixed(2)} ج.م / كم',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black12,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gavel_outlined, size: 20, color: isDark ? Colors.white : Colors.black),
                        const SizedBox(width: 8),
                        const Text('توجيهات الـ AI الفورية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(analysis['recommendation'], style: const TextStyle(fontSize: 14, height: 1.6)),
                    const SizedBox(height: 24),
                    if (analysis['status'] == 'success') ...[
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        // تم تصحيح الخصيصة هنا لتصبح spaceBetween بدلاً من between المسببة للخطأ
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('المنصة الأكثر ربحاً لك الآن:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white : Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              analysis['bestPlatform'],
                              style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWallet(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إجمالي صافي الرصيد المتوفر', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('${_totalWalletBalance.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
          const SizedBox(height: 32),
          Text('سجل الرحلات الحالية السحابي', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 16),
          Expanded(
            child: _allTrips.isEmpty
                ? Center(child: Text('لا توجد رحلات مسجلة بسحابة Firestore حتى الآن.', style: TextStyle(color: Colors.grey[400])))
                : ListView.builder(
                    itemCount: _allTrips.length,
                    itemBuilder: (context, index) {
                      final trip = _allTrips[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: Text(trip.platform[0], style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                          ),
                          title: Text('منصة ${trip.platform} - ${trip.distanceKm} كم'),
                          subtitle: Text('${trip.startTime.hour}:${trip.startTime.minute} - ${trip.startTime.day}/${trip.startTime.month}'),
                          trailing: Text(
                            '+${trip.netEarnings.toStringAsFixed(1)} ج.م',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, bool isDark) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
      ],
    );
  }
}