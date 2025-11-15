import 'package:flutter/material.dart';

class DigitalBodyguardScreen extends StatefulWidget {
  const DigitalBodyguardScreen({super.key});

  @override
  State<DigitalBodyguardScreen> createState() => _DigitalBodyguardScreenState();
}

class _DigitalBodyguardScreenState extends State<DigitalBodyguardScreen> {
  bool protectionActive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff2f3f7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black87,
        title: const Text("Digital Bodyguard"),
        actions: const [
          Icon(Icons.notifications_none),
          SizedBox(width: 10),
          Icon(Icons.account_circle_outlined),
          SizedBox(width: 16),
        ],
      ),
      drawer: const Drawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.shield_rounded, color: Colors.redAccent, size: 60),
                  const SizedBox(height: 12),
                  const Text(
                    "Digital Bodyguard",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "24/7 Protection Against Scams & Phishing",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Protection Active row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(
                          Icons.circle,
                          color: protectionActive ? Colors.green : Colors.red,
                          size: 12,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          protectionActive ? "Protection Active" : "Protection Disabled",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ]),
                      Switch(
                        value: protectionActive,
                        onChanged: (val) {
                          setState(() => protectionActive = val);
                        },
                        activeColor: Colors.green,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      _StatItem(label: "Threats Blocked", value: "24", color: Colors.green),
                      _StatItem(label: "Scans Today", value: "156", color: Colors.blue),
                      _StatItem(label: "Detection Rate", value: "99.9%", color: Colors.purple),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent Threats Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recent Threats Detected",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
            ),
            const SizedBox(height: 10),

            const ThreatCard(
              level: "HIGH",
              message:
                  'The message "Get 2% daily for every account link exchange" contains signs of a cryptocurrency scam.',
              tags: ["phishing", "blocked"],
              time: "2m ago",
              color: Colors.redAccent,
            ),
            const ThreatCard(
              level: "MEDIUM",
              message: "Suspicious link detected in messaging app.",
              tags: ["suspicious link", "blocked"],
              time: "5m ago",
              color: Colors.amber,
            ),
            const ThreatCard(
              level: "HIGH",
              message: "App requesting unusual permissions detected.",
              tags: ["fake app"],
              time: "12m ago",
              color: Colors.redAccent,
            ),

            const SizedBox(height: 20),

            // Bottom buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.remove_red_eye_outlined),
                    label: const Text("Scan Now"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.settings),
                    label: const Text("Settings"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---- COMPONENTS ----

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}

class ThreatCard extends StatelessWidget {
  final String level;
  final String message;
  final List<String> tags;
  final String time;
  final Color color;

  const ThreatCard({
    super.key,
    required this.level,
    required this.message,
    required this.tags,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  level,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 12),
                ),
              ),
              Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: tags
                .map(
                  (t) => Chip(
                    label: Text(t),
                    labelStyle: const TextStyle(fontSize: 12),
                    backgroundColor: Colors.grey.shade200,
                  ),
                )
                .toList(),
          ),
        ]),
      ),
    );
  }
}
