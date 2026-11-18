import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/api/booking_draft.dart';
import '../../../../core/models/api/customer_address.dart';
import '../../../../core/models/api/service_category.dart';
import '../../../../core/models/booking.dart';
import '../../../../core/models/service_item.dart';
import '../../../../core/services/address_service.dart';
import '../../../../core/services/api_config.dart';
import '../../../../core/services/api_exception.dart';
import '../../../../core/services/booking_assistant_service.dart';
import '../../../../core/services/booking_service.dart';
import '../../../../core/services/catalog_service.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../core/services/token_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/zing_search_scene.dart';
import '../../../shell/presentation/pages/main_shell.dart';

/// Opens the normal service list, pre-filling [prefill] as the problem.
typedef ChooseServiceCallback =
    Future<void> Function(BuildContext context, String prefill);

enum _Phase { loading, needsInfo, fullList, notOffered, confirm, error }

/// Booking assistant, steps 2–4: get the draft from `POST /bookings/draft`,
/// let the customer review / answer / change it, then book with the
/// existing `POST /bookings`. Nothing is booked before the Book tap, and
/// every state offers "Choose a service yourself".
class BookingAssistantPage extends StatefulWidget {
  const BookingAssistantPage({
    super.key,
    required this.message,
    required this.source,
    required this.services,
    required this.onBooked,
    required this.onChooseService,
  });

  final String message;
  final DraftSource source;

  /// Home catalogue, used to show the booked service with its local
  /// icon/colour in the bookings list.
  final List<ServiceItem> services;
  final ValueChanged<Booking> onBooked;
  final ChooseServiceCallback onChooseService;

  @override
  State<BookingAssistantPage> createState() => _BookingAssistantPageState();
}

class _BookingAssistantPageState extends State<BookingAssistantPage> {
  static const _minDescription = 10;
  static const _maxDescription = 1000;
  static const _minLead = Duration(minutes: 60);
  static const _maxAhead = Duration(days: 60);

  _Phase _phase = _Phase.loading;
  late String _message = widget.message;
  late DraftSource _source = widget.source;

  BookingDraft? _draft;
  ApiException? _error;
  bool _answeredOnce = false;

  // NEEDS_INFO
  List<TextEditingController> _answerControllers = [];

  // Edit-and-retry (NOT_OFFERED / 400 / 422)
  final _messageController = TextEditingController();
  bool _editingMessage = false;

  // Confirm screen
  ServiceCategory? _service;
  final _descriptionController = TextEditingController();
  DateTime? _scheduledAt;
  List<CustomerAddress>? _addresses;
  String? _addressId;
  bool _payOnline = false;
  bool _booking = false;

  List<ServiceCategory>? _allCategories;

  @override
  void initState() {
    super.initState();
    _messageController.text = _message;
    _descriptionController.addListener(() => setState(() {}));
    _fetchDraft();
    _loadAddresses();
  }

  @override
  void dispose() {
    for (final c in _answerControllers) {
      c.dispose();
    }
    _messageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- data

  Future<void> _fetchDraft({List<DraftAnswer> answers = const []}) async {
    setState(() {
      _phase = _Phase.loading;
      _error = null;
      _editingMessage = false;
    });
    try {
      final draft = await BookingAssistantService.instance.draft(
        message: _message,
        source: _source,
        answers: answers,
      );
      if (!mounted) return;
      _draft = draft;
      switch (draft.status) {
        case BookingDraftStatus.ready:
          _openConfirm(draft.service);
        case BookingDraftStatus.needsInfo:
          if (_answeredOnce || draft.questions.isEmpty) {
            // Still unsure after one round: no more questions, show the
            // full list instead.
            _showFullList();
          } else {
            _setQuestions(draft.questions);
            setState(() => _phase = _Phase.needsInfo);
          }
        case BookingDraftStatus.notOffered:
          setState(() => _phase = _Phase.notOffered);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _phase = _Phase.error;
      });
      if (e.statusCode == 503) {
        // Assistant off / busy / timed out: straight to the normal picker
        // with what the customer typed as the description.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onChooseService(context, _message);
        });
      }
    }
  }

  Future<void> _loadAddresses() async {
    try {
      final list = await AddressService.instance.list();
      if (!mounted) return;
      CustomerAddress? pick;
      for (final a in list) {
        if (a.isDefault && a.serviceable) pick = a;
      }
      pick ??= list.where((a) => a.serviceable).firstOrNull;
      setState(() {
        _addresses = list;
        _addressId = pick?.id;
      });
    } catch (_) {
      if (mounted) setState(() => _addresses = const []);
    }
  }

  Future<List<ServiceCategory>> _categories() async {
    return _allCategories ??= await CatalogService.instance.getCategories();
  }

  void _setQuestions(List<String> questions) {
    for (final c in _answerControllers) {
      c.dispose();
    }
    _answerControllers = [
      for (final _ in questions.take(2))
        TextEditingController()..addListener(() => setState(() {})),
    ];
  }

  void _openConfirm(ServiceCategory? service) {
    final draft = _draft;
    if (_descriptionController.text.trim().isEmpty) {
      final text = (draft?.description ?? '').trim();
      _descriptionController.text = text.isNotEmpty ? text : _message;
    }
    _scheduledAt ??= _validOrNull(draft?.suggestedScheduledAt?.toLocal());
    setState(() {
      _service = service;
      _phase = _Phase.confirm;
    });
    if (service == null) _pickService();
  }

  void _showFullList() {
    setState(() => _phase = _Phase.fullList);
    _categories().then((_) {
      if (mounted) setState(() {});
    }, onError: (_) {});
  }

  // ------------------------------------------------------------- actions

  void _chooseYourself() {
    AppHaptics.press();
    final text = _descriptionController.text.trim().isNotEmpty
        ? _descriptionController.text.trim()
        : _message;
    widget.onChooseService(context, text);
  }

  void _sendAnswers() {
    final draft = _draft;
    if (draft == null) return;
    final answers = <DraftAnswer>[
      for (var i = 0; i < _answerControllers.length; i++)
        if (_answerControllers[i].text.trim().isNotEmpty)
          DraftAnswer(draft.questions[i], _answerControllers[i].text.trim()),
    ];
    if (answers.isEmpty) return;
    AppHaptics.confirm();
    FocusScope.of(context).unfocus();
    _answeredOnce = true;
    _fetchDraft(answers: answers);
  }

  void _retryWithEditedMessage() {
    final text = _messageController.text.trim();
    if (text.length < BookingAssistantService.minMessageLength) return;
    AppHaptics.confirm();
    FocusScope.of(context).unfocus();
    if (text != _message) _source = DraftSource.text;
    _message = text;
    _answeredOnce = false;
    _descriptionController.clear();
    _scheduledAt = null;
    _fetchDraft();
  }

  Future<void> _pickService() async {
    final picked = await showModalBottomSheet<ServiceCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ServicePickerSheet(
        current: _service,
        quick: [?_draft?.service, ...?_draft?.alternatives],
        loadAll: _categories,
      ),
    );
    if (picked != null && mounted) {
      AppHaptics.tick();
      setState(() => _service = picked);
    }
  }

  DateTime get _earliest => _roundUp15(DateTime.now().add(_minLead));

  DateTime get _latest => DateTime.now().add(_maxAhead);

  DateTime _roundUp15(DateTime t) {
    final base = DateTime(t.year, t.month, t.day, t.hour);
    final partial = t.second > 0 || t.millisecond > 0 ? 1 : 0;
    final up = ((t.minute + partial + 14) ~/ 15) * 15;
    return base.add(Duration(minutes: up));
  }

  DateTime? _validOrNull(DateTime? t) {
    if (t == null) return null;
    if (t.isBefore(DateTime.now().add(_minLead)) || t.isAfter(_latest)) {
      return null;
    }
    return t;
  }

  Future<void> _pickTime() async {
    final initial = _scheduledAt ?? _earliest;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(_earliest.year, _earliest.month, _earliest.day),
      lastDate: _latest,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      initialEntryMode: TimePickerEntryMode.dial,
    );
    if (time == null || !mounted) return;
    var picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      (time.minute / 15).round() * 15,
    );
    if (picked.isBefore(_earliest)) {
      picked = _earliest;
      _snack('The earliest we can come is ${_formatWhen(picked)}.');
    } else if (picked.isAfter(_latest)) {
      _snack('Please pick a time within the next 60 days.');
      return;
    }
    AppHaptics.tick();
    setState(() => _scheduledAt = picked);
  }

  String? get _bookBlocker {
    if (_service == null) return 'Pick a service';
    final d = _descriptionController.text.trim().length;
    if (d < _minDescription) return 'Describe the problem (10+ characters)';
    if (d > _maxDescription) return 'Problem text is too long';
    if (_scheduledAt == null) return 'Pick a time';
    final address = _selectedAddress;
    if (address != null && !address.serviceable) {
      return "We're not in this area yet";
    }
    return null;
  }

  CustomerAddress? get _selectedAddress =>
      _addresses?.where((a) => a.id == _addressId).firstOrNull;

  Future<void> _book() async {
    if (_booking) return;
    final blocker = _bookBlocker;
    if (blocker != null) {
      _snack(blocker);
      return;
    }
    final user = TokenStore.instance.user;
    if (!TokenStore.instance.hasSession || user == null || !user.isCustomer) {
      _snack('Please sign in with a customer account to book.');
      return;
    }
    // A suggested time may have gone stale while the customer reviewed.
    if (_validOrNull(_scheduledAt) == null) {
      setState(() => _scheduledAt = null);
      _snack('That time is too soon now — please pick another.');
      return;
    }
    AppHaptics.confirm();
    setState(() => _booking = true);
    final service = _service!;
    try {
      final addressId =
          _addressId ?? await OnboardingService.instance.ensureDefaultAddress();
      final created = await BookingService.instance.create(
        categoryId: service.id,
        scheduledAt: _scheduledAt!,
        description: _descriptionController.text.trim(),
        paymentMode: _payOnline ? 'ONLINE' : 'PAY_AFTER_SERVICE',
        addressId: addressId,
      );
      if (!mounted) return;
      widget.onBooked(
        Booking(
          id: created.id,
          service: _serviceItemFor(service),
          mode: BookingMode.scheduled.label,
          slot: _formatWhen(_scheduledAt!),
          payment: _payOnline ? 'Pay online' : 'Pay after service',
          total: created.totalAmount?.toInt() ?? _draft?.price ?? 0,
          status: BookingStatus.confirmed,
        ),
      );
      _snack('Booked — your professional will be assigned shortly.');
      _popToShell();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _booking = false);
      if (e.code == 'PINCODE_NOT_SERVICEABLE') {
        _snack("We're not in this area yet. Please pick another address.");
      } else if (e.statusCode == 503 && _payOnline) {
        _offerPayAfterService(e.message);
      } else {
        _snack(e.message);
      }
    }
  }

  Future<void> _offerPayAfterService(String message) async {
    final switchMode = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Online payment unavailable'),
        content: Text('$message\n\nYou can pay after the service instead.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pay after service'),
          ),
        ],
      ),
    );
    if (switchMode == true && mounted) {
      setState(() => _payOnline = false);
      _book();
    }
  }

  void _popToShell() {
    var foundHome = false;
    Navigator.of(context).popUntil((route) {
      foundHome = route.settings.name == MainShell.routeName || route.isFirst;
      return foundHome;
    });
  }

  ServiceItem _serviceItemFor(ServiceCategory category) {
    for (final s in widget.services) {
      if (s.categoryId == category.id) return s;
    }
    return ServiceItem(
      categoryId: category.id,
      title: category.name,
      subtitle: 'Doorstep repair service',
      icon: LucideIcons.wrench,
      price: category.basePrice ?? _draft?.price ?? 0,
      duration: '60 min',
      questions: const [],
      badge: category.tier ?? 'Verified',
      color: const Color(0xFFF4F1E9),
      imageUrl: _imageUrl(category.image),
      usesApiImage: true,
    );
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // -------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _phase == _Phase.confirm
              ? 'Review your booking'
              : 'Booking assistant',
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandForest,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey('$_phase$_editingMessage'),
          child: switch (_phase) {
            _Phase.loading => _buildLoading(),
            _Phase.needsInfo => _buildNeedsInfo(bottomInset),
            _Phase.fullList => _buildFullList(bottomInset),
            _Phase.notOffered => _buildNotOffered(bottomInset),
            _Phase.confirm => _buildConfirm(bottomInset),
            _Phase.error => _buildError(bottomInset),
          },
        ),
      ),
      bottomNavigationBar: _phase == _Phase.confirm
          ? _buildBookBar(bottomInset)
          : null,
    );
  }

  Widget _buildLoading() => _ThinkingView(message: _message);

  Widget _buildNeedsInfo(double bottomInset) {
    final draft = _draft!;
    final chips = [?draft.service, ...draft.alternatives];
    final anyAnswer = _answerControllers.any((c) => c.text.trim().isNotEmpty);
    return ListView(
      padding: EdgeInsets.fromLTRB(18, 8, 18, 24 + bottomInset),
      children: [
        if (draft.safetyAdvice != null) ...[
          _SafetyBanner(text: draft.safetyAdvice!),
          const SizedBox(height: 16),
        ],
        _title('A quick question or two'),
        const SizedBox(height: 4),
        _muted('So we send the right professional.'),
        const SizedBox(height: 18),
        for (var i = 0; i < _answerControllers.length; i++) ...[
          Text(
            draft.questions[i],
            style: const TextStyle(
              color: AppColors.brandForest,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _answerControllers[i],
            maxLength: 300,
            textInputAction: i == _answerControllers.length - 1
                ? TextInputAction.done
                : TextInputAction.next,
            onSubmitted: (_) {
              if (i == _answerControllers.length - 1) _sendAnswers();
            },
            decoration: _inputDecoration('Your answer'),
          ),
          const SizedBox(height: 8),
        ],
        _PrimaryButton(
          label: 'Send answers',
          enabled: anyAnswer,
          onTap: _sendAnswers,
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 26),
          _sectionLabel('Or pick the service'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in chips)
                ActionChip(
                  avatar: const Icon(LucideIcons.wrench, size: 16),
                  label: Text(c.name),
                  onPressed: () {
                    AppHaptics.tick();
                    // Keep the draft's description and time.
                    _openConfirm(c);
                  },
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        _chooseLink(),
      ],
    );
  }

  Widget _buildFullList(double bottomInset) {
    final all = _allCategories;
    return ListView(
      padding: EdgeInsets.fromLTRB(18, 8, 18, 24 + bottomInset),
      children: [
        _title('Pick the service that fits'),
        const SizedBox(height: 4),
        _muted("We'll keep your description and time."),
        const SizedBox(height: 16),
        if (all == null)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (all.isEmpty)
          _chooseLink()
        else
          for (final c in all)
            _ServiceRow(
              category: c,
              selected: false,
              onTap: () {
                AppHaptics.tick();
                _openConfirm(c);
              },
            ),
      ],
    );
  }

  Widget _buildNotOffered(double bottomInset) {
    return _StateView(
      bottomInset: bottomInset,
      icon: LucideIcons.searchX,
      title: "We don't offer this yet",
      body:
          'None of our services fits this request. You can browse what we '
          'do offer, or change your message and try again.',
      primaryLabel: 'Browse services',
      onPrimary: _chooseYourself,
      editor: _buildMessageEditor(),
    );
  }

  Widget _buildError(double bottomInset) {
    final e = _error;
    final status = e?.statusCode;
    final (IconData icon, String title, String body, bool canEdit) = switch ((
      status,
      e?.code,
    )) {
      (422, _) || (_, 'ASSISTANT_NO_DRAFT') => (
        LucideIcons.messageCircleQuestion,
        "Sorry, we couldn't understand that.",
        'Try describing it differently, or choose the service yourself.',
        true,
      ),
      (429, _) => (
        LucideIcons.hourglass,
        'Please wait a few minutes',
        "You've asked the assistant a lot in a short time.",
        false,
      ),
      (503, _) => (
        LucideIcons.cloudOff,
        'The assistant is unavailable',
        'You can still book by choosing the service yourself — your '
            'description is kept.',
        false,
      ),
      (400, _) => (
        LucideIcons.pencil,
        'Please check your message',
        e?.message ?? '',
        true,
      ),
      (401, _) => (
        LucideIcons.lock,
        'Please sign in again',
        e?.message ?? '',
        false,
      ),
      _ => (
        LucideIcons.triangleAlert,
        'Something went wrong',
        e?.message ?? 'Please try again.',
        true,
      ),
    };
    return _StateView(
      bottomInset: bottomInset,
      icon: icon,
      title: title,
      body: body,
      primaryLabel: 'Choose a service yourself',
      onPrimary: _chooseYourself,
      editor: canEdit ? _buildMessageEditor() : null,
    );
  }

  /// "Try again (edit the text)" for NOT_OFFERED / 400 / 422.
  Widget _buildMessageEditor() {
    if (!_editingMessage) {
      return OutlinedButton.icon(
        onPressed: () => setState(() => _editingMessage = true),
        icon: const Icon(LucideIcons.pencil, size: 16),
        label: const Text('Edit message and try again'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandForest,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );
    }
    return StatefulBuilder(
      builder: (context, setLocal) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _messageController,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            maxLength: BookingAssistantService.maxMessageLength,
            onChanged: (_) => setLocal(() {}),
            decoration: _inputDecoration('Describe your problem'),
          ),
          const SizedBox(height: 8),
          _PrimaryButton(
            label: 'Try again',
            enabled:
                _messageController.text.trim().length >=
                BookingAssistantService.minMessageLength,
            onTap: _retryWithEditedMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirm(double bottomInset) {
    final draft = _draft;
    final service = _service;
    final price = service?.basePrice ?? draft?.price;
    final descLen = _descriptionController.text.trim().length;
    final emergency = draft?.urgency == BookingUrgency.emergency;
    return ListView(
      padding: EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        if (draft?.safetyAdvice != null) ...[
          _SafetyBanner(text: draft!.safetyAdvice!),
          const SizedBox(height: 16),
        ],
        if (draft?.urgency != null &&
            draft!.urgency != BookingUrgency.flexible) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: _UrgencyBadge(urgency: draft.urgency!),
          ),
          const SizedBox(height: 14),
        ],

        // Service
        _sectionLabel('Service'),
        const SizedBox(height: 8),
        _Card(
          onTap: _pickService,
          child: Row(
            children: [
              _ServiceThumb(image: service?.image),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service?.name ?? 'Pick a service',
                      style: const TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (price != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'From ₹$price',
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              TextButton(onPressed: _pickService, child: const Text('Change')),
            ],
          ),
        ),
        if ((draft?.alternatives ?? const []).isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final alt in [?draft!.service, ...draft.alternatives])
                ChoiceChip(
                  label: Text(alt.name),
                  selected: alt.id == service?.id,
                  onSelected: (_) {
                    AppHaptics.tick();
                    setState(() => _service = alt);
                  },
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),

        // Problem
        _sectionLabel('Problem'),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          minLines: 3,
          maxLines: 6,
          maxLength: _maxDescription,
          decoration: _inputDecoration('What needs fixing?').copyWith(
            errorText: descLen > 0 && descLen < _minDescription
                ? 'Please add a little more detail (10+ characters)'
                : null,
          ),
        ),
        const SizedBox(height: 12),

        // When
        _sectionLabel('When'),
        const SizedBox(height: 8),
        _Card(
          onTap: _pickTime,
          child: Row(
            children: [
              const Icon(
                LucideIcons.calendarClock,
                color: AppColors.brandForest,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _scheduledAt == null
                      ? 'Pick a date and time'
                      : _formatWhen(_scheduledAt!),
                  style: TextStyle(
                    color: _scheduledAt == null
                        ? AppColors.mutedText
                        : AppColors.brandForest,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: AppColors.mutedText),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ChoiceChip(
            avatar: Icon(
              LucideIcons.zap,
              size: 16,
              color: emergency ? Colors.white : AppColors.brandForest,
            ),
            label: Text('Earliest: ${_formatWhen(_earliest)}'),
            selected: _scheduledAt == _earliest,
            selectedColor: emergency ? const Color(0xFFC62828) : null,
            backgroundColor: emergency ? const Color(0xFFFFEBEE) : null,
            labelStyle: TextStyle(
              color: emergency && _scheduledAt == _earliest
                  ? Colors.white
                  : AppColors.brandForest,
              fontWeight: FontWeight.w600,
            ),
            showCheckmark: false,
            onSelected: (_) {
              AppHaptics.tick();
              setState(() => _scheduledAt = _earliest);
            },
          ),
        ),
        const SizedBox(height: 20),

        // Address
        _sectionLabel('Address'),
        const SizedBox(height: 8),
        ..._buildAddresses(),
        const SizedBox(height: 20),

        // Payment
        _sectionLabel('Payment'),
        const SizedBox(height: 8),
        _OptionRow(
          icon: LucideIcons.banknote,
          label: 'Pay after service',
          selected: !_payOnline,
          onTap: () => setState(() => _payOnline = false),
        ),
        const SizedBox(height: 8),
        _OptionRow(
          icon: LucideIcons.smartphone,
          label: 'Pay online',
          selected: _payOnline,
          onTap: () => setState(() => _payOnline = true),
        ),
        const SizedBox(height: 18),
        _chooseLink(),
      ],
    );
  }

  List<Widget> _buildAddresses() {
    final list = _addresses;
    if (list == null) {
      return const [LinearProgressIndicator(minHeight: 2)];
    }
    if (list.isEmpty) {
      return [
        _muted(
          'No saved address yet — we\'ll use your default area. You can add '
          'addresses in Profile → Saved addresses.',
        ),
      ];
    }
    return [
      for (final a in list) ...[
        _OptionRow(
          icon: LucideIcons.mapPin,
          label: '${a.label} · ${a.shortLabel}',
          subtitle: a.serviceable ? null : "We're not in this area yet",
          selected: a.id == _addressId,
          enabled: a.serviceable,
          onTap: () => setState(() => _addressId = a.id),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }

  Widget _buildBookBar(double bottomInset) {
    final blocker = _bookBlocker;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (blocker != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                blocker,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          _PrimaryButton(
            label: 'Book',
            enabled: blocker == null && !_booking,
            loading: _booking,
            onTap: _book,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ helpers

  Widget _chooseLink() => Center(
    child: TextButton(
      onPressed: _chooseYourself,
      style: TextButton.styleFrom(foregroundColor: AppColors.brandTeal),
      child: const Text(
        'Choose a service yourself',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        ),
      ),
    ),
  );

  Widget _title(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      color: AppColors.brandForest,
      fontSize: 19,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
    ),
  );

  Widget _muted(String text) => Text(
    text,
    style: const TextStyle(
      color: AppColors.mutedText,
      fontSize: 13.5,
      height: 1.4,
    ),
  );

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: AppColors.brandForest,
      fontSize: 13,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.3,
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF8F7F3),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.borderSubtle),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.borderSubtle),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.brandForest, width: 1.4),
    ),
  );
}

String _formatWhen(DateTime t) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = day.difference(today).inDays;
  final dayLabel = switch (diff) {
    0 => 'Today',
    1 => 'Tomorrow',
    _ => '${weekdays[t.weekday - 1]}, ${t.day} ${months[t.month - 1]}',
  };
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$dayLabel, $h:$m ${t.hour < 12 ? 'am' : 'pm'}';
}

String? _imageUrl(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  final trimmed = path.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme) return trimmed;
  return '${ApiConfig.effectiveBaseUrl}$trimmed';
}

// ---------------------------------------------------------------- widgets

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.shieldAlert, color: Color(0xFFE65100)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF8A3A00),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgencyBadge extends StatelessWidget {
  const _UrgencyBadge({required this.urgency});

  final BookingUrgency urgency;

  @override
  Widget build(BuildContext context) {
    final emergency = urgency == BookingUrgency.emergency;
    final bg = emergency ? const Color(0xFFC62828) : const Color(0xFFFFB300);
    final fg = emergency ? Colors.white : const Color(0xFF3E2A00);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            emergency ? LucideIcons.siren : LucideIcons.clock,
            size: 14,
            color: fg,
          ),
          const SizedBox(width: 5),
          Text(
            emergency ? 'Emergency' : 'Soon',
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ServiceThumb extends StatelessWidget {
  const _ServiceThumb({this.image});

  final String? image;

  @override
  Widget build(BuildContext context) {
    final url = _imageUrl(image);
    const fallback = Icon(LucideIcons.wrench, color: AppColors.brandForest);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52,
        height: 52,
        color: const Color(0xFFF4F1E9),
        child: url == null
            ? fallback
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: enabled
            ? () {
                if (!selected) AppHaptics.tick();
                onTap();
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? AppColors.brandForest : AppColors.borderSubtle,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.brandForest, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Color(0xFFC62828),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                selected ? LucideIcons.circleCheck : LucideIcons.circle,
                color: selected ? AppColors.brandForest : AppColors.mutedText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ServiceCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: _ServiceThumb(image: category.image),
      title: Text(
        category.name,
        style: const TextStyle(
          color: AppColors.brandForest,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: category.basePrice == null
          ? null
          : Text('From ₹${category.basePrice}'),
      trailing: selected
          ? const Icon(LucideIcons.circleCheck, color: AppColors.brandForest)
          : const Icon(LucideIcons.chevronRight, color: AppColors.mutedText),
      onTap: onTap,
    );
  }
}

/// Change-service sheet: the draft's quick options first, then the full
/// `GET /categories` list.
class _ServicePickerSheet extends StatelessWidget {
  const _ServicePickerSheet({
    required this.current,
    required this.quick,
    required this.loadAll,
  });

  final ServiceCategory? current;
  final List<ServiceCategory> quick;
  final Future<List<ServiceCategory>> Function() loadAll;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, controller) => FutureBuilder<List<ServiceCategory>>(
        future: loadAll(),
        builder: (context, snap) {
          final quickIds = quick.map((c) => c.id).toSet();
          final rest = (snap.data ?? const <ServiceCategory>[])
              .where((c) => !quickIds.contains(c.id))
              .toList();
          return ListView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Choose a service',
                style: TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (quick.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'SUGGESTED',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                for (final c in quick)
                  _ServiceRow(
                    category: c,
                    selected: c.id == current?.id,
                    onTap: () => Navigator.pop(context, c),
                  ),
                const Divider(height: 24),
              ],
              if (snap.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snap.hasError)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Couldn't load services. Please try again."),
                )
              else
                for (final c in rest)
                  _ServiceRow(
                    category: c,
                    selected: c.id == current?.id,
                    onTap: () => Navigator.pop(context, c),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _StateView extends StatelessWidget {
  const _StateView({
    required this.bottomInset,
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.editor,
  });

  final double bottomInset;
  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final Widget? editor;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(24, 40, 24, 24 + bottomInset),
      children: [
        Icon(icon, size: 48, color: AppColors.brandTeal),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.brandForest,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: 28),
        _PrimaryButton(label: primaryLabel, onTap: onPrimary),
        if (editor != null) ...[const SizedBox(height: 12), editor!],
      ],
    );
  }
}

/// Forest-tinted liquid glass CTA, same as the payment page's Pay button.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled || loading ? 1 : 0.5,
      child: GlassButton.custom(
        width: double.infinity,
        height: 52,
        shape: const LiquidRoundedSuperellipse(borderRadius: 15),
        useOwnLayer: true,
        settings: const LiquidGlassSettings(glassColor: AppColors.brandForest),
        enabled: enabled,
        onTap: onTap,
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }
}

/// "Finding the right pro": a pulsing forest disc, steps that cycle while
/// the draft is made (2–6 s), the customer's own words, and a shimmering
/// skeleton of the review card that is about to appear.
class _ThinkingView extends StatefulWidget {
  const _ThinkingView({required this.message});

  final String message;

  @override
  State<_ThinkingView> createState() => _ThinkingViewState();
}

class _ThinkingViewState extends State<_ThinkingView> {
  static const _steps = [
    'Understanding your problem',
    'Matching the right service',
    'Checking the best time',
  ];

  int _step = 0;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1700), (_) {
      if (mounted && _step < _steps.length - 1) setState(() => _step++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Center(
          child: LayoutBuilder(
            builder: (context, c) =>
                ZingSearchScene(width: math.min(c.maxWidth, 320)),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Zing is finding your pro',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.brandForest,
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < _steps.length; i++) _stepRow(i),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                LucideIcons.quote,
                size: 16,
                color: AppColors.brandGold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: AppColors.brandForest,
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepRow(int i) {
    final done = i < _step;
    final active = i == _step;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 24),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? AppColors.brandTeal
                  : active
                  ? AppColors.brandGold.withValues(alpha: 0.22)
                  : AppColors.border,
            ),
            child: done
                ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
                : active
                ? const Padding(
                    padding: EdgeInsets.all(5),
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: AppColors.brandForest,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: GoogleFonts.poppins(
              color: done || active
                  ? AppColors.brandForest
                  : AppColors.mutedText.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
            child: Text(_steps[i]),
          ),
        ],
      ),
    );
  }
}
