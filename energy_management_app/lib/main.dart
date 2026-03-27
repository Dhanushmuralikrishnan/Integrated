import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'package:fl_chart/fl_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const EnergyApp());
}

class EnergyApp extends StatelessWidget {
  const EnergyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

// ---------------- COMPANY ----------------

class CompanyData {
  String name;
  CompanyData(this.name);
}

List<CompanyData> companies = [
  CompanyData("Company 1"),
  CompanyData("Company 2"),
  CompanyData("Company 3"),
  CompanyData("Company 4"),
  CompanyData("Company 5"),
];

// ---------------- COMPANY SCREEN ----------------

class CompanySelectionScreen extends StatelessWidget {
  const CompanySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Company")),
      body: ListView.builder(
        itemCount: companies.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(companies[index].name),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EnergyHomePage(company: companies[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------- HOME ----------------

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

  double consumption = 0;
  double generation = 0;
  double balance = 0;

  double ebUsed = 0;
  double surplus = 0;

  double totalCost = 0;
  double demandCharge = 0;
  double avgCost = 0;
  double finalAmount = 0;

  double renewablePercent = 0;

  double bankedPower = 0;
  double currentPower = 0;

  double bankUsed = 0;
  double bankLoss = 0;

  double sanctionedDemand = 2500;
  double maxDemand = 0;

  double calculateEB(double units) {
    if (units <= 100) {
      return 0;
    } else if (units <= 200)
      return (units - 100) * 2;
    else if (units <= 500)
      return (100 * 2) + (units - 200) * 5;
    else
      return (100 * 2) + (300 * 5) + (units - 500) * 7;
  }

  double calculateDemand(double sd, double md) {
    if (sd == 0) return 0;

    double percent = (md / sd) * 100;
    if (percent >= 90) return 0;

    double unused = (sd * 0.9) - md;
    if (unused < 0) unused = 0;

    return unused * 600;
  }

  void calculate() {
    setState(() {
      consumption = (double.tryParse(c1.text) ?? 0) +
          (double.tryParse(c2.text) ?? 0) +
          (double.tryParse(c3.text) ?? 0) +
          (double.tryParse(c4.text) ?? 0) +
          (double.tryParse(c5.text) ?? 0);

      generation = (double.tryParse(solar.text) ?? 0) +
          (double.tryParse(wind.text) ?? 0);
      bankedPower = generation / 2;
      currentPower = generation / 2;

      balance = currentPower - consumption;

      if (currentPower >= consumption) {
        ebUsed = 0;
        surplus = currentPower - consumption;
      } else {
        ebUsed = consumption - currentPower;
        surplus = 0;
      }
      double usableBank = bankedPower * 0.9; // 10% loss
      bankLoss = bankedPower * 0.1;

      if (ebUsed > 0) {
        if (usableBank >= ebUsed) {
          ebUsed = 0;
        } else {
          ebUsed = ebUsed - usableBank;
        }
      }
      totalCost = calculateEB(ebUsed);
      maxDemand = consumption;
      double demandCharge = calculateDemand(sanctionedDemand, maxDemand);
      double achievedPercent = (maxDemand / sanctionedDemand) * 100;

      if (achievedPercent < 90) {
        double unusedDemand = (sanctionedDemand * 0.9) - maxDemand;

        if (unusedDemand > 0) {
          demandCharge = unusedDemand * 600;
        } else {
          demandCharge = 0;
        }
      } else {
        demandCharge = 0;
      }

      finalAmount = totalCost + demandCharge;

// Use banked power to reduce EB
      if (ebUsed > 0) {
        if (usableBank >= ebUsed) {
          bankUsed = ebUsed;
          ebUsed = 0;
        } else {
          bankUsed = usableBank;
          ebUsed = ebUsed - usableBank;
        }
      }

      double sd = double.tryParse(sanctionedCtrl.text) ?? 0;
      double md = double.tryParse(maxDemandCtrl.text) ?? 0;

      demandCharge = calculateDemand(sd, md);

      finalAmount = totalCost + demandCharge;
      renewablePercent =
          consumption > 0 ? (currentPower / consumption) * 100 : 0;
      avgCost = consumption > 0 ? finalAmount / consumption : 0;
    });
  }

  Future<void> saveData() async {
    await FirebaseFirestore.instance.collection('energy_data').add({
      'company': widget.company.name,
      'consumption': consumption,
      'generation': generation,
      'balance': balance,
      'ebUsed': ebUsed,
      'surplus': surplus,
      'totalCost': totalCost,
      'demandCharge': demandCharge,
      'finalAmount': finalAmount,
      'timestamp': FieldValue.serverTimestamp(),
      'bankedPower': bankedPower,
      'currentPower': currentPower,
      'renewablePercent': renewablePercent,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data saved to Firebase ")),
    );
  }

  Future<void> downloadPDF() async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("ENERGY REPORT",
                style:
                    pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text("Company: ${widget.company.name}"),
            pw.Text("Date: ${now.day}-${now.month}-${now.year}"),
            pw.Text("Time: ${now.hour}:${now.minute}"),
            pw.Divider(),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                row("Consumption", consumption),
                row("Generation", generation),
                row("Balance", balance),
                row("EB Used", ebUsed),
                row("Surplus", surplus),
                row("EB Cost", totalCost),
                row("Demand Charge", demandCharge),
                row("Average Cost", avgCost),
                row("Final Amount", finalAmount),
                row("Banked Power", bankedPower),
                row("Current Power", currentPower),
                row("Renewable %", renewablePercent),
                row("EB Cost", totalCost),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
    );
  }

  pw.TableRow row(String title, double value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(title),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value.toStringAsFixed(2)),
        ),
      ],
    );
  }

  Widget inputBox(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget resultCard(String title, double value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(title),
              Text(value.toStringAsFixed(2)),
            ],
          ),
        ),
      ),
    );
  }

  void goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CompanySelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.company.name), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            inputBox("C1", c1),
            inputBox("C2", c2),
            inputBox("C3", c3),
            inputBox("C4", c4),
            inputBox("C5", c5),
            inputBox("Solar", solar),
            inputBox("Wind", wind),
            inputBox("Sanctioned Demand", sanctionedCtrl),
            inputBox("Max Demand", maxDemandCtrl),
            const SizedBox(height: 20),
            Row(children: [
              resultCard("Consumption", consumption),
              resultCard("Generation", generation),
            ]),
            Row(children: [
              resultCard("Balance", balance),
              resultCard("EB Used", ebUsed),
            ]),
            Row(children: [
              resultCard("Surplus", surplus),
              resultCard("Cost", totalCost),
            ]),
            Row(children: [
              resultCard("Demand", demandCharge),
              resultCard("Final", finalAmount),
            ]),
            Row(children: [
              resultCard("Banked", bankedPower),
              resultCard("Current", currentPower),
            ]),
            Row(children: [
              resultCard("Balance", balance),
              resultCard("EB Used", ebUsed),
            ]),
            Row(children: [
              resultCard("Renewable %", renewablePercent),
            ]),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                "Renewable %: ${renewablePercent.toStringAsFixed(2)}%",
                style: TextStyle(
                  color: renewablePercent > 50 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            Container(
              height: 250,
              padding: EdgeInsets.all(10),
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(toY: consumption, color: Colors.blue),
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(toY: generation, color: Colors.green),
                    ]),
                    BarChartGroupData(x: 2, barRods: [
                      BarChartRodData(toY: ebUsed, color: Colors.red),
                    ]),
                    BarChartGroupData(x: 3, barRods: [
                      BarChartRodData(toY: finalAmount, color: Colors.orange),
                    ]),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: downloadPDF,
              child: const Text("Download PDF"),
            ),
            ElevatedButton(
              onPressed: () {
                calculate();
                saveData();
              },
              child: const Text("Calculate"),
            ),
            ElevatedButton(
              onPressed: goHome,
              child: const Text("Back to Home"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        HistoryScreen(company: widget.company), // ✅ FIX
                  ),
                );
              },
              child: const Text("View History"),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- HISTORY ----------------

class HistoryScreen extends StatefulWidget {
  final CompanyData company;

  const HistoryScreen({super.key, required this.company});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Widget summaryCard(String title, double value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 5),
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String selectedFilter = "All";
  DateTime? startDate;
  DateTime? endDate;

  bool checkFilter(DateTime date) {
    final now = DateTime.now();

    if (selectedFilter == "Today") {
      return date.day == now.day &&
          date.month == now.month &&
          date.year == now.year;
    } else if (selectedFilter == "This Month") {
      return date.month == now.month && date.year == now.year;
    } else if (selectedFilter == "This Year") {
      return date.year == now.year;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.company.name} History"),
      ),
      body: Column(
        children: [
          // DROPDOWN
          DropdownButton<String>(
            value: selectedFilter,
            items: ["All", "Today", "This Month", "This Year"]
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedFilter = value!;
              });
            },
          ),

          // DATE PICKERS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );

                  if (picked != null) {
                    setState(() {
                      startDate = picked;
                    });
                  }
                },
                child: Text(startDate == null
                    ? "Start Date"
                    : "${startDate!.day}/${startDate!.month}/${startDate!.year}"),
              ),
              ElevatedButton(
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );

                  if (picked != null) {
                    setState(() {
                      endDate = picked;
                    });
                  }
                },
                child: Text(endDate == null
                    ? "End Date"
                    : "${endDate!.day}/${endDate!.month}/${endDate!.year}"),
              ),
            ],
          ),

          // STREAM BUILDER
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('energy_data')
                  .where('company', isEqualTo: widget.company.name)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No Data Found"));
                }

                var filteredData = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  DateTime date = (data['timestamp'] as Timestamp).toDate();

                  if (startDate != null && endDate != null) {
                    return date.isAfter(startDate!) && date.isBefore(endDate!);
                  }

                  return checkFilter(date);
                }).toList();

                double totalConsumption = 0;
                double totalCost = 0;
                double totalDemand = 0;

                for (var doc in filteredData) {
                  var data = doc.data() as Map<String, dynamic>;
                  totalConsumption += (data['consumption'] ?? 0);
                  totalCost += (data['finalAmount'] ?? 0);
                  totalDemand += (data['demandCharge'] ?? 0);
                }

                double avgCost =
                    totalConsumption > 0 ? totalCost / totalConsumption : 0;

                return Column(
                  children: [
                    // SUMMARY CARDS
                    Row(
                      children: [
                        summaryCard(
                            "Total Units", totalConsumption, Colors.blue),
                        summaryCard("Total Cost", totalCost, Colors.green),
                      ],
                    ),

                    Row(
                      children: [
                        summaryCard("Avg Cost", avgCost, Colors.orange),
                      ],
                    ),

                    Row(
                      children: [
                        summaryCard("Demand Charge", totalDemand, Colors.red),
                      ],
                    ),

                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          var item = filteredData[index].data()
                              as Map<String, dynamic>;

                          return Card(
                            margin: const EdgeInsets.all(10),
                            child: ListTile(
                              title: Text(item['company']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Consumption: ${item['consumption']}"),
                                  Text("Generation: ${item['generation']}"),
                                  Text("Final Amount: ₹${item['finalAmount']}"),
                                  Text("Banked: ${item['bankedPower']}"),
                                  Text("Current: ${item['currentPower']}"),
                                  Text(
                                      "Renewable: ${item['renewablePercent']}"),
                                  Text(
                                      "Demand Charge: ${item['demandCharge']}"),
                                ],
                              ),
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
    );
  }
}
