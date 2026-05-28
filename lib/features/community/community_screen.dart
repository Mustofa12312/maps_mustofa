import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Simulated community reports
  final List<_RoadReport> _reports = [
    _RoadReport(
      type: ReportType.macet,
      location: 'Jl. Sudirman, Jakarta Pusat',
      description: 'Kemacetan parah arah selatan',
      time: DateTime.now().subtract(const Duration(minutes: 15)),
      upvotes: 24,
    ),
    _RoadReport(
      type: ReportType.kecelakaan,
      location: 'Tol Cipularang KM 91',
      description: 'Kecelakaan 2 kendaraan, satu jalur tertutup',
      time: DateTime.now().subtract(const Duration(minutes: 32)),
      upvotes: 48,
    ),
    _RoadReport(
      type: ReportType.rusak,
      location: 'Jl. Raya Bogor KM 35',
      description: 'Jalan berlubang besar, hati-hati',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      upvotes: 12,
    ),
    _RoadReport(
      type: ReportType.banjir,
      location: 'Jl. Otista, Jakarta Timur',
      description: 'Banjir 30 cm, hindari rute ini',
      time: DateTime.now().subtract(const Duration(hours: 1)),
      upvotes: 36,
    ),
    _RoadReport(
      type: ReportType.ditutup,
      location: 'Jl. Asia Afrika, Bandung',
      description: 'Ditutup untuk acara car free day',
      time: DateTime.now().subtract(const Duration(minutes: 5)),
      upvotes: 9,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showReportDialog() {
    ReportType? selected;
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Buat Laporan', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              const Text('Jenis Laporan', style: TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReportType.values.map((t) {
                  final isSel = selected == t;
                  return GestureDetector(
                    onTap: () => setModal(() => selected = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? t.color.withValues(alpha: 0.15) : AppColors.cardDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSel ? t.color : AppColors.borderDark,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t.emoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(t.label, style: TextStyle(
                            color: isSel ? t.color : AppColors.textOnDarkSecondary,
                            fontSize: 13, fontWeight: FontWeight.w500,
                          )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Deskripsi (opsional)', style: TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'Contoh: macet parah, 2 km antrian...'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selected == null
                      ? null
                      : () {
                          setState(() {
                            _reports.insert(0, _RoadReport(
                              type: selected!,
                              location: 'Lokasi Anda',
                              description: descController.text.isEmpty
                                  ? selected!.label
                                  : descController.text,
                              time: DateTime.now(),
                              upvotes: 0,
                            ));
                          });
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Laporan ${selected!.label} berhasil dikirim!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.borderDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Kirim Laporan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Komunitas & Laporan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textOnDarkSecondary,
          tabs: const [
            Tab(text: 'Laporan Terkini'),
            Tab(text: 'Statistik'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_alert, color: Colors.white),
        label: const Text('Buat Laporan', style: TextStyle(color: Colors.white)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsList(),
          _buildStats(),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    if (_reports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🛣️', style: TextStyle(fontSize: 56)),
            SizedBox(height: 12),
            Text('Belum ada laporan kondisi jalan',
              style: TextStyle(color: Colors.white60)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _reports.length,
      itemBuilder: (_, i) {
        final r = _reports[i];
        return _buildReportCard(r, i);
      },
    );
  }

  Widget _buildReportCard(_RoadReport r, int index) {
    final minutesAgo = DateTime.now().difference(r.time).inMinutes;
    final timeLabel = minutesAgo < 60
        ? '${minutesAgo}m lalu'
        : '${DateTime.now().difference(r.time).inHours}j lalu';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: r.type.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: r.type.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(r.type.emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: r.type.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(r.type.label, style: TextStyle(color: r.type.color, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    Text(timeLabel, style: const TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(r.location, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(r.description, style: const TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _reports[index] = _RoadReport(
                        type: r.type, location: r.location, description: r.description,
                        time: r.time, upvotes: r.upvotes + 1,
                      )),
                      child: Row(
                        children: [
                          const Icon(Icons.thumb_up_outlined, color: AppColors.primary, size: 14),
                          const SizedBox(width: 4),
                          Text('${r.upvotes}', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.share_outlined, color: AppColors.textOnDarkSecondary, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final byType = <ReportType, int>{};
    for (final r in _reports) {
      byType[r.type] = (byType[r.type] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF003D2E), Color(0xFF00875A)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Laporan Hari Ini', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('${_reports.length}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700)),
              const Text('laporan dari komunitas', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Berdasarkan Jenis', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...ReportType.values.map((t) {
          final count = byType[t] ?? 0;
          final pct = _reports.isEmpty ? 0.0 : count / _reports.length;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                Text(t.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(t.label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text('$count laporan', style: TextStyle(color: t.color, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: AppColors.borderDark,
                          valueColor: AlwaysStoppedAnimation(t.color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

enum ReportType {
  macet('Kemacetan', '🚗', AppColors.warning),
  kecelakaan('Kecelakaan', '🚨', AppColors.error),
  rusak('Jalan Rusak', '⚠️', AppColors.accent),
  banjir('Banjir', '🌊', AppColors.info),
  ditutup('Jalan Ditutup', '🚧', Color(0xFF8B5CF6));

  final String label;
  final String emoji;
  final Color color;
  const ReportType(this.label, this.emoji, this.color);
}

class _RoadReport {
  final ReportType type;
  final String location;
  final String description;
  final DateTime time;
  final int upvotes;

  const _RoadReport({
    required this.type,
    required this.location,
    required this.description,
    required this.time,
    required this.upvotes,
  });
}
