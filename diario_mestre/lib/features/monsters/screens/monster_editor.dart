import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/monster_model.dart';
import 'package:diario_mestre/features/notebook/models/notebook_page.dart';
import 'package:diario_mestre/providers/book_navigation_provider.dart'; // Import Provider
import 'package:diario_mestre/core/theme/colors.dart';
import '../widgets/stat_block_decoration.dart';

class MonsterEditor extends StatefulWidget {
  final NotebookPage page;
  final Function(NotebookPage) onSave;

  const MonsterEditor({super.key, required this.page, required this.onSave});

  @override
  State<MonsterEditor> createState() => _MonsterEditorState();
}

class _MonsterEditorState extends State<MonsterEditor> {
  late MonsterModel _monster;
  final _formKey = GlobalKey<FormState>();
  bool _hasChanges = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _loadMonster();
    _nameController = TextEditingController(text: _monster.name);
  }

  void _loadMonster() {
    try {
      if (widget.page.content.trim().isEmpty) {
        _monster = MonsterModel();
      } else {
        final json = jsonDecode(widget.page.content);
        // Verifica se é um conteúdo de Quill (lista) ou monstros (mapa)
        if (json is List) {
          _monster = MonsterModel(); // Se for Quill antigo, inicia zerado
        } else {
          _monster = MonsterModel.fromMap(json);
        }
      }
    } catch (e) {
      _monster = MonsterModel();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _monster.name = _nameController.text;
    });

    final content = _monster.toJson();
    final updatedPage = widget.page.copyWith(
      title:
          _monster.name, // Sincroniza o título da página com o nome do monstro
      content: content,
      updatedAt: DateTime.now(),
    );

    await widget.onSave(updatedPage);
    setState(() {
      _hasChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monstro salvo com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(
        16.0,
      ), // Margem externa para não colar na borda da página real
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.monsterSheetAccent.withValues(alpha: 0.5),
            width: 1,
          ), // Borda externa fina
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(4.0), // Espaço entre bordas
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.accentGold,
              width: 2,
            ), // Borda interna dourada
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              // Header com Nome e Botão Salvar (Estilizado)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Back to Index Button
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: const Icon(
                          Icons.pets,
                          size: 28,
                        ), // Grid/Index Icon
                        color: AppColors.accentGold,
                        tooltip: 'Voltar para o Índice',
                        onPressed: () {
                          // Fecha o livro (volta para o índice geral)
                          Provider.of<BookNavigationProvider>(
                            context,
                            listen: false,
                          ).closeBook();
                        },
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.libreBaskerville(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accentGold,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Nome do Monstro',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          _monster.name = val;
                          _markChanged();
                        },
                      ),
                    ),
                    if (_hasChanges)
                      IconButton(
                        onPressed: _save,
                        icon: const Icon(
                          Icons.save,
                          color: AppColors.accentGold,
                        ),
                        tooltip: 'Salvar',
                      ),
                  ],
                ),
              ),
              StatBlockDecoration.headerRule(),

              // Área de Rolagem do Stat Block
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBasicInfo(),
                        StatBlockDecoration.taperedRule(),

                        _buildDefensiveInfo(),
                        StatBlockDecoration.taperedRule(),

                        _buildStatsGrid(),
                        StatBlockDecoration.taperedRule(),

                        _buildSkillsAndSenses(),
                        StatBlockDecoration.taperedRule(),

                        _buildAbilitiesList('Traços', _monster.traits),
                        _buildAbilitiesSection('Ações', _monster.actions),
                        _buildAbilitiesSection(
                          'Ações Bônus',
                          _monster.bonusActions,
                        ),
                        _buildAbilitiesSection('Reações', _monster.reactions),

                        const SizedBox(height: 12),
                        if (_hasFooterInfo()) ...[
                          StatBlockDecoration.taperedRule(),
                          _buildFooterInfo(),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInlineField(
                _monster.size,
                (val) => _monster.size = val,
                style: GoogleFonts.libreBaskerville(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Text(
              ' ',
              style: GoogleFonts.libreBaskerville(
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
            Expanded(
              child: _buildInlineField(
                _monster.type,
                (val) => _monster.type = val,
                style: GoogleFonts.libreBaskerville(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Text(
              ', ',
              style: GoogleFonts.libreBaskerville(
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
            Expanded(
              child: _buildInlineField(
                _monster.alignment,
                (val) => _monster.alignment = val,
                style: GoogleFonts.libreBaskerville(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInlineField(
    String initialVal,
    Function(String) onChanged, {
    TextStyle? style,
  }) {
    return TextFormField(
      initialValue: initialVal,
      style:
          style ??
          GoogleFonts.libreBaskerville(fontSize: 14, color: AppColors.textDark),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
      ),
      onChanged: (val) {
        onChanged(val);
        _markChanged();
      },
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildAbilityColumn([
            _AbilityData(
              'FOR',
              _monster.strength,
              (v) => _monster.strength = v,
            ),
            _AbilityData(
              'DES',
              _monster.dexterity,
              (v) => _monster.dexterity = v,
            ),
            _AbilityData(
              'CON',
              _monster.constitution,
              (v) => _monster.constitution = v,
            ),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAbilityColumn([
            _AbilityData(
              'INT',
              _monster.intelligence,
              (v) => _monster.intelligence = v,
            ),
            _AbilityData('SAB', _monster.wisdom, (v) => _monster.wisdom = v),
            _AbilityData(
              'CAR',
              _monster.charisma,
              (v) => _monster.charisma = v,
            ),
          ], isMental: true), // Mental stats
        ),
      ],
    );
  }

  Widget _buildAbilityColumn(
    List<_AbilityData> abilities, {
    bool isMental = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isMental
            ? AppColors.primaryBlue.withValues(alpha: 0.15)
            : AppColors.monsterStatBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 4,
      ), // Reduced padding
      child: Column(
        children: [
          // Header Row: [Label 50] [MOD Flex 1] [SAVE Flex 1]
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const SizedBox(width: 75), // Matches Label width in Row
                Expanded(
                  child: Center(
                    child: Text(
                      'MOD',
                      style: GoogleFonts.libreBaskerville(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'SAVE',
                      style: GoogleFonts.libreBaskerville(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...abilities.map((ability) => _buildAbilityRow(ability)),
        ],
      ),
    );
  }

  Widget _buildAbilityRow(_AbilityData ability) {
    int mod = MonsterModel.calculateModifier(ability.value);
    bool isProficient = _monster.saveProficiencies[ability.label] ?? false;
    int saveBonus = mod + (isProficient ? _monster.proficiencyBonus : 0);
    String modSign = mod >= 0 ? '+' : '';
    String saveSign = saveBonus >= 0 ? '+' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // Label (30) + Input (20) = 50 Width -> Increased to 75
          SizedBox(
            width: 75,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ability.label,
                  style: GoogleFonts.libreBaskerville(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(
                  width: 20,
                  child: TextFormField(
                    initialValue: ability.value.toString(),
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.libreBaskerville(
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) {
                      int? n = int.tryParse(v);
                      if (n != null) {
                        setState(() {
                          ability.onChanged(n);
                          _markChanged();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Modifier
          Expanded(
            child: Center(
              child: Text(
                '$modSign$mod',
                style: GoogleFonts.libreBaskerville(
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
          // Save
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _monster.saveProficiencies[ability.label] = !isProficient;
                  _markChanged();
                });
              },
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: isProficient
                      ? BoxDecoration(
                          border: Border.all(
                            color: AppColors.monsterSheetAccent,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color: AppColors.monsterSheetAccent.withValues(
                            alpha: 0.1,
                          ),
                        )
                      : null,
                  child: Text(
                    '$saveSign$saveBonus',
                    style: GoogleFonts.libreBaskerville(
                      fontSize: 13,
                      fontWeight: isProficient
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefensiveInfo() {
    return Column(
      children: [
        _buildLineItem(
          'Classe de Armadura',
          _monster.armorClass.toString(),
          (val) => _monster.armorClass = int.tryParse(val) ?? 10,
          isNumber: true,
        ),
        // _buildLineItem('Pontos de Vida', '${_monster.hitPoints} (${_monster.hitPointsFormula})', (val) { /* Complex parsing ignored for MVP */ }),
        Row(
          children: [
            Text(
              'Pontos de Vida ',
              style: GoogleFonts.libreBaskerville(
                fontWeight: FontWeight.bold,
                color: AppColors.monsterSheetAccent,
              ),
            ),
            SizedBox(
              width: 40,
              child: _buildInlineNumber(
                _monster.hitPoints,
                (v) => _monster.hitPoints = v,
              ),
            ),
            Text(
              ' (',
              style: GoogleFonts.libreBaskerville(
                color: AppColors.monsterSheetAccent,
              ),
            ),
            SizedBox(
              width: 100, // Largura fixa para manter os parênteses próximos
              child: _buildInlineField(
                _monster.hitPointsFormula,
                (v) => _monster.hitPointsFormula = v,
              ),
            ),
            Text(
              ')',
              style: GoogleFonts.libreBaskerville(
                color: AppColors.monsterSheetAccent,
              ),
            ),
          ],
        ),
        _buildLineItem(
          'Deslocamento',
          _monster.speed,
          (val) => _monster.speed = val,
        ),
        // Initiative Row (Added)
        Row(
          children: [
            Text(
              'Iniciativa ',
              style: GoogleFonts.libreBaskerville(
                fontWeight: FontWeight.bold,
                color: AppColors.monsterSheetAccent,
              ),
            ),
            SizedBox(
              width: 40,
              child: _buildInlineNumber(
                _monster.initiative,
                (v) => _monster.initiative = v,
                showSign: true, // +5
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillsAndSenses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Simplified for MVP - Ideally these would be specialized widgets
        _buildLineItem('Sentidos', _monster.senses, (v) => _monster.senses = v),
        _buildLineItem(
          'Idiomas',
          _monster.languages,
          (v) => _monster.languages = v,
        ),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    'ND ',
                    style: GoogleFonts.libreBaskerville(
                      fontWeight: FontWeight.bold,
                      color: AppColors.monsterSheetAccent,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: _buildInlineNumber(
                      _monster.challengeRating.toInt(),
                      (v) => _monster.challengeRating = v.toDouble(),
                    ),
                  ),
                  Text(
                    ' (XP ',
                    style: GoogleFonts.libreBaskerville(
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: _buildInlineNumber(
                      _monster.xp,
                      (v) => _monster.xp = v,
                    ),
                  ),
                  Text(
                    ')',
                    style: GoogleFonts.libreBaskerville(
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLineItem(
    String label,
    String value,
    Function(String) onChanged, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: GoogleFonts.libreBaskerville(
              fontWeight: FontWeight.bold,
              color: AppColors.monsterSheetAccent,
            ),
          ),
          Expanded(
            child: isNumber
                ? TextFormField(
                    initialValue: value,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.libreBaskerville(
                      color: AppColors.monsterSheetAccent,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    onChanged: (v) {
                      onChanged(v);
                      _markChanged();
                    },
                  )
                : _buildInlineField(value, onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineNumber(
    int init,
    Function(int) onChange, {
    bool showSign = false,
  }) {
    // Se showSign for true e o número for positivo, adiciona '+'.
    // Mas o TextFormField espera valer 'init'.
    // Vamos apenas controlar a visualização inicial se fosse texto, mas aqui é input.
    // Melhor deixar o user digitar o sinal ou formatar na exibição fora?
    // O TextFormField para número geralmente não força o sinal visualmente enquanto edita.
    // Vamos manter simples: se showSign, o InitialValue pode ter o sinal? Não, é int.

    // Melhor abordagem: Mostrar o sinal apenas se for texto estático, mas aqui é editável.
    // Vamos ignorar o showSign no form field para evitar complexidade de parsing agora.

    return TextFormField(
      initialValue: init.toString(),
      keyboardType: TextInputType.numberWithOptions(signed: true),
      style: GoogleFonts.libreBaskerville(color: AppColors.monsterSheetAccent),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
      ),
      onChanged: (v) {
        int? n = int.tryParse(v);
        if (n != null) {
          onChange(n);
          _markChanged();
        }
      },
    );
  }

  Widget _buildAbilitiesList(String? title, List<MonsterAbility> list) {
    if (list.isEmpty && title == 'Traços') {
      return _buildAddButton(list, 'Adicionar Traço');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title != 'Traços') ...[
          Text(
            title,
            style: GoogleFonts.cinzel(
              fontSize: 20,
              color: AppColors.accentGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: AppColors.accentGold, thickness: 1.5),
        ],
        ...list.asMap().entries.map((entry) {
          int index = entry.key;
          MonsterAbility ability = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: ability.name,
                        style: GoogleFonts.libreBaskerville(
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textDark,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Nome da Habilidade',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) {
                          ability.name = v;
                          _markChanged();
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.red,
                      ),
                      onPressed: () => setState(() {
                        list.removeAt(index);
                        _markChanged();
                      }),
                    ),
                  ],
                ),
                TextFormField(
                  initialValue: ability.description,
                  maxLines: null,
                  style: GoogleFonts.libreBaskerville(
                    color: AppColors.textDark.withValues(alpha: 0.9),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Descrição...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) {
                    ability.description = v;
                    _markChanged();
                  },
                ),
              ],
            ),
          );
        }),
        _buildAddButton(list, 'Adicionar Habilidade'),
      ],
    );
  }

  Widget _buildAbilitiesSection(String title, List<MonsterAbility> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.cinzel(
            fontSize: 24,
            color: AppColors.monsterSheetAccent,
            fontWeight: FontWeight.normal,
          ),
        ),
        Container(
          height: 2,
          color: AppColors.monsterSheetAccent,
          margin: const EdgeInsets.only(bottom: 8),
        ),
        _buildAbilitiesList(null, list),
      ],
    );
  }

  Widget _buildFooterInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_monster.damageImmunities.isNotEmpty || _hasChanges)
          _buildFooterItem(
            'Imunidades',
            _monster.damageImmunities,
            (v) => _monster.damageImmunities = v,
          ),
        if (_monster.damageResistances.isNotEmpty || _hasChanges)
          _buildFooterItem(
            'Resistências',
            _monster.damageResistances,
            (v) => _monster.damageResistances = v,
          ),
        if (_monster.conditionImmunities.isNotEmpty || _hasChanges)
          _buildFooterItem(
            'Imunidades a Condição',
            _monster.conditionImmunities,
            (v) => _monster.conditionImmunities = v,
          ),
        if (_monster.damageVulnerabilities.isNotEmpty || _hasChanges)
          _buildFooterItem(
            'Vulnerabilidades',
            _monster.damageVulnerabilities,
            (v) => _monster.damageVulnerabilities = v,
          ),
      ],
    );
  }

  Widget _buildFooterItem(
    String label,
    String value,
    Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.libreBaskerville(
              fontWeight: FontWeight.bold,
              color: AppColors.monsterStatGreen, // Verde estilo D&D 5e
            ),
          ),
          Expanded(
            child: _buildInlineField(
              value.isEmpty ? '-' : value,
              onChanged,
              style: GoogleFonts.libreBaskerville(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasFooterInfo() {
    return _monster.damageImmunities.isNotEmpty ||
        _monster.damageResistances.isNotEmpty ||
        _monster.conditionImmunities.isNotEmpty ||
        _monster.damageVulnerabilities.isNotEmpty;
  }

  Widget _buildAddButton(List<MonsterAbility> list, String label) {
    return Center(
      child: TextButton.icon(
        icon: const Icon(Icons.add, size: 16, color: Colors.grey),
        label: Text(label, style: const TextStyle(color: Colors.grey)),
        onPressed: () {
          setState(() {
            list.add(MonsterAbility(name: 'Nova Habilidade', description: ''));
            _markChanged();
          });
        },
      ),
    );
  }
}

class _AbilityData {
  final String label;
  final int value;
  final Function(int) onChanged;
  _AbilityData(this.label, this.value, this.onChanged);
}
