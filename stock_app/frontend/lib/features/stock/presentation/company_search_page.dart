import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'company_search_controller.dart';

class CompanySearchPage extends ConsumerStatefulWidget {
  const CompanySearchPage({super.key});

  @override
  ConsumerState<CompanySearchPage> createState() => _CompanySearchPageState();
}

class _CompanySearchPageState extends ConsumerState<CompanySearchPage> {

  bool _loaded = false;
  RangeValues? _rangeValues;

  Icon _sortIcon(SortField field, CompanySearchController controller) {

    if (controller.sortField != field) {
      return const Icon(Icons.unfold_more, size: 16);
    }

    if (controller.sortDir == SortDir.asc) {
      return const Icon(Icons.arrow_upward, size: 16);
    }

    if (controller.sortDir == SortDir.desc) {
      return const Icon(Icons.arrow_downward, size: 16);
    }

    return const Icon(Icons.unfold_more, size: 16);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_loaded) {
      _loaded = true;

      Future.microtask(() async {

        final controller = ref.read(companySearchControllerProvider);

        await controller.refreshFavoriteQuotes();

        if (!mounted) return;

        setState(() {
          _rangeValues = RangeValues(
            controller.priceMin,
            controller.priceMax,
          );
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final controller = ref.watch(companySearchControllerProvider);

    final minRange = controller.priceRangeMin;
    final maxRange = controller.priceRangeMax;

    _rangeValues ??= RangeValues(
      controller.priceMin,
      controller.priceMax,
    );

    return Scaffold(

      appBar: AppBar(
        title: const Text("お気に入り株価一覧"),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("銘柄追加"),
              onPressed: () {
                context.go('/');
              },
            ),
          )
        ],
      ),

      body: Column(
        children: [

          /// 検索
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              textAlign: TextAlign.center,
              onChanged: controller.setQuery,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "銘柄検索",
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),

          /// フィルター
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                ChoiceChip(
                  label: const Text("業種"),
                  selected: controller.tab == FilterTab.industry,
                  onSelected: (_) {
                    controller.setTab(FilterTab.industry);
                  },
                ),

                const SizedBox(width: 12),

                ChoiceChip(
                  label: const Text("株価"),
                  selected: controller.tab == FilterTab.price,
                  onSelected: (_) {
                    controller.setTab(FilterTab.price);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          /// 並び替え
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [

                OutlinedButton.icon(
                  onPressed: controller.toggleSortTicker,
                  icon: _sortIcon(SortField.ticker, controller),
                  label: const Text("コード"),
                ),

                OutlinedButton.icon(
                  onPressed: controller.toggleSortPrice,
                  icon: _sortIcon(SortField.price, controller),
                  label: const Text("株価"),
                ),

                OutlinedButton.icon(
                  onPressed: controller.toggleSortChange,
                  icon: _sortIcon(SortField.change, controller),
                  label: const Text("前日比"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          /// 株価レンジ
          if (controller.tab == FilterTab.price)
            Column(
              children: [

                Text(
                  "¥${_rangeValues!.start.toStringAsFixed(0)} ~ ¥${_rangeValues!.end.toStringAsFixed(0)}",
                ),

                RangeSlider(
                  values: _rangeValues!,
                  min: minRange,
                  max: maxRange,
                  onChanged: (values) {
                    setState(() {
                      _rangeValues = values;
                    });
                  },
                  onChangeEnd: (values) {
                    controller.setPriceSliderRange(
                      values.start,
                      values.end,
                    );
                  },
                ),
              ],
            ),

          const SizedBox(height: 8),

          /// 読み込み
          if (controller.loading)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "取得中... ${controller.done}/${controller.total}",
              ),
            ),

          /// リスト
          Expanded(
            child: ListView.separated(

              padding: const EdgeInsets.all(12),

              itemCount: controller.result.length,

              separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),

              itemBuilder: (context, index) {

                final company = controller.result[index];

                final isPlus = company.changePct >= 0;

                return Card(

                  elevation: 3,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: InkWell(

                    borderRadius: BorderRadius.circular(16),

                    onTap: () {
                      context.go('/stock/${company.code}');
                    },

                    child: Padding(

                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),

                      child: Row(
                        children: [

                          /// コード
                          CircleAvatar(
                            radius: 20,
                            child: Text(
                              company.code,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),

                          const SizedBox(width: 12),

                          /// 名前
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [

                                Text(
                                  company.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                Text(
                                  company.industry,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// 株価
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [

                              Text(
                                "¥${company.price.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                "${isPlus ? "+" : ""}${company.changePct.toStringAsFixed(2)}%",
                                style: TextStyle(
                                  color: isPlus
                                      ? Colors.red
                                      : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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