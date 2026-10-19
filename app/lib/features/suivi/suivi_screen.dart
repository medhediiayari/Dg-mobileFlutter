import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/models.dart';
import '../../core/utils/format.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/carte_rc.dart';
import '../../ui/widgets/composants.dart';
import '../../ui/widgets/squelette.dart';
import '../rc/rc_providers.dart';

const List<Bucket> _buckets = [Bucket.pending, Bucket.rejected, Bucket.approved, Bucket.toReceive];

/// Tous les RC / avenants visibles par le rôle, filtrables et cherchables.
class SuiviScreen extends ConsumerStatefulWidget {
  const SuiviScreen({this.bucketInitial, super.key});

  /// Arrivée depuis un compteur de l'accueil (`/suivi?bucket=pending`).
  final Bucket? bucketInitial;

  @override
  ConsumerState<SuiviScreen> createState() => _SuiviScreenState();
}

class _SuiviScreenState extends ConsumerState<SuiviScreen> {
  late Bucket? _bucket = widget.bucketInitial;
  TypeDocument? _type;
  String _q = '';
  final _saisie = TextEditingController();
  Timer? _differe;

  @override
  void didUpdateWidget(SuiviScreen ancien) {
    super.didUpdateWidget(ancien);
    if (widget.bucketInitial != ancien.bucketInitial && widget.bucketInitial != null) {
      setState(() => _bucket = widget.bucketInitial);
    }
  }

  @override
  void dispose() {
    _differe?.cancel();
    _saisie.dispose();
    super.dispose();
  }

  // Recherche différée : pas une requête par frappe.
  void _surSaisie(String v) {
    _differe?.cancel();
    _differe = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _q = v.trim());
    });
    setState(() {});
  }

  FiltresListe get _filtres => FiltresListe(vue: 'tous', bucket: _bucket, type: _type, q: _q);

  @override
  Widget build(BuildContext context) {
    final p = context.dg;
    final filtres = _filtres;
    final liste = ref.watch(listeProvider(filtres));
    final premiere = liste.value?.premiere;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des documents'),
        automaticallyImplyLeading: false,
        titleSpacing: Espace.l,
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(bottom: BorderSide(color: p.bordure)),
            ),
            padding: const EdgeInsets.only(top: Espace.m, bottom: Espace.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Espace.l),
                  child: TextField(
                    controller: _saisie,
                    onChanged: _surSaisie,
                    textInputAction: TextInputAction.search,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: 'Chantier, lot, entreprise ou référence',
                      fillColor: p.fond,
                      prefixIcon: Icon(Icons.search_rounded, color: p.texteTertiaire),
                      suffixIcon: _saisie.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Effacer la recherche',
                              icon: Icon(Icons.cancel_rounded, color: p.texteTertiaire),
                              onPressed: () {
                                _saisie.clear();
                                _surSaisie('');
                              },
                            ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Rayon.m),
                        borderSide: BorderSide(color: p.fond),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(Espace.l, Espace.xs, Espace.l, 0),
                  child: Row(
                    children: [
                      Puce(libelle: 'Tous', actif: _bucket == null, onTap: () => setState(() => _bucket = null)),
                      for (final b in _buckets)
                        if (b != Bucket.toReceive || (premiere?.compteurs[Bucket.toReceive] ?? 0) > 0 || _bucket == b)
                          Puce(
                            libelle: premiere?.libellesBuckets[b] ?? b.libelleParDefaut,
                            compteur: premiere?.compteurs[b],
                            actif: _bucket == b,
                            onTap: () => setState(() => _bucket = _bucket == b ? null : b),
                          ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(Espace.l, 0, Espace.l, Espace.xs),
                  child: Row(
                    children: [
                      Puce(libelle: 'RC et avenants', actif: _type == null, onTap: () => setState(() => _type = null)),
                      Puce(
                        libelle: 'RC',
                        actif: _type == TypeDocument.rc,
                        onTap: () => setState(() => _type = TypeDocument.rc),
                      ),
                      Puce(
                        libelle: 'Avenants',
                        actif: _type == TypeDocument.avenant,
                        onTap: () => setState(() => _type = TypeDocument.avenant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _Liste(filtres: filtres, liste: liste),
          ),
        ],
      ),
    );
  }
}

class _Liste extends ConsumerWidget {
  const _Liste({required this.filtres, required this.liste});

  final FiltresListe filtres;
  final AsyncValue<EtatListe> liste;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.dg;
    if (liste.hasError && !liste.hasValue) {
      return EtatErreur(message: messageErreur(liste.error), onReessayer: () => ref.invalidate(listeProvider(filtres)));
    }
    final s = liste.value;
    if (s == null) return const SingleChildScrollView(child: ListeSquelette());
    final elements = s.elements;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 500) ref.read(listeProvider(filtres).notifier).chargerSuite();
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          try {
            ref.invalidate(listeProvider(filtres));
            await ref.read(listeProvider(filtres).future);
          } catch (_) {}
        },
        child: elements.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  EtatVide(
                    icone: Icons.search_off_rounded,
                    titre: 'Aucun document',
                    texte: 'Modifiez la recherche ou les filtres.',
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(Espace.l, Espace.m, Espace.l, Espace.xxl),
                itemCount: elements.length + 1 + (s.chargementSuite || s.erreurSuite != null ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: Espace.s, left: 2),
                      child: Row(
                        children: [
                          Text(
                            Format.pluriel(s.premiere.total, 'document'),
                            style: Typo.secondaire.copyWith(color: p.texteSecondaire),
                          ),
                          if (liste.isRefreshing) ...[const SizedBox(width: Espace.s), const Roue(taille: 12)],
                        ],
                      ),
                    );
                  }
                  final j = i - 1;
                  if (j >= elements.length) {
                    if (s.erreurSuite != null) {
                      return Center(
                        child: TextButton.icon(
                          onPressed: () => ref.read(listeProvider(filtres).notifier).chargerSuite(force: true),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Charger la suite'),
                        ),
                      );
                    }
                    return const Miroitement(child: CarteSquelette());
                  }
                  final rc = elements[j];
                  return CarteRc(rc: rc, onTap: () => context.push('/rc/${rc.id}'));
                },
              ),
      ),
    );
  }
}
