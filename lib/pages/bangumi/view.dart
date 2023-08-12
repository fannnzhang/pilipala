import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:pilipala/common/constants.dart';
import 'package:pilipala/common/widgets/http_error.dart';
import 'package:pilipala/pages/main/index.dart';
import 'package:pilipala/pages/rcmd/view.dart';
import 'package:pilipala/utils/storage.dart';

import 'controller.dart';
import 'widgets/bangumu_card_v.dart';

class BangumiPage extends StatefulWidget {
  const BangumiPage({super.key});

  @override
  State<BangumiPage> createState() => _BangumiPageState();
}

class _BangumiPageState extends State<BangumiPage>
    with AutomaticKeepAliveClientMixin {
  final BangumiController _bangumidController = Get.put(BangumiController());
  late Future? _futureBuilderFuture;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    ScrollController scrollController = _bangumidController.scrollController;
    StreamController<bool> mainStream =
        Get.find<MainController>().bottomBarStream;
    _futureBuilderFuture = _bangumidController.queryBangumiListFeed();
    scrollController.addListener(
      () async {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          if (!_bangumidController.isLoadingMore) {
            _bangumidController.isLoadingMore = true;
            await _bangumidController.onLoad();
          }
        }

        final ScrollDirection direction =
            scrollController.position.userScrollDirection;
        if (direction == ScrollDirection.forward) {
          mainStream.add(true);
        } else if (direction == ScrollDirection.reverse) {
          mainStream.add(false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.only(
          left: StyleString.safeSpace, right: StyleString.safeSpace),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(StyleString.imgRadius),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          await _bangumidController.queryBangumiListFeed(type: 'init');
          return _bangumidController.queryBangumiFollow();
        },
        child: CustomScrollView(
          controller: _bangumidController.scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Obx(
                () => Visibility(
                  visible: _bangumidController.userLogin.value,
                  child: Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 10, bottom: 10, left: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '最近追番',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 254,
                        child: FutureBuilder(
                          future: _bangumidController.queryBangumiFollow(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              Map data = snapshot.data as Map;
                              if (data['status']) {
                                return Obx(
                                  () => ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _bangumidController
                                        .bangumiFollowList.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        width: Get.size.width / 3,
                                        height: 254,
                                        margin: EdgeInsets.only(
                                            right: index <
                                                    _bangumidController
                                                            .bangumiFollowList
                                                            .length -
                                                        1
                                                ? StyleString.safeSpace
                                                : 0),
                                        child: BangumiCardV(
                                          bangumiItem: _bangumidController
                                              .bangumiFollowList[index],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              } else {
                                return SizedBox();
                              }
                            } else {
                              return SizedBox();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10, left: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '推荐',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.zero,
              sliver: FutureBuilder(
                future: _futureBuilderFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    Map data = snapshot.data as Map;
                    if (data['status']) {
                      return Obx(() => contentGrid(_bangumidController,
                          _bangumidController.bangumiList));
                    } else {
                      return HttpError(
                        errMsg: data['msg'],
                        fn: () => {},
                      );
                    }
                  } else {
                    return contentGrid(_bangumidController, []);
                  }
                },
              ),
            ),
            const LoadingMore()
          ],
        ),
      ),
    );
  }

  Widget contentGrid(ctr, bangumiList) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        // 行间距
        mainAxisSpacing: StyleString.cardSpace - 2,
        // 列间距
        crossAxisSpacing: StyleString.cardSpace,
        // 列数
        crossAxisCount: 3,
        mainAxisExtent: Get.size.width / 3 / 0.65 + 30,
      ),
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return bangumiList!.isNotEmpty
              ? BangumiCardV(bangumiItem: bangumiList[index])
              : const SizedBox();
        },
        childCount: bangumiList!.isNotEmpty ? bangumiList!.length : 10,
      ),
    );
  }
}
