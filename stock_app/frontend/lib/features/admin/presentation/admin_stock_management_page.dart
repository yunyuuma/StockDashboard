import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/admin_stock_repository.dart';

class AdminStockManagementPage extends StatefulWidget {
  const AdminStockManagementPage({super.key});

  @override
  State<AdminStockManagementPage> createState() => _AdminStockManagementPageState();
}

class _AdminStockManagementPageState extends State<AdminStockManagementPage> {
  final _repository = AdminStockRepository();
  final _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<AdminStock> _stocks = [];

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _repository.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<AdminStock> get _filteredStocks {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _stocks;

    return _stocks.where((s) {
      return s.code.toLowerCase().contains(q) ||
          s.name.toLowerCase().contains(q) ||
          s.market.toLowerCase().contains(q) ||
          s.sector.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stocks = await _repository.fetchStocks();
      if (!mounted) return;
      setState(() {
        _stocks = stocks;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openEditDialog({AdminStock? stock}) async {
    final result = await showDialog<AdminStock>(
      context: context,
      builder: (_) => _StockEditDialog(stock: stock),
    );

    if (result == null) return;

    try {
      if (stock == null) {
        final created = await _repository.createStock(
          code: result.code,
          name: result.name,
          market: result.market,
          sector: result.sector,
        );

        if (!mounted) return;
        setState(() {
          _stocks = [..._stocks, created]
            ..sort((a, b) => a.code.compareTo(b.code));
        });
      } else {
        final updated = await _repository.updateStock(
          code: stock.code,
          name: result.name,
          market: result.market,
          sector: result.sector,
        );

        if (!mounted) return;
        setState(() {
          _stocks = _stocks.map((e) {
            if (e.code == updated.code) return updated;
            return e;
          }).toList();
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(stock == null ? '銘柄を追加しました。' : '銘柄を更新しました。')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e')),
      );
    }
  }

  Future<void> _delete(AdminStock stock) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('銘柄削除'),
        content: Text('${stock.code} ${stock.name} を削除しますか？\n関連するお気に入り・企業情報も削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _repository.deleteStock(stock.code);

      if (!mounted) return;
      setState(() {
        _stocks = _stocks.where((e) => e.code != stock.code).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('銘柄を削除しました。')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredStocks;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          '銘柄管理',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/admin'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: '再読込',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => _openEditDialog(),
              icon: const Icon(Icons.add),
              label: const Text('追加'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '銘柄コード・銘柄名・市場・業種で検索',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (_) {
                if (_loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (list.isEmpty) {
                  return const Center(child: Text('銘柄がありません。'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final stock = list[index];

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        title: Text(
                          '${stock.code}  ${stock.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${stock.market} / ${stock.sector}'),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              onPressed: () => _openEditDialog(stock: stock),
                              icon: const Icon(Icons.edit),
                              tooltip: '編集',
                            ),
                            IconButton(
                              onPressed: () => _delete(stock),
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red,
                              tooltip: '削除',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StockEditDialog extends StatefulWidget {
  const _StockEditDialog({this.stock});

  final AdminStock? stock;

  @override
  State<_StockEditDialog> createState() => _StockEditDialogState();
}

class _StockEditDialogState extends State<_StockEditDialog> {
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _marketController;
  late final TextEditingController _sectorController;

  @override
  void initState() {
    super.initState();
    final stock = widget.stock;

    _codeController = TextEditingController(text: stock?.code ?? '');
    _nameController = TextEditingController(text: stock?.name ?? '');
    _marketController = TextEditingController(text: stock?.market ?? '');
    _sectorController = TextEditingController(text: stock?.sector ?? '');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _marketController.dispose();
    _sectorController.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _codeController.text.trim();
    final name = _nameController.text.trim();
    final market = _marketController.text.trim();
    final sector = _sectorController.text.trim();

    if (code.isEmpty || name.isEmpty || market.isEmpty || sector.isEmpty) {
      return;
    }

    Navigator.pop(
      context,
      AdminStock(
        code: code,
        name: name,
        market: market,
        sector: sector,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.stock != null;

    return AlertDialog(
      title: Text(isEdit ? '銘柄編集' : '銘柄追加'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codeController,
              enabled: !isEdit,
              decoration: const InputDecoration(
                labelText: '銘柄コード',
              ),
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '銘柄名',
              ),
            ),
            TextField(
              controller: _marketController,
              decoration: const InputDecoration(
                labelText: '市場',
              ),
            ),
            TextField(
              controller: _sectorController,
              decoration: const InputDecoration(
                labelText: '業種',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEdit ? '更新' : '追加'),
        ),
      ],
    );
  }
}