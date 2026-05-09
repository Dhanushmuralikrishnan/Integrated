import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EnergyApp());
}

class EnergyApp extends StatelessWidget {
  const EnergyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sudhan Yarns - Energy Management',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.light,
        useMaterial3: true,
        cardTheme: CardThemeData(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias),
        inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 20))),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
        useMaterial3: true,
        cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
        inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade800),
      ),
      themeMode: ThemeMode.system,
      initialRoute: "/splash",
      routes: {
        "/splash": (context) => const SplashScreen(),
        "/login": (context) => LoginScreen(toggleDarkMode: (bool) {}),
        "/home": (context) => const CompanySelectionScreen(),
        "/admin": (context) => const AdminScreen(),
      },
    );
  }
}

// ==================== SPLASH SCREEN (5 seconds) ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreenWrapper()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade800, Colors.green.shade400],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.energy_savings_leaf,
                    size: 80, color: Colors.white),
              ),
              const SizedBox(height: 30),
              const Text("Sudhan Yarns",
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 10),
              const Text("Energy Management System",
                  style: TextStyle(fontSize: 18, color: Colors.white70)),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              const SizedBox(height: 20),
              const Text("Loading...", style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== WRAPPER FOR LOGIN SCREEN ====================
class LoginScreenWrapper extends StatefulWidget {
  const LoginScreenWrapper({super.key});

  @override
  State<LoginScreenWrapper> createState() => _LoginScreenWrapperState();
}

class _LoginScreenWrapperState extends State<LoginScreenWrapper> {
  void toggleDarkMode(bool isDark) {}
  @override
  Widget build(BuildContext context) {
    return LoginScreen(toggleDarkMode: toggleDarkMode);
  }
}

// ==================== LOGIN SCREEN ====================
class LoginScreen extends StatefulWidget {
  final Function(bool) toggleDarkMode;
  const LoginScreen({super.key, required this.toggleDarkMode});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;
  final regNameCtrl = TextEditingController();
  final regEmailCtrl = TextEditingController();
  final regPassCtrl = TextEditingController();
  final regConfirmPassCtrl = TextEditingController();

  void showMessage(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4)));
  }

  Future<String> getRole(String uid) async {
    try {
      var doc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();
      return doc.data()?['role'] ?? "user";
    } catch (e) {
      return "user";
    }
  }

  void login() async {
    if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      showMessage("Enter email and password");
      return;
    }
    setState(() => isLoading = true);
    try {
      UserCredential user = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: emailCtrl.text.trim(), password: passCtrl.text.trim());
      String role = await getRole(user.user!.uid);
      if (!mounted) return;
      if (role == "admin") {
        Navigator.pushReplacementNamed(context, "/admin");
      } else {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => UserDashboardScreen(
                    toggleDarkMode: widget.toggleDarkMode)));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found')
        showMessage("No user found with this email");
      else if (e.code == 'wrong-password')
        showMessage("Wrong password");
      else if (e.code == 'invalid-email')
        showMessage("Invalid email format");
      else if (e.code == 'user-disabled')
        showMessage("This user account has been disabled");
      else
        showMessage("Login failed: ${e.message}");
    } catch (e) {
      showMessage("Error: $e\nCheck console for details");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showRegisterDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Create New Account"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: regNameCtrl,
                    decoration: const InputDecoration(labelText: "Full Name")),
                const SizedBox(height: 12),
                TextField(
                    controller: regEmailCtrl,
                    decoration: const InputDecoration(labelText: "Email"),
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                TextField(
                    controller: regPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password")),
                const SizedBox(height: 12),
                TextField(
                    controller: regConfirmPassCtrl,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: "Confirm Password")),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearRegistrationFields();
                },
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () => _register(context, setDialogState),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Register")),
          ],
        ),
      ),
    );
  }

  Future<void> _register(
      BuildContext context, StateSetter setDialogState) async {
    String name = regNameCtrl.text.trim();
    String email = regEmailCtrl.text.trim();
    String password = regPassCtrl.text.trim();
    String confirm = regConfirmPassCtrl.text.trim();
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showMessage("All fields required");
      return;
    }
    if (password != confirm) {
      showMessage("Passwords do not match");
      return;
    }
    if (password.length < 6) {
      showMessage("Password must be at least 6 characters");
      return;
    }

    setDialogState(() => isLoading = true);
    try {
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .set({
        'name': name,
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
      _clearRegistrationFields();
      showMessage("Account created! Please login.", isError: false);
      setState(() {
        emailCtrl.text = email;
        passCtrl.text = password;
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use')
        showMessage("Email already registered");
      else if (e.code == 'weak-password')
        showMessage("Weak password. Use at least 6 characters.");
      else
        showMessage("Registration failed: ${e.message}");
    } catch (e) {
      showMessage("Error: $e");
    } finally {
      setDialogState(() => isLoading = false);
    }
  }

  void _clearRegistrationFields() {
    regNameCtrl.clear();
    regEmailCtrl.clear();
    regPassCtrl.clear();
    regConfirmPassCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.green.shade800, Colors.green.shade400])),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle),
                        child: Icon(Icons.energy_savings_leaf,
                            size: 60, color: Colors.green.shade700)),
                    const SizedBox(height: 24),
                    const Text("Sudhan Yarns",
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    const Text("Energy Management System",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text("Login to your account",
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 16)),
                    const SizedBox(height: 32),
                    TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                            labelText: "Email", prefixIcon: Icon(Icons.email))),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passCtrl,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => obscurePassword = !obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text("Login",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text("Don't have an account?"),
                      TextButton(
                          onPressed: _showRegisterDialog,
                          child: const Text("Register",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ]),
                    const SizedBox(height: 8),
                    TextButton(
                        onPressed: () {
                          emailCtrl.text = "admin@energy.com";
                          passCtrl.text = "admin123";
                        },
                        child: const Text("Demo Credentials")),
                    const SizedBox(height: 16),
                    const Text("© Sudhan Yarns",
                        style: TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== DATA MODELS ====================
class CompanyData {
  final String name;
  CompanyData(this.name);
}

List<CompanyData> companies =
    List.generate(5, (i) => CompanyData("Company ${i + 1}"));

// ==================== USER DASHBOARD (NEW REPORT BUTTON AT TOP) ====================
class UserDashboardScreen extends StatefulWidget {
  final Function(bool) toggleDarkMode;
  const UserDashboardScreen({super.key, required this.toggleDarkMode});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  String _selectedCompany = companies.first.name;
  double _totalConsumption = 0, _totalCost = 0, _totalRenewable = 0;
  int _totalReports = 0;
  Map<String, double> _monthlyConsumption = {};
  bool _isDarkMode = false;
  List<Map<String, dynamic>> _cachedReports = [];

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadCache();
    _fetchData();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = prefs.getBool('darkMode') ?? false);
    widget.toggleDarkMode(_isDarkMode);
  }

  Future<void> _toggleTheme(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', val);
    setState(() => _isDarkMode = val);
    widget.toggleDarkMode(val);
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cached = prefs.getString('reportsCache');
    if (cached != null) {
      List<dynamic> list = jsonDecode(cached);
      setState(() => _cachedReports =
          list.map((e) => Map<String, dynamic>.from(e)).toList());
    }
  }

  Future<void> _saveCache(List<QueryDocumentSnapshot> docs) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> cacheList = [];
    for (var doc in docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      cacheList.add(data);
    }
    await prefs.setString('reportsCache', jsonEncode(cacheList));
    setState(() => _cachedReports = cacheList);
  }

  Future<void> _fetchData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('energy_data')
        .where('company', isEqualTo: _selectedCompany)
        .get();
    await _saveCache(snapshot.docs);
    double consumption = 0, cost = 0, renewable = 0;
    Map<String, double> monthly = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final ts = data['timestamp'] as Timestamp?;
      if (ts != null) {
        final date = ts.toDate();
        final monthKey = "${date.year}-${date.month}";
        monthly[monthKey] =
            (monthly[monthKey] ?? 0) + (data['consumption'] ?? 0);
      }
      consumption += data['consumption'] ?? 0;
      cost += data['finalAmount'] ?? 0;
      renewable += data['generation'] ?? 0;
    }
    setState(() {
      _totalConsumption = consumption;
      _totalCost = cost;
      _totalRenewable = renewable;
      _totalReports = snapshot.docs.length;
      _monthlyConsumption = monthly;
    });
  }

  void _changeCompany(String? newCompany) {
    if (newCompany != null && newCompany != _selectedCompany) {
      setState(() => _selectedCompany = newCompany);
      _fetchData();
    }
  }

  Future<void> _exportCSV() async {
    if (_cachedReports.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No data to export")));
      return;
    }
    String csv = "Company,Consumption,Generation,EB Used,Final Amount,Date\n";
    for (var report in _cachedReports) {
      csv +=
          "${report['company']},${report['consumption']},${report['generation']},${report['ebUsed']},${report['finalAmount']},${report['timestamp']}\n";
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File("${directory.path}/energy_data_export.csv");
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: "Energy Data Export");
  }

  @override
  Widget build(BuildContext context) {
    final renewablePercent =
        _totalConsumption > 0 ? (_totalRenewable / _totalConsumption) * 100 : 0;
    final avgCost = _totalConsumption > 0 ? _totalCost / _totalConsumption : 0;
    final estimatedSavings = _totalRenewable * 7;

    final List<Map<String, dynamic>> stats = [
      {
        "title": "Total Consumption",
        "value": "${_totalConsumption.toStringAsFixed(2)} kWh",
        "icon": Icons.electric_bolt,
        "color": Colors.blue
      },
      {
        "title": "Total Cost",
        "value": "₹${_totalCost.toStringAsFixed(2)}",
        "icon": Icons.currency_rupee,
        "color": Colors.green
      },
      {
        "title": "Average Cost/Unit",
        "value": "₹${avgCost.toStringAsFixed(2)}",
        "icon": Icons.trending_up,
        "color": Colors.orange
      },
      {
        "title": "Renewable %",
        "value": "${renewablePercent.toStringAsFixed(1)}%",
        "icon": Icons.energy_savings_leaf,
        "color": Colors.teal
      },
      {
        "title": "Total Reports",
        "value": "$_totalReports",
        "icon": Icons.description,
        "color": Colors.purple
      },
      {
        "title": "Est. Savings",
        "value": "₹${estimatedSavings.toStringAsFixed(2)}",
        "icon": Icons.savings,
        "color": Colors.pink
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sudhan Yarns · Energy Dashboard"),
        backgroundColor: Colors.green,
        centerTitle: true,
        elevation: 0,
        actions: [
          Switch(value: _isDarkMode, onChanged: _toggleTheme),
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) Navigator.pushReplacementNamed(context, "/login");
              }),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
                decoration: BoxDecoration(color: Colors.green),
                child: Text("Energy Management",
                    style: TextStyle(color: Colors.white, fontSize: 24))),
            ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text("Dashboard"),
                onTap: () => Navigator.pop(context)),
            ListTile(
                leading: const Icon(Icons.add_chart),
                title: const Text("New Report"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CompanySelectionScreen()));
                }),
            ListTile(
                leading: const Icon(Icons.history),
                title: const Text("History"),
                onTap: () {
                  Navigator.pop(context);
                  final company = CompanyData(_selectedCompany);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => HistoryScreen(company: company)));
                }),
            ListTile(
                leading: const Icon(Icons.download),
                title: const Text("Export CSV"),
                onTap: () {
                  Navigator.pop(context);
                  _exportCSV();
                }),
            ListTile(
                leading: const Icon(Icons.functions),
                title: const Text("Math Notes"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MathNotesScreen()));
                }),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: Container(
          decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: [Colors.green.shade50, Colors.white])),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company selector card
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCompany,
                      decoration: const InputDecoration(
                          labelText: "Select Company",
                          border: InputBorder.none),
                      items: companies
                          .map((c) => DropdownMenuItem(
                              value: c.name, child: Text(c.name)))
                          .toList(),
                      onChanged: _changeCompany,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // NEW REPORT BUTTON (now at the top)
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CompanySelectionScreen())),
                  icon: const Icon(Icons.add_chart),
                  label: const Text("New Report"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 20),

                // Key Statistics
                const Text("Key Statistics",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stats.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = stats[index];
                      return ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (item["color"] as Color).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item["icon"] as IconData,
                              color: item["color"] as Color, size: 24),
                        ),
                        title: Text(item["title"] as String,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: Text(item["value"] as String,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: item["color"] as Color)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Monthly Consumption Trend
                const Text("Monthly Consumption Trend",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (_monthlyConsumption.isNotEmpty)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        height: 240,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _monthlyConsumption.values
                                .reduce((a, b) => a > b ? a : b),
                            barGroups: _monthlyConsumption.entries
                                .toList()
                                .asMap()
                                .entries
                                .map((e) => BarChartGroupData(
                                      x: e.key,
                                      barRods: [
                                        BarChartRodData(
                                            toY: e.value.value,
                                            color: Colors.green,
                                            width: 30,
                                            borderRadius:
                                                BorderRadius.circular(8))
                                      ],
                                    ))
                                .toList(),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final keys =
                                            _monthlyConsumption.keys.toList();
                                        if (value.toInt() < keys.length)
                                          return Text(keys[value.toInt()],
                                              style: const TextStyle(
                                                  fontSize: 12));
                                        return const Text("");
                                      })),
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: true)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const Card(
                      child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text("No data available for chart"))),
                const SizedBox(height: 24),

                // History and Export CSV buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => HistoryScreen(
                                    company: CompanyData(_selectedCompany)))),
                        icon: const Icon(Icons.history),
                        label: const Text("History"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _exportCSV,
                        icon: const Icon(Icons.download),
                        label: const Text("Export CSV"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== COMPANY SELECTION SCREEN ====================
class CompanySelectionScreen extends StatelessWidget {
  const CompanySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Company"),
        backgroundColor: Colors.green,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.functions),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MathNotesScreen())))
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
            gradient:
                LinearGradient(colors: [Colors.green.shade50, Colors.white])),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: companies.length,
          itemBuilder: (context, index) => Card(
            elevation: 6,
            margin: const EdgeInsets.only(bottom: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.business,
                      color: Colors.green.shade700, size: 28)),
              title: Text(companies[index].name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
              trailing:
                  Icon(Icons.arrow_forward_ios, color: Colors.green.shade700),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          EnergyHomePage(company: companies[index]))),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== PDF GENERATION SERVICE ====================
class ReportService {
  Future<void> generateAndSharePDFReport({
    required String company,
    required double consumption,
    required double generation,
    required double balance,
    required String source,
    required double ebUsed,
    required double surplus,
    required double totalCost,
    required double demandCharge,
    required double finalAmount,
    required double bankedPower,
    required double currentPower,
    required double renewablePercent,
    required double avgCost,
  }) async {
    final pdfDoc = pw.Document();
    final now = DateTime.now();

    pdfDoc.addPage(pw.Page(
      pageFormat: pdf.PdfPageFormat.a4,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
                color: pdf.PdfColors.green,
                borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Column(
              children: [
                pw.Text("ENERGY MANAGEMENT REPORT",
                    style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: pdf.PdfColors.white)),
                pw.SizedBox(height: 8),
                pw.Text("Generated by Energy Management System",
                    style:
                        pw.TextStyle(fontSize: 12, color: pdf.PdfColors.white)),
                pw.Text("Date: ${now.day}/${now.month}/${now.year}",
                    style:
                        pw.TextStyle(fontSize: 12, color: pdf.PdfColors.white)),
                pw.Text("Organization: Sudhan Yarns",
                    style:
                        pw.TextStyle(fontSize: 12, color: pdf.PdfColors.white)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
                border: pw.Border.all(color: pdf.PdfColors.grey),
                borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Column(children: [
              _infoRow("Company Name", company),
              _infoRow("Report Type", "Energy Consumption Analysis"),
              _infoRow("Source Type", source),
            ]),
          ),
          pw.SizedBox(height: 20),
          _sectionHeader("ENERGY STATISTICS"),
          _infoRow(
              "Total Consumption", "${consumption.toStringAsFixed(2)} kWh"),
          _infoRow("Total Generation", "${generation.toStringAsFixed(2)} kWh"),
          _infoRow("Energy Balance", "${balance.toStringAsFixed(2)} kWh"),
          _infoRow("Grid Power Used (EB)", "${ebUsed.toStringAsFixed(2)} kWh"),
          _infoRow("Surplus Power", "${surplus.toStringAsFixed(2)} kWh"),
          _infoRow("Renewable Percentage",
              "${renewablePercent.toStringAsFixed(2)}%"),
          pw.SizedBox(height: 16),
          _sectionHeader("FINANCIAL SUMMARY"),
          _infoRow("Energy Cost (EB)", "₹${totalCost.toStringAsFixed(2)}"),
          _infoRow("Demand Charge", "₹${demandCharge.toStringAsFixed(2)}"),
          _infoRow("Total Amount", "₹${finalAmount.toStringAsFixed(2)}"),
          _infoRow("Average Cost per Unit", "₹${avgCost.toStringAsFixed(2)}"),
          pw.SizedBox(height: 16),
          _sectionHeader("ENERGY BANKING"),
          _infoRow("Banked Power", "${bankedPower.toStringAsFixed(2)} kWh"),
          _infoRow("Current Available Power",
              "${currentPower.toStringAsFixed(2)} kWh"),
          pw.SizedBox(height: 16),
          _sectionHeader("DETAILED BREAKDOWN"),
          pw.Table(border: pw.TableBorder.all(), children: [
            _tableRow("Consumption", consumption),
            _tableRow("Generation", generation),
            _tableRow("Balance", balance),
            _tableRow("EB Used", ebUsed),
            _tableRow("Surplus", surplus),
            _tableRow("EB Cost", totalCost),
            _tableRow("Demand Charge", demandCharge),
            _tableRow("Average Cost", avgCost),
            _tableRow("Final Amount", finalAmount),
            _tableRow("Banked Power", bankedPower),
            _tableRow("Current Power", currentPower),
            _tableRow("Renewable %", renewablePercent),
          ]),
          pw.SizedBox(height: 30),
          _sectionHeader("RECOMMENDATIONS"),
          ..._getRecommendations(renewablePercent, consumption, generation),
          pw.SizedBox(height: 30),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 10),
          pw.Text(
              "This report is system generated and does not require signature",
              style: pw.TextStyle(fontSize: 10, color: pdf.PdfColors.grey),
              textAlign: pw.TextAlign.center),
          pw.Text("Sudhan Yarns - Energy Management System © ${now.year}",
              style: pw.TextStyle(fontSize: 10, color: pdf.PdfColors.grey),
              textAlign: pw.TextAlign.center),
        ],
      ),
    ));

    await Printing.layoutPdf(onLayout: (format) => pdfDoc.save());
  }

  pw.Widget _sectionHeader(String title) => pw.Column(children: [
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: pdf.PdfColors.green)),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 8),
      ]);

  pw.Widget _infoRow(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text(value, style: const pw.TextStyle(fontSize: 12))
          ]));

  pw.TableRow _tableRow(String title, double value) => pw.TableRow(children: [
        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(title)),
        pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(value.toStringAsFixed(2),
                textAlign: pw.TextAlign.right))
      ]);

  List<pw.Widget> _getRecommendations(
      double rp, double consumption, double generation) {
    List<pw.Widget> rec = [];
    if (rp < 30) {
      rec.add(pw.Text("• Consider increasing renewable energy sources",
          style: const pw.TextStyle(fontSize: 11)));
      rec.add(pw.SizedBox(height: 5));
      rec.add(pw.Text("• Install additional solar panels or wind turbines",
          style: const pw.TextStyle(fontSize: 11)));
    } else if (rp < 60) {
      rec.add(pw.Text("• Good job on renewable adoption! Continue optimizing",
          style: const pw.TextStyle(fontSize: 11)));
      rec.add(pw.SizedBox(height: 5));
      rec.add(pw.Text("• Consider battery storage for excess renewable energy",
          style: const pw.TextStyle(fontSize: 11)));
    } else {
      rec.add(pw.Text("• Excellent renewable energy utilization!",
          style: const pw.TextStyle(fontSize: 11)));
      rec.add(pw.SizedBox(height: 5));
      rec.add(pw.Text("• Share your best practices with other departments",
          style: const pw.TextStyle(fontSize: 11)));
    }
    if (consumption > generation) {
      rec.add(pw.SizedBox(height: 5));
      rec.add(pw.Text(
          "• Energy consumption exceeds generation. Focus on conservation",
          style: const pw.TextStyle(fontSize: 11)));
    } else {
      rec.add(pw.SizedBox(height: 5));
      rec.add(pw.Text(
          "• You're generating surplus energy. Consider selling back to the grid",
          style: const pw.TextStyle(fontSize: 11)));
    }
    return rec;
  }
}

// ==================== ENERGY INPUT PAGE ====================
class EnergyHomePage extends StatefulWidget {
  final CompanyData company;
  const EnergyHomePage({super.key, required this.company});

  @override
  State<EnergyHomePage> createState() => _EnergyHomePageState();
}

class _EnergyHomePageState extends State<EnergyHomePage> {
  final c1 = TextEditingController();
  final c2 = TextEditingController();
  final c3 = TextEditingController();
  final c4 = TextEditingController();
  final c5 = TextEditingController();
  final solar = TextEditingController();
  final wind = TextEditingController();
  final sanctionedCtrl = TextEditingController();
  final maxDemandCtrl = TextEditingController();
  String selectedSource = "EB";

  double consumption = 0, generation = 0, balance = 0, ebUsed = 0, surplus = 0;
  double totalCost = 0, demandCharge = 0, avgCost = 0, finalAmount = 0;
  double renewablePercent = 0, bankedPower = 0, currentPower = 0;
  double _storedBank = 0;

  @override
  void initState() {
    super.initState();
    _loadBankedPower();
  }

  Future<void> _loadBankedPower() async {
    final doc = await FirebaseFirestore.instance
        .collection('company_bank')
        .doc(widget.company.name)
        .get();
    setState(() => _storedBank = doc.data()?['bankedPower'] ?? 0);
  }

  Future<void> _saveBankedPower(double newBank) async {
    await FirebaseFirestore.instance
        .collection('company_bank')
        .doc(widget.company.name)
        .set({
      'bankedPower': newBank,
      'updatedAt': FieldValue.serverTimestamp()
    });
  }

  void showError(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  double calculateEB(double units) {
    if (units <= 100) return 0;
    if (units <= 200) return (units - 100) * 2;
    if (units <= 500) return 200 + (units - 200) * 5;
    return 200 + 1500 + (units - 500) * 7;
  }

  double calculateDemand(double sd, double md) {
    if (sd == 0) return 0;
    double percent = (md / sd) * 100;
    if (percent >= 90) return 0;
    double unused = (sd * 0.9) - md;
    return unused < 0 ? 0 : unused * 600;
  }

  bool validateInputs() {
    List<TextEditingController> fields = [
      c1,
      c2,
      c3,
      c4,
      c5,
      sanctionedCtrl,
      maxDemandCtrl
    ];
    for (var f in fields)
      if (f.text.trim().isEmpty) {
        showError("All fields required");
        return false;
      }
    for (var f in fields)
      if (double.tryParse(f.text) == null) {
        showError("Enter valid numbers");
        return false;
      }
    for (var f in fields)
      if ((double.tryParse(f.text) ?? 0) < 0) {
        showError("No negative values");
        return false;
      }
    double sd = double.parse(sanctionedCtrl.text),
        md = double.parse(maxDemandCtrl.text);
    if (md > sd) {
      showError("Max Demand cannot exceed Sanctioned Demand");
      return false;
    }
    if (selectedSource == "Solar" && (double.tryParse(solar.text) ?? 0) == 0) {
      showError("Enter Solar value");
      return false;
    }
    if (selectedSource == "Wind" && (double.tryParse(wind.text) ?? 0) == 0) {
      showError("Enter Wind value");
      return false;
    }
    return true;
  }

  void calculate() {
    consumption = (double.tryParse(c1.text) ?? 0) +
        (double.tryParse(c2.text) ?? 0) +
        (double.tryParse(c3.text) ?? 0) +
        (double.tryParse(c4.text) ?? 0) +
        (double.tryParse(c5.text) ?? 0);
    generation = (selectedSource == "EB")
        ? 0
        : (selectedSource == "Solar")
            ? (double.tryParse(solar.text) ?? 0)
            : (selectedSource == "Wind")
                ? (double.tryParse(wind.text) ?? 0)
                : (double.tryParse(solar.text) ?? 0) +
                    (double.tryParse(wind.text) ?? 0);

    double bankLossFactor = 0.9;
    double initialBank = _storedBank;
    double newBank = initialBank;

    if (generation >= consumption) {
      ebUsed = 0;
      surplus = generation - consumption;
      newBank = initialBank + surplus;
      currentPower = generation;
    } else {
      double deficit = consumption - generation;
      surplus = 0;
      currentPower = generation;
      double usableFromBank = initialBank * bankLossFactor;
      if (usableFromBank >= deficit) {
        ebUsed = 0;
        newBank = initialBank - (deficit / bankLossFactor);
      } else {
        ebUsed = deficit - usableFromBank;
        newBank = 0;
      }
    }

    newBank = newBank < 0 ? 0 : newBank;
    ebUsed = ebUsed < 0 ? 0 : ebUsed;
    surplus = surplus < 0 ? 0 : surplus;
    bankedPower = newBank;
    _storedBank = newBank;
    _saveBankedPower(newBank);

    totalCost = calculateEB(ebUsed);
    double sd = double.parse(sanctionedCtrl.text);
    double md = double.parse(maxDemandCtrl.text);
    demandCharge = calculateDemand(sd, md);
    finalAmount = totalCost + demandCharge;

    double renewableContribution =
        generation - (ebUsed > 0 ? 0 : (generation - consumption));
    renewablePercent =
        consumption > 0 ? (renewableContribution / consumption) * 100 : 0;
    avgCost = consumption > 0 ? finalAmount / consumption : 0;
    balance = (generation + (initialBank * bankLossFactor)) - consumption;
  }

  void calculateAndNavigate() {
    if (!validateInputs()) return;
    calculate();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ResultPage(
                  company: widget.company.name,
                  consumption: consumption,
                  generation: generation,
                  balance: balance,
                  source: selectedSource,
                  ebUsed: ebUsed,
                  surplus: surplus,
                  totalCost: totalCost,
                  demandCharge: demandCharge,
                  finalAmount: finalAmount,
                  bankedPower: bankedPower,
                  currentPower: currentPower,
                  renewablePercent: renewablePercent,
                  avgCost: avgCost,
                )));
  }

  Widget inputBox(String label, TextEditingController controller,
          {bool enabled = true}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.black, fontSize: 16),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.black54),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.company.name),
          backgroundColor: Colors.green,
          centerTitle: true,
          elevation: 0),
      body: Container(
        decoration: BoxDecoration(
            gradient:
                LinearGradient(colors: [Colors.green.shade50, Colors.white])),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Energy Input",
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.green))),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String>(
                  value: selectedSource,
                  decoration: InputDecoration(
                      labelText: "Power Source Type",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white),
                  items: ["EB", "Solar", "Wind", "Hybrid"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedSource = v!;
                      if (selectedSource == "Solar")
                        wind.clear();
                      else if (selectedSource == "Wind")
                        solar.clear();
                      else if (selectedSource == "EB") {
                        solar.clear();
                        wind.clear();
                      }
                    });
                  },
                ),
              ),
              inputBox("Line 1 Consumption (kWh)", c1),
              inputBox("Line 2 Consumption (kWh)", c2),
              inputBox("Line 3 Consumption (kWh)", c3),
              inputBox("Line 4 Consumption (kWh)", c4),
              inputBox("Line 5 Consumption (kWh)", c5),
              inputBox("Solar Generation (kWh)", solar,
                  enabled:
                      selectedSource == "Solar" || selectedSource == "Hybrid"),
              inputBox("Wind Generation (kWh)", wind,
                  enabled:
                      selectedSource == "Wind" || selectedSource == "Hybrid"),
              inputBox("Sanctioned Demand (kVA)", sanctionedCtrl),
              inputBox("Max Demand (kVA)", maxDemandCtrl),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: calculateAndNavigate,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text("Calculate",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                        child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                c1.clear();
                                c2.clear();
                                c3.clear();
                                c4.clear();
                                c5.clear();
                                solar.clear();
                                wind.clear();
                                sanctionedCtrl.clear();
                                maxDemandCtrl.clear();
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text("Reset"),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const CompanySelectionScreen())),
                            icon: const Icon(Icons.home),
                            label: const Text("Home"),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => HistoryScreen(
                                        company: widget.company))),
                            icon: const Icon(Icons.history),
                            label: const Text("History"),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== RESULT PAGE ====================
class ResultPage extends StatelessWidget {
  final String company;
  final double consumption, generation, balance, ebUsed, surplus;
  final double totalCost, demandCharge, finalAmount, bankedPower, currentPower;
  final double renewablePercent, avgCost;
  final String source;

  const ResultPage(
      {super.key,
      required this.company,
      required this.consumption,
      required this.generation,
      required this.balance,
      required this.source,
      required this.ebUsed,
      required this.surplus,
      required this.totalCost,
      required this.demandCharge,
      required this.finalAmount,
      required this.bankedPower,
      required this.currentPower,
      required this.renewablePercent,
      required this.avgCost});

  void _saveData(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('energy_data').add({
        'company': company,
        'consumption': consumption,
        'generation': generation,
        'balance': balance,
        'ebUsed': ebUsed,
        'surplus': surplus,
        'totalCost': totalCost,
        'demandCharge': demandCharge,
        'finalAmount': finalAmount,
        'bankedPower': bankedPower,
        'currentPower': currentPower,
        'renewablePercent': renewablePercent,
        'source': source,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Report saved"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  void _sharePDF(BuildContext context) async {
    try {
      final service = ReportService();
      await service.generateAndSharePDFReport(
        company: company,
        consumption: consumption,
        generation: generation,
        balance: balance,
        source: source,
        ebUsed: ebUsed,
        surplus: surplus,
        totalCost: totalCost,
        demandCharge: demandCharge,
        finalAmount: finalAmount,
        bankedPower: bankedPower,
        currentPower: currentPower,
        renewablePercent: renewablePercent,
        avgCost: avgCost,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("PDF error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    double total = ebUsed + generation;
    double renewPercent = total > 0 ? (generation / total) * 100 : 0;
    double gridPercent = total > 0 ? (ebUsed / total) * 100 : 0;

    final sections = [
      PieChartSectionData(
        value: generation,
        title: "${renewPercent.toStringAsFixed(1)}%",
        color: Colors.green.shade600,
        radius: 70,
        titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(blurRadius: 3, color: Colors.black26, offset: Offset(1, 1))
            ]),
      ),
      PieChartSectionData(
        value: ebUsed,
        title: "${gridPercent.toStringAsFixed(1)}%",
        color: Colors.red.shade500,
        radius: 70,
        titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(blurRadius: 3, color: Colors.black26, offset: Offset(1, 1))
            ]),
      ),
    ];

    final List<Map<String, dynamic>> resultItems = [
      {
        "title": "Consumption",
        "value": "${consumption.toStringAsFixed(2)} kWh",
        "icon": Icons.electric_bolt,
        "color": Colors.blue
      },
      {
        "title": "Generation",
        "value": "${generation.toStringAsFixed(2)} kWh",
        "icon": Icons.solar_power,
        "color": Colors.green
      },
      {
        "title": "Balance",
        "value": "${balance.toStringAsFixed(2)} kWh",
        "icon": Icons.compare_arrows,
        "color": Colors.orange
      },
      {
        "title": "EB Used",
        "value": "${ebUsed.toStringAsFixed(2)} kWh",
        "icon": Icons.power,
        "color": Colors.red
      },
      {
        "title": "Surplus",
        "value": "${surplus.toStringAsFixed(2)} kWh",
        "icon": Icons.arrow_upward,
        "color": Colors.teal
      },
      {
        "title": "Total Cost",
        "value": "₹${totalCost.toStringAsFixed(2)}",
        "icon": Icons.currency_rupee,
        "color": Colors.purple
      },
      {
        "title": "Demand Charge",
        "value": "₹${demandCharge.toStringAsFixed(2)}",
        "icon": Icons.trending_up,
        "color": Colors.brown
      },
      {
        "title": "Final Amount",
        "value": "₹${finalAmount.toStringAsFixed(2)}",
        "icon": Icons.payments,
        "color": Colors.green.shade700
      },
      {
        "title": "Banked Power",
        "value": "${bankedPower.toStringAsFixed(2)} kWh",
        "icon": Icons.battery_full,
        "color": Colors.indigo
      },
      {
        "title": "Current Power",
        "value": "${currentPower.toStringAsFixed(2)} kWh",
        "icon": Icons.flash_on,
        "color": Colors.cyan
      },
      {
        "title": "Renewable %",
        "value": "${renewablePercent.toStringAsFixed(2)}%",
        "icon": Icons.energy_savings_leaf,
        "color": Colors.teal
      },
      {
        "title": "Avg Cost/Unit",
        "value": "₹${avgCost.toStringAsFixed(2)}",
        "icon": Icons.calculate,
        "color": Colors.pink
      },
    ];

    return Scaffold(
      appBar: AppBar(
          title: const Text("Energy Report"),
          backgroundColor: Colors.green,
          centerTitle: true,
          elevation: 0),
      body: Container(
        decoration: BoxDecoration(
            gradient:
                LinearGradient(colors: [Colors.green.shade50, Colors.white])),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: ListTile(
                      leading: const Icon(Icons.business, size: 40),
                      title: Text("Company: $company",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: Text("Source: $source"))),
              const SizedBox(height: 20),
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text("Energy Mix",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: sections,
                            sectionsSpace: 3,
                            centerSpaceRadius: 40,
                            startDegreeOffset: -90,
                            pieTouchData: PieTouchData(enabled: false),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legend(
                              "Renewable", Colors.green.shade600, textColor),
                          const SizedBox(width: 32),
                          _legend("Grid (EB)", Colors.red.shade500, textColor),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Renewable: ${generation.toStringAsFixed(2)} kWh   |   Grid: ${ebUsed.toStringAsFixed(2)} kWh",
                        style: TextStyle(fontSize: 13, color: textColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text("Detailed Results",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: resultItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = resultItems[index];
                    return ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (item["color"] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item["icon"] as IconData,
                            color: item["color"] as Color, size: 24),
                      ),
                      title: Text(item["title"] as String,
                          style: TextStyle(
                              fontWeight: FontWeight.w500, color: textColor)),
                      trailing: Text(item["value"] as String,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: ElevatedButton.icon(
                          onPressed: () => _saveData(context),
                          icon: const Icon(Icons.save),
                          label: const Text("Save Report"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14)))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: ElevatedButton.icon(
                          onPressed: () => _sharePDF(context),
                          icon: const Icon(Icons.share),
                          label: const Text("Share PDF"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14)))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text("Back"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14)))),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legend(String label, Color color, Color textColor) {
    return Row(
      children: [
        Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)])),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
      ],
    );
  }
}

// ==================== HISTORY SCREEN ====================
class HistoryScreen extends StatefulWidget {
  final CompanyData company;
  const HistoryScreen({super.key, required this.company});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String selectedFilter = "All";
  DateTime? startDate, endDate;

  bool checkFilter(DateTime date) {
    final now = DateTime.now();
    if (selectedFilter == "Today")
      return date.day == now.day &&
          date.month == now.month &&
          date.year == now.year;
    if (selectedFilter == "This Month")
      return date.month == now.month && date.year == now.year;
    if (selectedFilter == "This Year") return date.year == now.year;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("${widget.company.name} History"),
          backgroundColor: Colors.green,
          centerTitle: true,
          elevation: 0),
      body: Container(
        decoration: BoxDecoration(
            gradient:
                LinearGradient(colors: [Colors.green.shade50, Colors.white])),
        child: Column(
          children: [
            Container(
                padding: const EdgeInsets.all(16),
                color: Colors.green.shade50,
                child: Column(
                  children: [
                    DropdownButton<String>(
                        value: selectedFilter,
                        isExpanded: true,
                        items: ["All", "Today", "This Month", "This Year"]
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => selectedFilter = v!)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: ElevatedButton.icon(
                              onPressed: () async {
                                DateTime? p = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now());
                                if (p != null) setState(() => startDate = p);
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(startDate == null
                                  ? "Start Date"
                                  : "${startDate!.day}/${startDate!.month}/${startDate!.year}"))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: ElevatedButton.icon(
                              onPressed: () async {
                                DateTime? p = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now());
                                if (p != null) setState(() => endDate = p);
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(endDate == null
                                  ? "End Date"
                                  : "${endDate!.day}/${endDate!.month}/${endDate!.year}"))),
                    ]),
                  ],
                )),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('energy_data')
                    .where('company', isEqualTo: widget.company.name)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return const Center(child: Text("No Data Found"));
                  var filtered = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    DateTime date = (data['timestamp'] as Timestamp).toDate();
                    if (startDate != null && endDate != null)
                      return date.isAfter(
                              startDate!.subtract(const Duration(days: 1))) &&
                          date.isBefore(endDate!.add(const Duration(days: 1)));
                    return checkFilter(date);
                  }).toList();
                  double totalConsumption = 0, totalCost = 0, totalDemand = 0;
                  for (var doc in filtered) {
                    var d = doc.data() as Map<String, dynamic>;
                    totalConsumption += d['consumption'] ?? 0;
                    totalCost += d['finalAmount'] ?? 0;
                    totalDemand += d['demandCharge'] ?? 0;
                  }
                  double avgCost =
                      totalConsumption > 0 ? totalCost / totalConsumption : 0;
                  return Column(
                    children: [
                      Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.blue.shade50,
                          child: Row(children: [
                            Expanded(
                                child: _summaryCard("Total Units",
                                    totalConsumption, Colors.blue)),
                            Expanded(
                                child: _summaryCard(
                                    "Total Cost", totalCost, Colors.green)),
                            Expanded(
                                child: _summaryCard(
                                    "Avg Cost", avgCost, Colors.orange)),
                            Expanded(
                                child: _summaryCard(
                                    "Demand Charge", totalDemand, Colors.red)),
                          ])),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            var item =
                                filtered[index].data() as Map<String, dynamic>;
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: ExpansionTile(
                                leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: const Icon(Icons.receipt,
                                        color: Colors.green)),
                                title: Text(item['company'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    "Date: ${(item['timestamp'] as Timestamp).toDate().day}/${(item['timestamp'] as Timestamp).toDate().month}/${(item['timestamp'] as Timestamp).toDate().year}"),
                                children: [
                                  Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _detailRow("Consumption",
                                                "${item['consumption']} kWh"),
                                            _detailRow("Generation",
                                                "${item['generation']} kWh"),
                                            _detailRow("Final Amount",
                                                "₹${item['finalAmount']}"),
                                            _detailRow("Banked",
                                                "${item['bankedPower']} kWh"),
                                            _detailRow("Renewable %",
                                                "${item['renewablePercent']?.toStringAsFixed(2)}%"),
                                            _detailRow("Demand Charge",
                                                "₹${item['demandCharge']}"),
                                            _detailRow("Source",
                                                item['source'] ?? 'N/A'),
                                          ])),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, double value, Color color) => Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value.toStringAsFixed(2),
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color))
          ])));
  Widget _detailRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        Text(value, style: const TextStyle(fontSize: 14))
      ]));
}

// ==================== ADMIN SCREEN ====================
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sudhan Yarns · Admin"),
        backgroundColor: Colors.green,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.add_chart),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CompanySelectionScreen())),
              tooltip: "New Report"),
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: "Logout"),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
            gradient:
                LinearGradient(colors: [Colors.green.shade50, Colors.white])),
        child: _selectedIndex == 0
            ? _buildOverview()
            : (_selectedIndex == 1
                ? _buildCompanies()
                : (_selectedIndex == 2 ? _buildUsers() : _buildReports())),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.green,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: "Overview"),
          BottomNavigationBarItem(
              icon: Icon(Icons.business), label: "Companies"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Reports"),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('energy_data').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        double totalConsumption = 0, totalCost = 0, totalGeneration = 0;
        for (var doc in snapshot.data!.docs) {
          var d = doc.data() as Map<String, dynamic>;
          totalConsumption += d['consumption'] ?? 0;
          totalCost += d['finalAmount'] ?? 0;
          totalGeneration += d['generation'] ?? 0;
        }
        double avgCost =
            totalConsumption > 0 ? totalCost / totalConsumption : 0;
        double renewPercent = totalConsumption > 0
            ? (totalGeneration / totalConsumption) * 100
            : 0;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _statCard(
                      "Total Consumption",
                      "${totalConsumption.toStringAsFixed(2)} kWh",
                      Icons.electric_bolt,
                      Colors.blue),
                  _statCard(
                      "Total Generation",
                      "${totalGeneration.toStringAsFixed(2)} kWh",
                      Icons.solar_power,
                      Colors.green),
                  _statCard("Total Cost", "₹${totalCost.toStringAsFixed(2)}",
                      Icons.currency_rupee, Colors.orange),
                  _statCard("Avg Cost/Unit", "₹${avgCost.toStringAsFixed(2)}",
                      Icons.trending_up, Colors.purple),
                  _statCard(
                      "Renewable %",
                      "${renewPercent.toStringAsFixed(1)}%",
                      Icons.energy_savings_leaf,
                      Colors.teal),
                  _statCard("Total Reports", "${snapshot.data!.docs.length}",
                      Icons.description, Colors.red),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) =>
      Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 12),
              Text(value,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _buildCompanies() => Column(
        children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                  onPressed: _addCompany,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Company"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14)))),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('companies').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        title: Text(data['name'],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => doc.reference.delete()),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );

  void _addCompany() async {
    TextEditingController c = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Company"),
        content: TextField(
            controller: c,
            decoration: const InputDecoration(labelText: "Company Name")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () async {
                await _firestore.collection('companies').add({
                  'name': c.text,
                  'createdAt': FieldValue.serverTimestamp()
                });
                Navigator.pop(context);
              },
              child: const Text("Add")),
        ],
      ),
    );
  }

  Widget _buildUsers() => StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(data['email'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Role: ${data['role']}"),
                  trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => doc.reference.delete()),
                ),
              );
            },
          );
        },
      );

  Widget _buildReports() => StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('energy_data')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(data['company'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Final Amount: ₹${data['finalAmount']}"),
                  trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => doc.reference.delete()),
                ),
              );
            },
          );
        },
      );

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, "/login");
  }
}

// ==================== MATH NOTES (INTEGRAL CALCULATOR) ====================
class MathNotesScreen extends StatefulWidget {
  const MathNotesScreen({super.key});

  @override
  State<MathNotesScreen> createState() => _MathNotesScreenState();
}

class _MathNotesScreenState extends State<MathNotesScreen> {
  final _aController = TextEditingController(text: "0");
  final _bController = TextEditingController(text: "2");
  final _nController = TextEditingController(text: "1000");
  String _function = "x^2";
  double _result = 0.0;
  String _expression = "x²";

  void _computeIntegral() {
    double a = double.tryParse(_aController.text) ?? 0;
    double b = double.tryParse(_bController.text) ?? 0;
    int n = int.tryParse(_nController.text) ?? 1000;
    double h = (b - a) / n;
    double sum = 0.0;
    for (int i = 0; i <= n; i++) {
      double x = a + i * h;
      double fx;
      switch (_function) {
        case "x^2":
          fx = x * x;
          _expression = "x²";
          break;
        case "x^3":
          fx = x * x * x;
          _expression = "x³";
          break;
        case "sin(x)":
          fx = sin(x);
          _expression = "sin(x)";
          break;
        case "cos(x)":
          fx = cos(x);
          _expression = "cos(x)";
          break;
        case "e^x":
          fx = exp(x);
          _expression = "eˣ";
          break;
        default:
          fx = x * x;
      }
      if (i == 0 || i == n)
        sum += fx;
      else if (i % 2 == 0)
        sum += 2 * fx;
      else
        sum += 4 * fx;
    }
    _result = (h / 3) * sum;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Math Notes - Integral Calculator"),
          backgroundColor: Colors.green,
          centerTitle: true,
          elevation: 0),
      body: Container(
        decoration: BoxDecoration(
            gradient:
                LinearGradient(colors: [Colors.green.shade50, Colors.white])),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text("Numerical Integration (Simpson's Rule)",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _function,
                        decoration: const InputDecoration(
                            labelText: "Function f(x)",
                            border: OutlineInputBorder()),
                        items: ["x^2", "x^3", "sin(x)", "cos(x)", "e^x"]
                            .map((f) =>
                                DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _function = v!);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: TextField(
                                  controller: _aController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: "Lower limit a"))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: TextField(
                                  controller: _bController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: "Upper limit b"))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                          controller: _nController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: "Number of subintervals (even)")),
                      const SizedBox(height: 20),
                      ElevatedButton(
                          onPressed: _computeIntegral,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size(double.infinity, 48)),
                          child: const Text("Compute Integral",
                              style: TextStyle(fontSize: 16))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text("Result",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                          "∫ $_expression dx from ${_aController.text} to ${_bController.text}",
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      Text("≈ ${_result.toStringAsFixed(6)}",
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
