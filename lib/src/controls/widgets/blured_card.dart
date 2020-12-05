import 'dart:ui';

import 'package:flutter/material.dart';

class BluredCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final bool isBorderEnabled;
  final Color borderColor;
  const BluredCard(
      {Key key,
      @required this.child,
      this.borderRadius = 0.0,
      this.isBorderEnabled = false,
      this.borderColor})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            children: [
              BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 5.0,
                    sigmaY: 5.0,
                  ),
                  child: Opacity(
                    opacity: 0.8,
                    child: Container(
                        decoration: isBorderEnabled
                            ? BoxDecoration(
                                border: Border.all(
                                  color: borderColor ??
                                      Color.fromRGBO(221, 78, 71, 1),
                                ),
                                borderRadius:
                                    BorderRadius.circular(borderRadius),
                              )
                            : BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(borderRadius),
                              ),
                        child: child),
                  )),
              Container(
                  decoration: isBorderEnabled
                      ? BoxDecoration(
                          color: Color.fromRGBO(141, 141, 151, 0.15),
                          border: Border.all(
                            color:
                                borderColor ?? Color.fromRGBO(221, 78, 71, 1),
                          ),
                          borderRadius: BorderRadius.circular(borderRadius),
                        )
                      : BoxDecoration(
                          color: Color.fromRGBO(141, 141, 151, 0.15),
                          borderRadius: BorderRadius.circular(borderRadius),
                        ),
                  child: child),
            ],
          )),
    );
  }
}
