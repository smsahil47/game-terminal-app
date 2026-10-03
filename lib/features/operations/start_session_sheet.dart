import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/operations.dart';
import '../../data/models/shop_snapshot.dart';
import '../../data/models/website_models.dart';
import '../../data/repositories/operations_repository.dart';
import '../../data/repositories/website_repository.dart';

/// The website opens Start Session over the current station or booking page.
/// Keep that interaction on mobile instead of navigating to Sessions first.
Future<bool> showStartSessionSheet(
  BuildContext context,
  ShopSnapshot shop,
  OperationsRepository operations,
  WebsiteRepository website, {
  String? stationId,
  SessionMode? initialMode,
  Booking? booking,
}) async {
  final available = shop.stations
      .where((station) => station.status == StationStatus.available)
      .toList();
  final selected = available
      .where((station) => station.id == (booking?.stationId ?? stationId))
      .firstOrNull;
  if (available.isEmpty ||
      ((stationId != null || booking != null) && selected == null)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The selected station is not available.')),
      );
    }
    return false;
  }
  if (booking != null &&
      selected!.type != 'PS5_MULTI' &&
      booking.mode != SessionMode.gaming) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This station supports Gaming only.')),
      );
    }
    return false;
  }
  try {
    final config = await website.configuration();
    List<String> games;
    try {
      games = await operations.games();
    } catch (_) {
      games = const [];
    }
    if (!context.mounted) return false;
    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _StartSessionSheet(
            shop: shop,
            operations: operations,
            config: config,
            catalog: games.isEmpty ? defaultGames : games,
            initialStation: selected ?? available.first,
            lockStation: stationId != null || booking != null,
            initialMode: booking?.mode ?? initialMode ?? SessionMode.gaming,
            booking: booking,
          ),
        ) ??
        false;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open Start Session: $error')),
      );
    }
    return false;
  }
}

class _StartSessionSheet extends StatefulWidget {
  const _StartSessionSheet({
    required this.shop,
    required this.operations,
    required this.config,
    required this.catalog,
    required this.initialStation,
    required this.lockStation,
    required this.initialMode,
    this.booking,
  });
  final ShopSnapshot shop;
  final OperationsRepository operations;
  final ShopConfiguration config;
  final List<String> catalog;
  final Station initialStation;
  final bool lockStation;
  final SessionMode initialMode;
  final Booking? booking;

  @override
  State<_StartSessionSheet> createState() => _StartSessionSheetState();
}

class _StartSessionSheetState extends State<_StartSessionSheet> {
  late Station station = widget.initialStation;
  late SessionMode mode = station.type == 'PS5_MULTI'
      ? widget.initialMode
      : SessionMode.gaming;
  late final name = TextEditingController(
    text: widget.booking?.customerName ?? '',
  );
  late final phone = TextEditingController(
    text: widget.booking?.customerPhone ?? '',
  );
  final customGame = TextEditingController();
  final snackName = TextEditingController();
  final snackPrice = TextEditingController();
  final notes = TextEditingController();
  String? selectedGame;
  int players = 1;
  int? reminderMinutes;
  bool submitting = false;
  final snacks = <Snack>[];

  @override
  void initState() {
    super.initState();
    players = widget.booking?.players ?? 1;
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    customGame.dispose();
    snackName.dispose();
    snackPrice.dispose();
    notes.dispose();
    super.dispose();
  }

  void _notice(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _submit() async {
    if (submitting) return;
    final customer = name.text.trim();
    final mobile = phone.text.trim();
    final game = selectedGame == '__other__'
        ? customGame.text.trim()
        : selectedGame ?? '';
    if (customer.length < 2) {
      _notice('Enter the customer name.');
      return;
    }
    if (mobile.isNotEmpty && !RegExp(r'^[6-9]\d{9}$').hasMatch(mobile)) {
      _notice('Enter a valid 10-digit mobile number.');
      return;
    }
    if (reminderMinutes == null) {
      _notice('Choose a session duration.');
      return;
    }
    if (game.isEmpty) {
      _notice('Select a game.');
      return;
    }
    if (mode == SessionMode.gaming &&
        (players < 1 || players > widget.shop.controllersFree)) {
      _notice('Only ${widget.shop.controllersFree} controllers are available.');
      return;
    }
    if (snackName.text.trim().isNotEmpty || snackPrice.text.trim().isNotEmpty) {
      _notice('Add the snack or clear the item and price fields.');
      return;
    }
    setState(() => submitting = true);
    try {
      await widget.operations.start(
        SessionDraft(
          station: station,
          customerName: customer,
          phone: mobile,
          mode: mode,
          minutes: reminderMinutes!,
          players: mode == SessionMode.gaming ? players : 1,
          game: game,
          notes: notes.text.trim(),
          playAmount: 0,
          ratePerHour: widget.config.fallbackRate(mode.value, players),
          snacks: List.of(snacks),
        ),
        widget.shop.controllersFree,
      );
      if (widget.booking != null) {
        try {
          await widget.operations.completeBooking(widget.booking!.id);
        } catch (_) {
          if (mounted) {
            _notice('Session started. Booking status needs manual review.');
          }
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _notice(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final games = gamesForSessionMode(mode.value, widget.catalog);
    final rate = widget.config.fallbackRate(mode.value, players);
    final available = widget.shop.stations
        .where((item) => item.status == StationStatus.available)
        .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: .94,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            border: Border(top: BorderSide(color: AppTheme.border)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Start session',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${station.name} · ${mode.label}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (!widget.lockStation) ...[
                      DropdownButtonFormField<Station>(
                        initialValue: station,
                        decoration: const InputDecoration(labelText: 'Station'),
                        items: [
                          for (final item in available)
                            DropdownMenuItem(
                              value: item,
                              child: Text(item.name),
                            ),
                        ],
                        onChanged: (value) => setState(() {
                          station = value!;
                          if (station.type != 'PS5_MULTI') {
                            mode = SessionMode.gaming;
                          }
                          selectedGame = null;
                        }),
                      ),
                      const SizedBox(height: 18),
                    ],
                    const _SectionLabel(Icons.person_outline, 'Customer'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: name,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'Name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        hintText: 'Phone (optional)',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _SectionLabel(Icons.schedule, 'Session Duration'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final choice in [30, 60, 120])
                          ChoiceChip(
                            label: Text(
                              choice == 30
                                  ? '30 Minutes'
                                  : choice == 60
                                  ? '1 Hour'
                                  : '2 Hours',
                            ),
                            selected: reminderMinutes == choice,
                            onSelected: (_) =>
                                setState(() => reminderMinutes = choice),
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'You’ll get an alert at this time. Billing follows actual elapsed time.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                    if (station.type == 'PS5_MULTI' &&
                        widget.booking == null) ...[
                      const SizedBox(height: 22),
                      const _SectionLabel(Icons.tune, 'Mode'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final value in SessionMode.values)
                            ChoiceChip(
                              label: Text(value.label),
                              selected: mode == value,
                              onSelected: (_) => setState(() {
                                mode = value;
                                selectedGame = null;
                              }),
                            ),
                        ],
                      ),
                    ],
                    if (mode == SessionMode.gaming) ...[
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Expanded(
                            child: _SectionLabel(
                              Icons.sports_esports_outlined,
                              'Players / Controllers',
                            ),
                          ),
                          Text(
                            '${widget.shop.controllersFree} available',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (var count = 1; count <= 4; count++)
                            ChoiceChip(
                              label: Text('$count'),
                              selected: players == count,
                              onSelected: count > widget.shop.controllersFree
                                  ? null
                                  : (_) => setState(() => players = count),
                            ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Rate: ₹$rate/hr · $players player${players == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    const _SectionLabel(Icons.search, 'Game'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey('${station.id}:${mode.value}'),
                      initialValue: selectedGame,
                      decoration: const InputDecoration(
                        hintText: 'Select a game',
                      ),
                      items: [
                        for (final game in games)
                          DropdownMenuItem(value: game, child: Text(game)),
                        const DropdownMenuItem(
                          value: '__other__',
                          child: Text('Other title…'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => selectedGame = value),
                    ),
                    if (selectedGame == '__other__') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: customGame,
                        decoration: const InputDecoration(
                          hintText: 'Type the game name',
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    const _SectionLabel(
                      Icons.cookie_outlined,
                      'Snacks (optional)',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: snackName,
                            decoration: const InputDecoration(
                              hintText: 'Item name',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: snackPrice,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '₹ Price',
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Add snack',
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final price = double.tryParse(
                              snackPrice.text.trim(),
                            );
                            if (snackName.text.trim().isEmpty ||
                                price == null ||
                                price <= 0) {
                              return;
                            }
                            setState(() {
                              snacks.add(
                                Snack(snackName.text.trim(), price.round()),
                              );
                              snackName.clear();
                              snackPrice.clear();
                            });
                          },
                        ),
                      ],
                    ),
                    for (final snack in snacks)
                      ListTile(
                        dense: true,
                        title: Text(snack.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₹${snack.price}'),
                            IconButton(
                              tooltip: 'Remove ${snack.name}',
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () =>
                                  setState(() => snacks.remove(snack)),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 22),
                    const _SectionLabel(Icons.notes, 'Notes (optional)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notes,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Anything to remember about this session',
                      ),
                    ),
                    if (widget.booking != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Advance already recorded: ₹${widget.booking!.advanceAmount}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: submitting
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: submitting ? null : _submit,
                        child: Text(submitting ? 'Starting…' : 'Start session'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: AppTheme.textSecondary),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
        ),
      ),
    ],
  );
}
