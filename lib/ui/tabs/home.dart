import 'dart:async';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:cherry/models/launch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:row_collection/row_collection.dart';
import 'package:scoped_model/scoped_model.dart';

import '../../models/details_capsule.dart';
import '../../models/details_core.dart';
import '../../models/launchpad.dart';
import '../../models/spacex_home.dart';
import '../../util/menu.dart';
import '../../widgets/dialog_round.dart';
import '../../widgets/header_swiper.dart';
import '../../widgets/list_cell.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/sliver_bar.dart';
import '../../widgets/launch_countdown.dart';
import '../pages/capsule.dart';
import '../pages/core.dart';
import '../pages/launch.dart';
import '../pages/launchpad.dart';

/// SPACEX HOME TAB
/// This tab holds main information about the next launch.
/// It has a countdown widget.
class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => new _HomeTabState();
}
class _HomeTabState extends State<HomeTab> {

  ScrollController _scrollController;

  Future<Null> _onRefresh(SpacexHomeModel model) {
    Completer<Null> completer = Completer<Null>();
    model.refresh().then((context) => completer.complete());
    return completer.future;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(() => setState(() {}));
  }

  Widget _typeContainer(Launch launch) {

    double _silverBarHeight = MediaQuery.of(context).size.height * SliverBar().height;

    // Select counter or link to video
    Widget _typeContainer = 
      launch.launchDate.isAfter(DateTime.now()) 
        ? LaunchCountdown(launch) 
        : InkWell(
        onTap: () async => await FlutterWebBrowser.openWebPage(
              url: launch.getVideo,
              androidToolbarColor: Theme.of(context).primaryColor,
            ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.play_arrow, size: 30),
            Separator.smallSpacer(),
            Text(
              FlutterI18n.translate(
                context,
                'spacex.home.tab.live_mission',
              ).toUpperCase(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headline,
            ),
          ],
        ),
      );
    
    // When scroll 20% of TopBar size, counter or link to video disappear
    return AnimatedOpacity(
            opacity: _scrollController.hasClients && _scrollController.offset > _silverBarHeight/5 ? 0.0 : 1.0,
            duration: Duration(milliseconds: 350),
            child: _typeContainer
          );
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<SpacexHomeModel>(
      builder: (context, child, model) => Scaffold(
            body: RefreshIndicator(
              onRefresh: () => _onRefresh(model),
              child: CustomScrollView(
                  controller: _scrollController,
                  key: PageStorageKey('spacex_home'),
                  slivers: <Widget>[
                    SliverBar(
                      title: FlutterI18n.translate(
                        context,
                        'spacex.home.title',
                      ),
                      header: model.isLoading
                          ? LoadingIndicator()
                          : Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                SwiperHeader(list: model.photos),
                                _typeContainer(model.launch),
                              ],
                            ),
                      actions: <Widget>[
                        PopupMenuButton<String>(
                          itemBuilder: (context) => Menu.home.keys
                              .map((string) => PopupMenuItem(
                                    value: string,
                                    child: Text(
                                      FlutterI18n.translate(context, string),
                                    ),
                                  ))
                              .toList(),
                          onSelected: (text) => Navigator.pushNamed(
                                context,
                                Menu.home[text],
                              ),
                        ),
                      ],
                    ),
                    model.isLoading
                        ? SliverFillRemaining(child: LoadingIndicator())
                        : SliverToBoxAdapter(child: _buildBody())
                  ]),
            ),
          ),
    );
  }

  Widget _buildBody() {
    return ScopedModelDescendant<SpacexHomeModel>(
      builder: (context, child, model) => Column(children: <Widget>[
            ListCell.icon(
              icon: Icons.public,
              trailing: Icon(Icons.chevron_right),
              title: model.vehicle(context),
              subtitle: model.payload(context),
              onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LaunchPage(model.launch),
                    ),
                  ),
            ),
            Separator.divider(indent: 72),
            ListCell.icon(
              icon: Icons.event,
              trailing: Icon(Icons.chevron_right),
              title: FlutterI18n.translate(
                context,
                'spacex.home.tab.date.title',
              ),
              subtitle: model.launchDate(context),
              onTap: () => Add2Calendar.addEvent2Cal(
                    Event(
                      title: model.launch.name,
                      description: model.launch.details ??
                          FlutterI18n.translate(
                            context,
                            'spacex.launch.page.no_description',
                          ),
                      location: model.launch.launchpadName,
                      startDate: model.launch.launchDate,
                      endDate: model.launch.launchDate.add(
                        Duration(minutes: 30),
                      ),
                    ),
                  ),
            ),
            Separator.divider(indent: 72),
            ListCell.icon(
              icon: Icons.location_on,
              trailing: Icon(Icons.chevron_right),
              title: FlutterI18n.translate(
                context,
                'spacex.home.tab.launchpad.title',
              ),
              subtitle: model.launchpad(context),
              onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScopedModel<LaunchpadModel>(
                            model: LaunchpadModel(
                              model.launch.launchpadId,
                              model.launch.launchpadName,
                            )..loadData(),
                            child: LaunchpadPage(),
                          ),
                      fullscreenDialog: true,
                    ),
                  ),
            ),
            Separator.divider(indent: 72),
            ListCell.icon(
              icon: Icons.timer,
              title: FlutterI18n.translate(
                context,
                'spacex.home.tab.static_fire.title',
              ),
              subtitle: model.staticFire(context),
            ),
            Separator.divider(indent: 72),
            model.launch.rocket.hasFairing
                ? ListCell.icon(
                    icon: Icons.directions_boat,
                    title: FlutterI18n.translate(
                      context,
                      'spacex.home.tab.fairings.title',
                    ),
                    subtitle: model.fairings(context),
                  )
                : AbsorbPointer(
                    absorbing: model.launch.rocket.secondStage
                            .getPayload(0)
                            .capsuleSerial ==
                        null,
                    child: ListCell.icon(
                      icon: Icons.shopping_basket,
                      trailing: Icon(
                        Icons.chevron_right,
                        color: model.launch.rocket.secondStage
                                    .getPayload(0)
                                    .capsuleSerial ==
                                null
                            ? Theme.of(context).disabledColor
                            : Theme.of(context).iconTheme.color,
                      ),
                      title: FlutterI18n.translate(
                        context,
                        'spacex.home.tab.capsule.title',
                      ),
                      subtitle: model.capsule(context),
                      onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ScopedModel<CapsuleModel>(
                                    model: CapsuleModel(
                                      model.launch.rocket.secondStage
                                          .getPayload(0)
                                          .capsuleSerial,
                                    )..loadData(),
                                    child: CapsulePage(),
                                  ),
                              fullscreenDialog: true,
                            ),
                          ),
                    ),
                  ),
            Separator.divider(indent: 72),
            AbsorbPointer(
              absorbing: model.launch.rocket.isFirstStageNull,
              child: ListCell.icon(
                icon: Icons.autorenew,
                trailing: Icon(
                  Icons.chevron_right,
                  color: model.launch.rocket.isFirstStageNull
                      ? Theme.of(context).disabledColor
                      : Theme.of(context).iconTheme.color,
                ),
                title: FlutterI18n.translate(
                  context,
                  'spacex.home.tab.first_stage.title',
                ),
                subtitle: model.firstStage(context),
                onTap: () => model.launch.rocket.isHeavy
                    ? showHeavyDialog(context, model)
                    : openCorePage(
                        context,
                        model.launch.rocket.getSingleCore.id,
                      ),
              ),
            ),
            Separator.divider(indent: 72)
          ]),
    );
  }

  showHeavyDialog(BuildContext context, SpacexHomeModel model) {
    showDialog(
      context: context,
      builder: (context) => RoundDialog(
            title: FlutterI18n.translate(
              context,
              'spacex.home.tab.first_stage.heavy_dialog.title',
            ),
            children: model.launch.rocket.firstStage
                .map((core) => AbsorbPointer(
                      absorbing: core.id == null,
                      child: ListCell(
                        trailing: Icon(
                          Icons.chevron_right,
                          color: core.id == null
                              ? Theme.of(context).textTheme.caption.color
                              : Theme.of(context).textTheme.title.color,
                        ),
                        title: core.id != null
                            ? FlutterI18n.translate(
                                context,
                                'spacex.dialog.vehicle.title_core',
                                {'serial': core.id},
                              )
                            : FlutterI18n.translate(
                                context,
                                'spacex.home.tab.first_stage.heavy_dialog.core_null_title',
                              ),
                        subtitle: model.core(context, core),
                        onTap: () => openCorePage(
                              context,
                              core.id,
                            ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 24,
                        ),
                      ),
                    ))
                .toList(),
          ),
    );
  }

  openCorePage(BuildContext context, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScopedModel<CoreModel>(
              model: CoreModel(id)..loadData(),
              child: CoreDialog(),
            ),
        fullscreenDialog: true,
      ),
    );
  }

}
