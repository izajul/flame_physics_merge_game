

import 'package:flame_forge2d/flame_forge2d.dart';

class BodyWithDataComponent<T extends Forge2DGame> extends BodyComponent<T> {
  BodyWithDataComponent({
    super.key,
    super.bodyDef,
    super.children,
    super.fixtureDefs,
    super.paint,
    super.priority,
    super.renderBody,
    this.extraData,
  });

  final Object? extraData;

  @override
  Body createBody() {
    final body = world.createBody(super.bodyDef!)..userData = this;
    fixtureDefs?.forEach(body.createFixture);
    return body;
  }
}