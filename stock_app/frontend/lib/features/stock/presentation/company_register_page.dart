import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'company_search_controller.dart';

class CompanyRegisterPage extends ConsumerStatefulWidget {
  const CompanyRegisterPage({super.key});

  @override
  ConsumerState<CompanyRegisterPage> createState() =>
      _CompanyRegisterPageState();
}

class _CompanyRegisterPageState extends ConsumerState<CompanyRegisterPage> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_loaded) {
      _loaded = true;
      Future.microtask(() {
        ref.read(companySearchControllerProvider).load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(companySearchControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('お気に入り登録'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () async {
                await ref
                    .read(companySearchControllerProvider)
                    .refreshFavoriteQuotes();

                if (!context.mounted) return;
                context.go('/stocks');
              },
              child: const Text(
                '完了',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              textAlign: TextAlign.center,
              onChanged: controller.setQuery,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '企業名・銘柄コード・業種で検索',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          if (controller.loading)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '読み込み中... ${controller.done}/${controller.total}',
                textAlign: TextAlign.center,
              ),
            ),

          if (controller.lastError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                controller.lastError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          Expanded(
            child: controller.registerList.isEmpty
                ? const Center(
                    child: Text(
                      '表示できる企業がありません',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: controller.registerList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final company = controller.registerList[index];

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            child: Text(
                              company.code,
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          title: Text(
                            company.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${company.code} / ${company.industry}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              company.favorite
                                  ? Icons.star
                                  : Icons.star_border,
                              color: company.favorite
                                  ? Colors.amber
                                  : theme.iconTheme.color,
                            ),
                            onPressed: () {
                              ref
                                  .read(companySearchControllerProvider)
                                  .toggleFavorite(company);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}