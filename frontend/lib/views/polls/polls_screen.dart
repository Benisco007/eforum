import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/models/poll_model.dart';
import '../../data/repositories/poll_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';

const _ink     = Color(0xFF07090F);
const _surface = Color(0xFF0E1119);
const _card    = Color(0xFF131824);
const _line    = Color(0xFF1C2236);
const _neon    = Color(0xFF00E676);
const _txt     = Color(0xFFCDD5F0);
const _mut     = Color(0xFF485070);
const _chat    = Color(0xFFFF8A65);   // couleur sondage

// ─── Provider auteur ─────────────────────────────────────────────────────────

final _pollAuthorProvider =
    FutureProvider.family<String, String>((ref, uid) async {
  final user = await UserRepository().getUserById(uid);
  return user?.username ?? 'Joueur';
});

// ═══════════════════════════════════════════════════════════════════════════════
// POLL CARD
// ═══════════════════════════════════════════════════════════════════════════════

class PollCard extends ConsumerStatefulWidget {
  final PollModel poll;
  const PollCard({super.key, required this.poll});

  @override
  ConsumerState<PollCard> createState() => _PollCardState();
}

class _PollCardState extends ConsumerState<PollCard> {
  String? _userVote;          // optionId choisi, null = pas encore voté
  bool    _loading = true;
  bool    _voting  = false;

  @override
  void initState() {
    super.initState();
    _loadUserVote();
  }

  Future<void> _loadUserVote() async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) { setState(() => _loading = false); return; }
    final vote = await PollRepository().getUserVote(pollId: widget.poll.pollId, userId: uid);
    if (mounted) setState(() { _userVote = vote; _loading = false; });
  }

  Future<void> _vote(String optionId) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null || _userVote != null || _voting || widget.poll.isExpired) return;
    setState(() => _voting = true);
    try {
      await PollRepository().vote(pollId: widget.poll.pollId, userId: uid, optionId: optionId);
      if (mounted) setState(() { _userVote = optionId; _voting = false; });
    } catch (_) {
      if (mounted) setState(() => _voting = false);
    }
  }

  void _showPollMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(4)),
            ),
            ListTile(
              leading: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: const Color(0xFFEF5350).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF5350), size: 18),
              ),
              title: const Text('Supprimer le sondage', style: TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.w600, fontSize: 14.5)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce sondage ?', style: TextStyle(color: _txt, fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Cette action est irréversible.', style: TextStyle(color: _mut, fontSize: 13.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: _mut, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final uid = ref.read(currentUserProvider)?.uid;
              if (uid == null) return;
              try {
                await PollRepository().deletePoll(pollId: widget.poll.pollId, userId: uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sondage supprimé', style: TextStyle(color: _txt)),
                      backgroundColor: _card,
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de la suppression', style: TextStyle(color: _txt)),
                      backgroundColor: _card,
                    ),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final poll     = widget.poll;
    final hasVoted = _userVote != null;
    final author   = ref.watch(_pollAuthorProvider(poll.authorId)).valueOrNull ?? '';
    final timeStr  = timeago.format(poll.createdAt.toDate(), locale: 'fr');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ──────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _chat.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.poll_rounded, color: _chat, size: 13),
                      const SizedBox(width: 4),
                      const Text('Sondage', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _chat)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(author, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _txt)),
                const SizedBox(width: 6),
                Text('· $timeStr', style: const TextStyle(fontSize: 12, color: _mut)),
                if (poll.isExpired) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: _mut.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Terminé', style: TextStyle(fontSize: 10, color: _mut, fontWeight: FontWeight.w600)),
                  ),
                ],
                const Spacer(),
                if (ref.watch(currentUserProvider)?.uid == poll.authorId)
                  GestureDetector(
                    onTap: _showPollMenu,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Icon(Icons.more_horiz_rounded, color: _mut, size: 20),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Question ─────────────────────────────────────────────────────
            Text(poll.question,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _txt, height: 1.4)),
            const SizedBox(height: 14),

            // ── Options ──────────────────────────────────────────────────────
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(color: _chat, strokeWidth: 2),
              ))
            else
              ...poll.options.map((opt) {
                final isChosen = _userVote == opt.id;
                final pct = poll.totalVotes > 0
                    ? (opt.votes / poll.totalVotes)
                    : 0.0;
                final pctLabel = '${(pct * 100).round()}%';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => _vote(opt.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 44,
                      decoration: BoxDecoration(
                        color: isChosen ? _chat.withOpacity(0.12) : _surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isChosen ? _chat : _line,
                          width: isChosen ? 1.5 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            // Barre de progression
                            if (hasVoted)
                              Positioned.fill(
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: pct,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isChosen
                                          ? _chat.withOpacity(0.18)
                                          : _mut.withOpacity(0.08),
                                    ),
                                  ),
                                ),
                              ),
                            // Contenu
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  if (isChosen)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Icon(Icons.check_circle_rounded, color: _chat, size: 16),
                                    ),
                                  Expanded(
                                    child: Text(opt.text,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isChosen ? FontWeight.w700 : FontWeight.w500,
                                          color: isChosen ? _txt : _mut,
                                        )),
                                  ),
                                  if (hasVoted)
                                    Text(pctLabel,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isChosen ? _chat : _mut,
                                        )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 6),
            Text(
              '${poll.totalVotes} vote${poll.totalVotes != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 12, color: _mut),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CREATE POLL SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class CreatePollSheet extends ConsumerStatefulWidget {
  const CreatePollSheet({super.key});

  @override
  ConsumerState<CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends ConsumerState<CreatePollSheet> {
  final _questionCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _publishing = false;
  int _selectedDuration = 1; // jours, 0 = illimité

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _optionCtrls) c.dispose();
    super.dispose();
  }

  bool get _canPublish {
    if (_questionCtrl.text.trim().isEmpty) return false;
    final filled = _optionCtrls.where((c) => c.text.trim().isNotEmpty).length;
    return filled >= 2;
  }

  void _addOption() {
    if (_optionCtrls.length >= 5) return;
    setState(() => _optionCtrls.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_optionCtrls.length <= 2) return;
    setState(() {
      _optionCtrls[index].dispose();
      _optionCtrls.removeAt(index);
    });
  }

  Future<void> _publish() async {
    if (!_canPublish || _publishing) return;
    setState(() => _publishing = true);

    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) { setState(() => _publishing = false); return; }

    final options = _optionCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    try {
      await PollRepository().createPoll(
        authorId:    uid,
        question:    _questionCtrl.text.trim(),
        optionTexts: options,
        duration:    _selectedDuration > 0
            ? Duration(days: _selectedDuration)
            : null,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la création du sondage', style: TextStyle(color: _txt)),
            backgroundColor: _card,
          ),
        );
        setState(() => _publishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poignée
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),

            // Titre
            Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: _chat.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.poll_rounded, color: _chat, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('Créer un sondage',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _txt)),
              ],
            ),
            const SizedBox(height: 20),

            // Question
            const Text('QUESTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _mut, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _line),
              ),
              child: TextField(
                controller: _questionCtrl,
                onChanged: (_) => setState(() {}),
                maxLines: 2,
                style: const TextStyle(color: _txt, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Quel est ton meilleur joueur du monde ?',
                  hintStyle: TextStyle(color: _mut),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Options
            const Text('OPTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _mut, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            ...List.generate(_optionCtrls.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _line),
                        ),
                        child: TextField(
                          controller: _optionCtrls[i],
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(color: _txt, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Option ${i + 1}',
                            hintStyle: const TextStyle(color: _mut),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    if (_optionCtrls.length > 2) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeOption(i),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _line),
                          ),
                          child: const Icon(Icons.close_rounded, color: _mut, size: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            // Ajouter option
            if (_optionCtrls.length < 5)
              GestureDetector(
                onTap: _addOption,
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _chat.withOpacity(0.3), style: BorderStyle.solid),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: _chat, size: 16),
                      const SizedBox(width: 6),
                      const Text('Ajouter une option', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _chat)),
                    ],
                  ),
                ),
              ),

            // Durée
            const Text('DURÉE DU SONDAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _mut, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _DurationChip(label: '1 jour',   value: 1,  selected: _selectedDuration == 1,  onTap: () => setState(() => _selectedDuration = 1)),
                  const SizedBox(width: 8),
                  _DurationChip(label: '3 jours',  value: 3,  selected: _selectedDuration == 3,  onTap: () => setState(() => _selectedDuration = 3)),
                  const SizedBox(width: 8),
                  _DurationChip(label: '7 jours',  value: 7,  selected: _selectedDuration == 7,  onTap: () => setState(() => _selectedDuration = 7)),
                  const SizedBox(width: 8),
                  _DurationChip(label: 'Illimité', value: 0,  selected: _selectedDuration == 0,  onTap: () => setState(() => _selectedDuration = 0)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bouton publier
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _canPublish ? _publish : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _chat,
                  disabledBackgroundColor: _chat.withOpacity(0.25),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _publishing
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Publier le sondage',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final int    value;
  final bool   selected;
  final VoidCallback onTap;

  const _DurationChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _chat.withOpacity(0.12) : _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? _chat : _line, width: selected ? 1.5 : 1),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: selected ? _chat : _mut,
            )),
      ),
    );
  }
}
