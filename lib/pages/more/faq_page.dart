import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class FaqItem {
  final String question;
  final String answer;
  final String category;
  const FaqItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';

  static const _categories = [
    'All', 'Booking', 'Vehicles', 'Billing', 'Account', 'Notifications', 'General'
  ];

  final List<FaqItem> _allFaqs = const [
    FaqItem(
      question: 'How do I book a service?',
      answer: 'Go to Services → Book Service. Choose date/time, select your vehicle, and confirm.',
      category: 'Booking',
    ),
    FaqItem(
      question: 'Can I reschedule my appointment?',
      answer: 'Yes. Open My Appointments, tap the appointment, and choose Reschedule.',
      category: 'Booking',
    ),
    FaqItem(
      question: 'How do I add a vehicle?',
      answer: 'More → My Vehicles → tap the green + button, then fill in plate, model, and VIN.',
      category: 'Vehicles',
    ),
    FaqItem(
      question: 'Where do I see my invoices?',
      answer: 'Open Billing from the bottom navigation. You can view and download invoices.',
      category: 'Billing',
    ),
    FaqItem(
      question: 'Why am I not receiving notifications?',
      answer: 'Check device settings to allow notifications for TrackPit. In-app: More → Profile.',
      category: 'Notifications',
    ),
    FaqItem(
      question: 'How do I update my email or phone?',
      answer: 'More → Profile → edit your details, then Save Changes. Verification may be required.',
      category: 'Account',
    ),
    FaqItem(
      question: 'What can I do from the More menu?',
      answer: 'Access Profile, Find Workshops, My Vehicles, Payment Methods, Feedback, and FAQ.',
      category: 'General',
    ),
  ];

  List<FaqItem> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _allFaqs.where((f) {
      final matchesCat = _selectedCategory == 'All' || f.category == _selectedCategory;
      final matchesText = q.isEmpty ||
          f.question.toLowerCase().contains(q) ||
          f.answer.toLowerCase().contains(q);
      return matchesCat && matchesText;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final green = AppColors.primaryGreen;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('FAQ', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search questions…',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: green, width: 1.6),
                ),
              ),
            ),
          ),
          // Category chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = _categories[i];
                final selected = c == _selectedCategory;
                return ChoiceChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = c),
                  selectedColor: green.withOpacity(0.12),
                  labelStyle: TextStyle(
                    color: selected ? green : Colors.black87,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(color: selected ? green : const Color(0xFFE0E0E0)),
                  ),
                  backgroundColor: Colors.white,
                );
              },
            ),
          ),
          // FAQ list
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No results'))
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _FaqCard(item: _filtered[i], green: green),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  final FaqItem item;
  final Color green;
  const _FaqCard({required this.item, required this.green});

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.green, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 8,
            spreadRadius: 2,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(
            widget.item.question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          trailing: Icon(_open ? Icons.expand_less : Icons.expand_more),
          onExpansionChanged: (v) => setState(() => _open = v),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.item.answer,
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.item.category,
                style: TextStyle(fontSize: 12, color: widget.green, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
