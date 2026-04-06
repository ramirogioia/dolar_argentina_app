import 'package:flutter/material.dart';

/// Observador raíz para [RouteAware] (p. ej. reintentar banner al volver a una pantalla).
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
