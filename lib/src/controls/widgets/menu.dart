import 'package:better_player/src/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';

class Menu extends StatelessWidget {
  const Menu({
    Key key,
    @required this.children,
  }) : super(key: key);

  final Widget children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
            blurRadius: 90,
            spreadRadius: 110,
            color: AppTheme.backgroundColor.withOpacity(.7))
      ]),
      child: SizedBox(
          width: 80,
          height: MediaQuery.of(context).size.height / 1.5,
          child: children),
    );
  }
}

class ModalEntry extends StatelessWidget {
  const ModalEntry({
    Key key,
    this.onClose,
    this.menu,
    this.visible,
    this.menuAnchor,
    this.childAnchor,
    this.child,
  }) : super(key: key);

  final VoidCallback onClose;
  final Widget menu;
  final bool visible;
  final Widget child;
  final Alignment menuAnchor;
  final Alignment childAnchor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: visible ? onClose : null,
      child: PortalEntry(
        visible: visible,
        portal: menu,
        portalAnchor: menuAnchor,
        childAnchor: childAnchor,
        child: IgnorePointer(
          ignoring: visible,
          child: child,
        ),
      ),
    );
  }
}
