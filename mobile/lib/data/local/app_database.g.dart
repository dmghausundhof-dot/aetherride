// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BikesTable extends Bikes with TableInfo<$BikesTable, BikeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BikesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
      'brand', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
      'year', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _wheelSizeMeta =
      const VerificationMeta('wheelSize');
  @override
  late final GeneratedColumn<String> wheelSize = GeneratedColumn<String>(
      'wheel_size', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _odometerKmMeta =
      const VerificationMeta('odometerKm');
  @override
  late final GeneratedColumn<double> odometerKm = GeneratedColumn<double>(
      'odometer_km', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        category,
        brand,
        model,
        year,
        wheelSize,
        odometerKm,
        isActive,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bikes';
  @override
  VerificationContext validateIntegrity(Insertable<BikeRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
          _brandMeta, brand.isAcceptableOrUnknown(data['brand']!, _brandMeta));
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    }
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    }
    if (data.containsKey('wheel_size')) {
      context.handle(_wheelSizeMeta,
          wheelSize.isAcceptableOrUnknown(data['wheel_size']!, _wheelSizeMeta));
    }
    if (data.containsKey('odometer_km')) {
      context.handle(
          _odometerKmMeta,
          odometerKm.isAcceptableOrUnknown(
              data['odometer_km']!, _odometerKmMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BikeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BikeRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      brand: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}brand']),
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model']),
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year']),
      wheelSize: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}wheel_size']),
      odometerKm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}odometer_km'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BikesTable createAlias(String alias) {
    return $BikesTable(attachedDatabase, alias);
  }
}

class BikeRow extends DataClass implements Insertable<BikeRow> {
  final String id;
  final String name;
  final String category;
  final String? brand;
  final String? model;
  final int? year;
  final String? wheelSize;
  final double odometerKm;
  final bool isActive;
  final DateTime updatedAt;
  const BikeRow(
      {required this.id,
      required this.name,
      required this.category,
      this.brand,
      this.model,
      this.year,
      this.wheelSize,
      required this.odometerKm,
      required this.isActive,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || wheelSize != null) {
      map['wheel_size'] = Variable<String>(wheelSize);
    }
    map['odometer_km'] = Variable<double>(odometerKm);
    map['is_active'] = Variable<bool>(isActive);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BikesCompanion toCompanion(bool nullToAbsent) {
    return BikesCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      brand:
          brand == null && nullToAbsent ? const Value.absent() : Value(brand),
      model:
          model == null && nullToAbsent ? const Value.absent() : Value(model),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      wheelSize: wheelSize == null && nullToAbsent
          ? const Value.absent()
          : Value(wheelSize),
      odometerKm: Value(odometerKm),
      isActive: Value(isActive),
      updatedAt: Value(updatedAt),
    );
  }

  factory BikeRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BikeRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      brand: serializer.fromJson<String?>(json['brand']),
      model: serializer.fromJson<String?>(json['model']),
      year: serializer.fromJson<int?>(json['year']),
      wheelSize: serializer.fromJson<String?>(json['wheelSize']),
      odometerKm: serializer.fromJson<double>(json['odometerKm']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'brand': serializer.toJson<String?>(brand),
      'model': serializer.toJson<String?>(model),
      'year': serializer.toJson<int?>(year),
      'wheelSize': serializer.toJson<String?>(wheelSize),
      'odometerKm': serializer.toJson<double>(odometerKm),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BikeRow copyWith(
          {String? id,
          String? name,
          String? category,
          Value<String?> brand = const Value.absent(),
          Value<String?> model = const Value.absent(),
          Value<int?> year = const Value.absent(),
          Value<String?> wheelSize = const Value.absent(),
          double? odometerKm,
          bool? isActive,
          DateTime? updatedAt}) =>
      BikeRow(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        brand: brand.present ? brand.value : this.brand,
        model: model.present ? model.value : this.model,
        year: year.present ? year.value : this.year,
        wheelSize: wheelSize.present ? wheelSize.value : this.wheelSize,
        odometerKm: odometerKm ?? this.odometerKm,
        isActive: isActive ?? this.isActive,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BikeRow copyWithCompanion(BikesCompanion data) {
    return BikeRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      brand: data.brand.present ? data.brand.value : this.brand,
      model: data.model.present ? data.model.value : this.model,
      year: data.year.present ? data.year.value : this.year,
      wheelSize: data.wheelSize.present ? data.wheelSize.value : this.wheelSize,
      odometerKm:
          data.odometerKm.present ? data.odometerKm.value : this.odometerKm,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BikeRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('year: $year, ')
          ..write('wheelSize: $wheelSize, ')
          ..write('odometerKm: $odometerKm, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, category, brand, model, year,
      wheelSize, odometerKm, isActive, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BikeRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.brand == this.brand &&
          other.model == this.model &&
          other.year == this.year &&
          other.wheelSize == this.wheelSize &&
          other.odometerKm == this.odometerKm &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt);
}

class BikesCompanion extends UpdateCompanion<BikeRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> category;
  final Value<String?> brand;
  final Value<String?> model;
  final Value<int?> year;
  final Value<String?> wheelSize;
  final Value<double> odometerKm;
  final Value<bool> isActive;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BikesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.brand = const Value.absent(),
    this.model = const Value.absent(),
    this.year = const Value.absent(),
    this.wheelSize = const Value.absent(),
    this.odometerKm = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BikesCompanion.insert({
    required String id,
    required String name,
    required String category,
    this.brand = const Value.absent(),
    this.model = const Value.absent(),
    this.year = const Value.absent(),
    this.wheelSize = const Value.absent(),
    this.odometerKm = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        category = Value(category),
        updatedAt = Value(updatedAt);
  static Insertable<BikeRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? brand,
    Expression<String>? model,
    Expression<int>? year,
    Expression<String>? wheelSize,
    Expression<double>? odometerKm,
    Expression<bool>? isActive,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      if (year != null) 'year': year,
      if (wheelSize != null) 'wheel_size': wheelSize,
      if (odometerKm != null) 'odometer_km': odometerKm,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BikesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? category,
      Value<String?>? brand,
      Value<String?>? model,
      Value<int?>? year,
      Value<String?>? wheelSize,
      Value<double>? odometerKm,
      Value<bool>? isActive,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return BikesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      wheelSize: wheelSize ?? this.wheelSize,
      odometerKm: odometerKm ?? this.odometerKm,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (wheelSize.present) {
      map['wheel_size'] = Variable<String>(wheelSize.value);
    }
    if (odometerKm.present) {
      map['odometer_km'] = Variable<double>(odometerKm.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BikesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('year: $year, ')
          ..write('wheelSize: $wheelSize, ')
          ..write('odometerKm: $odometerKm, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ComponentsTable extends Components
    with TableInfo<$ComponentsTable, Component> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ComponentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bikeIdMeta = const VerificationMeta('bikeId');
  @override
  late final GeneratedColumn<String> bikeId = GeneratedColumn<String>(
      'bike_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
      'slot', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _manufacturerMeta =
      const VerificationMeta('manufacturer');
  @override
  late final GeneratedColumn<String> manufacturer = GeneratedColumn<String>(
      'manufacturer', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _catalogModelIdMeta =
      const VerificationMeta('catalogModelId');
  @override
  late final GeneratedColumn<String> catalogModelId = GeneratedColumn<String>(
      'catalog_model_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _installedAtMeta =
      const VerificationMeta('installedAt');
  @override
  late final GeneratedColumn<DateTime> installedAt = GeneratedColumn<DateTime>(
      'installed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _removedAtMeta =
      const VerificationMeta('removedAt');
  @override
  late final GeneratedColumn<DateTime> removedAt = GeneratedColumn<DateTime>(
      'removed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _odometerKmMeta =
      const VerificationMeta('odometerKm');
  @override
  late final GeneratedColumn<double> odometerKm = GeneratedColumn<double>(
      'odometer_km', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _attributesJsonMeta =
      const VerificationMeta('attributesJson');
  @override
  late final GeneratedColumn<String> attributesJson = GeneratedColumn<String>(
      'attributes_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        bikeId,
        slot,
        manufacturer,
        model,
        catalogModelId,
        installedAt,
        removedAt,
        odometerKm,
        attributesJson,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'components';
  @override
  VerificationContext validateIntegrity(Insertable<Component> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bike_id')) {
      context.handle(_bikeIdMeta,
          bikeId.isAcceptableOrUnknown(data['bike_id']!, _bikeIdMeta));
    } else if (isInserting) {
      context.missing(_bikeIdMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
          _slotMeta, slot.isAcceptableOrUnknown(data['slot']!, _slotMeta));
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('manufacturer')) {
      context.handle(
          _manufacturerMeta,
          manufacturer.isAcceptableOrUnknown(
              data['manufacturer']!, _manufacturerMeta));
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    }
    if (data.containsKey('catalog_model_id')) {
      context.handle(
          _catalogModelIdMeta,
          catalogModelId.isAcceptableOrUnknown(
              data['catalog_model_id']!, _catalogModelIdMeta));
    }
    if (data.containsKey('installed_at')) {
      context.handle(
          _installedAtMeta,
          installedAt.isAcceptableOrUnknown(
              data['installed_at']!, _installedAtMeta));
    }
    if (data.containsKey('removed_at')) {
      context.handle(_removedAtMeta,
          removedAt.isAcceptableOrUnknown(data['removed_at']!, _removedAtMeta));
    }
    if (data.containsKey('odometer_km')) {
      context.handle(
          _odometerKmMeta,
          odometerKm.isAcceptableOrUnknown(
              data['odometer_km']!, _odometerKmMeta));
    }
    if (data.containsKey('attributes_json')) {
      context.handle(
          _attributesJsonMeta,
          attributesJson.isAcceptableOrUnknown(
              data['attributes_json']!, _attributesJsonMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Component map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Component(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      bikeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bike_id'])!,
      slot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slot'])!,
      manufacturer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}manufacturer']),
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model']),
      catalogModelId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}catalog_model_id']),
      installedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}installed_at']),
      removedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}removed_at']),
      odometerKm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}odometer_km'])!,
      attributesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}attributes_json'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ComponentsTable createAlias(String alias) {
    return $ComponentsTable(attachedDatabase, alias);
  }
}

class Component extends DataClass implements Insertable<Component> {
  final String id;
  final String bikeId;
  final String slot;
  final String? manufacturer;
  final String? model;
  final String? catalogModelId;
  final DateTime? installedAt;
  final DateTime? removedAt;
  final double odometerKm;
  final String attributesJson;
  final DateTime updatedAt;
  const Component(
      {required this.id,
      required this.bikeId,
      required this.slot,
      this.manufacturer,
      this.model,
      this.catalogModelId,
      this.installedAt,
      this.removedAt,
      required this.odometerKm,
      required this.attributesJson,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bike_id'] = Variable<String>(bikeId);
    map['slot'] = Variable<String>(slot);
    if (!nullToAbsent || manufacturer != null) {
      map['manufacturer'] = Variable<String>(manufacturer);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || catalogModelId != null) {
      map['catalog_model_id'] = Variable<String>(catalogModelId);
    }
    if (!nullToAbsent || installedAt != null) {
      map['installed_at'] = Variable<DateTime>(installedAt);
    }
    if (!nullToAbsent || removedAt != null) {
      map['removed_at'] = Variable<DateTime>(removedAt);
    }
    map['odometer_km'] = Variable<double>(odometerKm);
    map['attributes_json'] = Variable<String>(attributesJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ComponentsCompanion toCompanion(bool nullToAbsent) {
    return ComponentsCompanion(
      id: Value(id),
      bikeId: Value(bikeId),
      slot: Value(slot),
      manufacturer: manufacturer == null && nullToAbsent
          ? const Value.absent()
          : Value(manufacturer),
      model:
          model == null && nullToAbsent ? const Value.absent() : Value(model),
      catalogModelId: catalogModelId == null && nullToAbsent
          ? const Value.absent()
          : Value(catalogModelId),
      installedAt: installedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(installedAt),
      removedAt: removedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(removedAt),
      odometerKm: Value(odometerKm),
      attributesJson: Value(attributesJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory Component.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Component(
      id: serializer.fromJson<String>(json['id']),
      bikeId: serializer.fromJson<String>(json['bikeId']),
      slot: serializer.fromJson<String>(json['slot']),
      manufacturer: serializer.fromJson<String?>(json['manufacturer']),
      model: serializer.fromJson<String?>(json['model']),
      catalogModelId: serializer.fromJson<String?>(json['catalogModelId']),
      installedAt: serializer.fromJson<DateTime?>(json['installedAt']),
      removedAt: serializer.fromJson<DateTime?>(json['removedAt']),
      odometerKm: serializer.fromJson<double>(json['odometerKm']),
      attributesJson: serializer.fromJson<String>(json['attributesJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bikeId': serializer.toJson<String>(bikeId),
      'slot': serializer.toJson<String>(slot),
      'manufacturer': serializer.toJson<String?>(manufacturer),
      'model': serializer.toJson<String?>(model),
      'catalogModelId': serializer.toJson<String?>(catalogModelId),
      'installedAt': serializer.toJson<DateTime?>(installedAt),
      'removedAt': serializer.toJson<DateTime?>(removedAt),
      'odometerKm': serializer.toJson<double>(odometerKm),
      'attributesJson': serializer.toJson<String>(attributesJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Component copyWith(
          {String? id,
          String? bikeId,
          String? slot,
          Value<String?> manufacturer = const Value.absent(),
          Value<String?> model = const Value.absent(),
          Value<String?> catalogModelId = const Value.absent(),
          Value<DateTime?> installedAt = const Value.absent(),
          Value<DateTime?> removedAt = const Value.absent(),
          double? odometerKm,
          String? attributesJson,
          DateTime? updatedAt}) =>
      Component(
        id: id ?? this.id,
        bikeId: bikeId ?? this.bikeId,
        slot: slot ?? this.slot,
        manufacturer:
            manufacturer.present ? manufacturer.value : this.manufacturer,
        model: model.present ? model.value : this.model,
        catalogModelId:
            catalogModelId.present ? catalogModelId.value : this.catalogModelId,
        installedAt: installedAt.present ? installedAt.value : this.installedAt,
        removedAt: removedAt.present ? removedAt.value : this.removedAt,
        odometerKm: odometerKm ?? this.odometerKm,
        attributesJson: attributesJson ?? this.attributesJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Component copyWithCompanion(ComponentsCompanion data) {
    return Component(
      id: data.id.present ? data.id.value : this.id,
      bikeId: data.bikeId.present ? data.bikeId.value : this.bikeId,
      slot: data.slot.present ? data.slot.value : this.slot,
      manufacturer: data.manufacturer.present
          ? data.manufacturer.value
          : this.manufacturer,
      model: data.model.present ? data.model.value : this.model,
      catalogModelId: data.catalogModelId.present
          ? data.catalogModelId.value
          : this.catalogModelId,
      installedAt:
          data.installedAt.present ? data.installedAt.value : this.installedAt,
      removedAt: data.removedAt.present ? data.removedAt.value : this.removedAt,
      odometerKm:
          data.odometerKm.present ? data.odometerKm.value : this.odometerKm,
      attributesJson: data.attributesJson.present
          ? data.attributesJson.value
          : this.attributesJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Component(')
          ..write('id: $id, ')
          ..write('bikeId: $bikeId, ')
          ..write('slot: $slot, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('model: $model, ')
          ..write('catalogModelId: $catalogModelId, ')
          ..write('installedAt: $installedAt, ')
          ..write('removedAt: $removedAt, ')
          ..write('odometerKm: $odometerKm, ')
          ..write('attributesJson: $attributesJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      bikeId,
      slot,
      manufacturer,
      model,
      catalogModelId,
      installedAt,
      removedAt,
      odometerKm,
      attributesJson,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Component &&
          other.id == this.id &&
          other.bikeId == this.bikeId &&
          other.slot == this.slot &&
          other.manufacturer == this.manufacturer &&
          other.model == this.model &&
          other.catalogModelId == this.catalogModelId &&
          other.installedAt == this.installedAt &&
          other.removedAt == this.removedAt &&
          other.odometerKm == this.odometerKm &&
          other.attributesJson == this.attributesJson &&
          other.updatedAt == this.updatedAt);
}

class ComponentsCompanion extends UpdateCompanion<Component> {
  final Value<String> id;
  final Value<String> bikeId;
  final Value<String> slot;
  final Value<String?> manufacturer;
  final Value<String?> model;
  final Value<String?> catalogModelId;
  final Value<DateTime?> installedAt;
  final Value<DateTime?> removedAt;
  final Value<double> odometerKm;
  final Value<String> attributesJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ComponentsCompanion({
    this.id = const Value.absent(),
    this.bikeId = const Value.absent(),
    this.slot = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.model = const Value.absent(),
    this.catalogModelId = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.removedAt = const Value.absent(),
    this.odometerKm = const Value.absent(),
    this.attributesJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ComponentsCompanion.insert({
    required String id,
    required String bikeId,
    required String slot,
    this.manufacturer = const Value.absent(),
    this.model = const Value.absent(),
    this.catalogModelId = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.removedAt = const Value.absent(),
    this.odometerKm = const Value.absent(),
    this.attributesJson = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        bikeId = Value(bikeId),
        slot = Value(slot),
        updatedAt = Value(updatedAt);
  static Insertable<Component> custom({
    Expression<String>? id,
    Expression<String>? bikeId,
    Expression<String>? slot,
    Expression<String>? manufacturer,
    Expression<String>? model,
    Expression<String>? catalogModelId,
    Expression<DateTime>? installedAt,
    Expression<DateTime>? removedAt,
    Expression<double>? odometerKm,
    Expression<String>? attributesJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bikeId != null) 'bike_id': bikeId,
      if (slot != null) 'slot': slot,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (model != null) 'model': model,
      if (catalogModelId != null) 'catalog_model_id': catalogModelId,
      if (installedAt != null) 'installed_at': installedAt,
      if (removedAt != null) 'removed_at': removedAt,
      if (odometerKm != null) 'odometer_km': odometerKm,
      if (attributesJson != null) 'attributes_json': attributesJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ComponentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? bikeId,
      Value<String>? slot,
      Value<String?>? manufacturer,
      Value<String?>? model,
      Value<String?>? catalogModelId,
      Value<DateTime?>? installedAt,
      Value<DateTime?>? removedAt,
      Value<double>? odometerKm,
      Value<String>? attributesJson,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ComponentsCompanion(
      id: id ?? this.id,
      bikeId: bikeId ?? this.bikeId,
      slot: slot ?? this.slot,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      catalogModelId: catalogModelId ?? this.catalogModelId,
      installedAt: installedAt ?? this.installedAt,
      removedAt: removedAt ?? this.removedAt,
      odometerKm: odometerKm ?? this.odometerKm,
      attributesJson: attributesJson ?? this.attributesJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bikeId.present) {
      map['bike_id'] = Variable<String>(bikeId.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (manufacturer.present) {
      map['manufacturer'] = Variable<String>(manufacturer.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (catalogModelId.present) {
      map['catalog_model_id'] = Variable<String>(catalogModelId.value);
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<DateTime>(installedAt.value);
    }
    if (removedAt.present) {
      map['removed_at'] = Variable<DateTime>(removedAt.value);
    }
    if (odometerKm.present) {
      map['odometer_km'] = Variable<double>(odometerKm.value);
    }
    if (attributesJson.present) {
      map['attributes_json'] = Variable<String>(attributesJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ComponentsCompanion(')
          ..write('id: $id, ')
          ..write('bikeId: $bikeId, ')
          ..write('slot: $slot, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('model: $model, ')
          ..write('catalogModelId: $catalogModelId, ')
          ..write('installedAt: $installedAt, ')
          ..write('removedAt: $removedAt, ')
          ..write('odometerKm: $odometerKm, ')
          ..write('attributesJson: $attributesJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SetupsTable extends Setups with TableInfo<$SetupsTable, Setup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bikeIdMeta = const VerificationMeta('bikeId');
  @override
  late final GeneratedColumn<String> bikeId = GeneratedColumn<String>(
      'bike_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valuesJsonMeta =
      const VerificationMeta('valuesJson');
  @override
  late final GeneratedColumn<String> valuesJson = GeneratedColumn<String>(
      'values_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _immutableMeta =
      const VerificationMeta('immutable');
  @override
  late final GeneratedColumn<bool> immutable = GeneratedColumn<bool>(
      'immutable', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("immutable" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, bikeId, label, valuesJson, createdAt, immutable];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setups';
  @override
  VerificationContext validateIntegrity(Insertable<Setup> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bike_id')) {
      context.handle(_bikeIdMeta,
          bikeId.isAcceptableOrUnknown(data['bike_id']!, _bikeIdMeta));
    } else if (isInserting) {
      context.missing(_bikeIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('values_json')) {
      context.handle(
          _valuesJsonMeta,
          valuesJson.isAcceptableOrUnknown(
              data['values_json']!, _valuesJsonMeta));
    } else if (isInserting) {
      context.missing(_valuesJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('immutable')) {
      context.handle(_immutableMeta,
          immutable.isAcceptableOrUnknown(data['immutable']!, _immutableMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setup(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      bikeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bike_id'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      valuesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}values_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      immutable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}immutable'])!,
    );
  }

  @override
  $SetupsTable createAlias(String alias) {
    return $SetupsTable(attachedDatabase, alias);
  }
}

class Setup extends DataClass implements Insertable<Setup> {
  final String id;
  final String bikeId;
  final String label;
  final String valuesJson;
  final DateTime createdAt;
  final bool immutable;
  const Setup(
      {required this.id,
      required this.bikeId,
      required this.label,
      required this.valuesJson,
      required this.createdAt,
      required this.immutable});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bike_id'] = Variable<String>(bikeId);
    map['label'] = Variable<String>(label);
    map['values_json'] = Variable<String>(valuesJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['immutable'] = Variable<bool>(immutable);
    return map;
  }

  SetupsCompanion toCompanion(bool nullToAbsent) {
    return SetupsCompanion(
      id: Value(id),
      bikeId: Value(bikeId),
      label: Value(label),
      valuesJson: Value(valuesJson),
      createdAt: Value(createdAt),
      immutable: Value(immutable),
    );
  }

  factory Setup.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setup(
      id: serializer.fromJson<String>(json['id']),
      bikeId: serializer.fromJson<String>(json['bikeId']),
      label: serializer.fromJson<String>(json['label']),
      valuesJson: serializer.fromJson<String>(json['valuesJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      immutable: serializer.fromJson<bool>(json['immutable']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bikeId': serializer.toJson<String>(bikeId),
      'label': serializer.toJson<String>(label),
      'valuesJson': serializer.toJson<String>(valuesJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'immutable': serializer.toJson<bool>(immutable),
    };
  }

  Setup copyWith(
          {String? id,
          String? bikeId,
          String? label,
          String? valuesJson,
          DateTime? createdAt,
          bool? immutable}) =>
      Setup(
        id: id ?? this.id,
        bikeId: bikeId ?? this.bikeId,
        label: label ?? this.label,
        valuesJson: valuesJson ?? this.valuesJson,
        createdAt: createdAt ?? this.createdAt,
        immutable: immutable ?? this.immutable,
      );
  Setup copyWithCompanion(SetupsCompanion data) {
    return Setup(
      id: data.id.present ? data.id.value : this.id,
      bikeId: data.bikeId.present ? data.bikeId.value : this.bikeId,
      label: data.label.present ? data.label.value : this.label,
      valuesJson:
          data.valuesJson.present ? data.valuesJson.value : this.valuesJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      immutable: data.immutable.present ? data.immutable.value : this.immutable,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setup(')
          ..write('id: $id, ')
          ..write('bikeId: $bikeId, ')
          ..write('label: $label, ')
          ..write('valuesJson: $valuesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('immutable: $immutable')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, bikeId, label, valuesJson, createdAt, immutable);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setup &&
          other.id == this.id &&
          other.bikeId == this.bikeId &&
          other.label == this.label &&
          other.valuesJson == this.valuesJson &&
          other.createdAt == this.createdAt &&
          other.immutable == this.immutable);
}

class SetupsCompanion extends UpdateCompanion<Setup> {
  final Value<String> id;
  final Value<String> bikeId;
  final Value<String> label;
  final Value<String> valuesJson;
  final Value<DateTime> createdAt;
  final Value<bool> immutable;
  final Value<int> rowid;
  const SetupsCompanion({
    this.id = const Value.absent(),
    this.bikeId = const Value.absent(),
    this.label = const Value.absent(),
    this.valuesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.immutable = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetupsCompanion.insert({
    required String id,
    required String bikeId,
    required String label,
    required String valuesJson,
    required DateTime createdAt,
    this.immutable = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        bikeId = Value(bikeId),
        label = Value(label),
        valuesJson = Value(valuesJson),
        createdAt = Value(createdAt);
  static Insertable<Setup> custom({
    Expression<String>? id,
    Expression<String>? bikeId,
    Expression<String>? label,
    Expression<String>? valuesJson,
    Expression<DateTime>? createdAt,
    Expression<bool>? immutable,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bikeId != null) 'bike_id': bikeId,
      if (label != null) 'label': label,
      if (valuesJson != null) 'values_json': valuesJson,
      if (createdAt != null) 'created_at': createdAt,
      if (immutable != null) 'immutable': immutable,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetupsCompanion copyWith(
      {Value<String>? id,
      Value<String>? bikeId,
      Value<String>? label,
      Value<String>? valuesJson,
      Value<DateTime>? createdAt,
      Value<bool>? immutable,
      Value<int>? rowid}) {
    return SetupsCompanion(
      id: id ?? this.id,
      bikeId: bikeId ?? this.bikeId,
      label: label ?? this.label,
      valuesJson: valuesJson ?? this.valuesJson,
      createdAt: createdAt ?? this.createdAt,
      immutable: immutable ?? this.immutable,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bikeId.present) {
      map['bike_id'] = Variable<String>(bikeId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (valuesJson.present) {
      map['values_json'] = Variable<String>(valuesJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (immutable.present) {
      map['immutable'] = Variable<bool>(immutable.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetupsCompanion(')
          ..write('id: $id, ')
          ..write('bikeId: $bikeId, ')
          ..write('label: $label, ')
          ..write('valuesJson: $valuesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('immutable: $immutable, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RidesTable extends Rides with TableInfo<$RidesTable, Ride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RidesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bikeIdMeta = const VerificationMeta('bikeId');
  @override
  late final GeneratedColumn<String> bikeId = GeneratedColumn<String>(
      'bike_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endedAtMeta =
      const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
      'ended_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _distanceKmMeta =
      const VerificationMeta('distanceKm');
  @override
  late final GeneratedColumn<double> distanceKm = GeneratedColumn<double>(
      'distance_km', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _movingTimeSecMeta =
      const VerificationMeta('movingTimeSec');
  @override
  late final GeneratedColumn<int> movingTimeSec = GeneratedColumn<int>(
      'moving_time_sec', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _summaryJsonMeta =
      const VerificationMeta('summaryJson');
  @override
  late final GeneratedColumn<String> summaryJson = GeneratedColumn<String>(
      'summary_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, bikeId, startedAt, endedAt, distanceKm, movingTimeSec, summaryJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rides';
  @override
  VerificationContext validateIntegrity(Insertable<Ride> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bike_id')) {
      context.handle(_bikeIdMeta,
          bikeId.isAcceptableOrUnknown(data['bike_id']!, _bikeIdMeta));
    } else if (isInserting) {
      context.missing(_bikeIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta,
          endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    }
    if (data.containsKey('distance_km')) {
      context.handle(
          _distanceKmMeta,
          distanceKm.isAcceptableOrUnknown(
              data['distance_km']!, _distanceKmMeta));
    }
    if (data.containsKey('moving_time_sec')) {
      context.handle(
          _movingTimeSecMeta,
          movingTimeSec.isAcceptableOrUnknown(
              data['moving_time_sec']!, _movingTimeSecMeta));
    }
    if (data.containsKey('summary_json')) {
      context.handle(
          _summaryJsonMeta,
          summaryJson.isAcceptableOrUnknown(
              data['summary_json']!, _summaryJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ride(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      bikeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bike_id'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ended_at']),
      distanceKm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}distance_km'])!,
      movingTimeSec: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}moving_time_sec'])!,
      summaryJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary_json'])!,
    );
  }

  @override
  $RidesTable createAlias(String alias) {
    return $RidesTable(attachedDatabase, alias);
  }
}

class Ride extends DataClass implements Insertable<Ride> {
  final String id;
  final String bikeId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double distanceKm;
  final int movingTimeSec;
  final String summaryJson;
  const Ride(
      {required this.id,
      required this.bikeId,
      required this.startedAt,
      this.endedAt,
      required this.distanceKm,
      required this.movingTimeSec,
      required this.summaryJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bike_id'] = Variable<String>(bikeId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['distance_km'] = Variable<double>(distanceKm);
    map['moving_time_sec'] = Variable<int>(movingTimeSec);
    map['summary_json'] = Variable<String>(summaryJson);
    return map;
  }

  RidesCompanion toCompanion(bool nullToAbsent) {
    return RidesCompanion(
      id: Value(id),
      bikeId: Value(bikeId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      distanceKm: Value(distanceKm),
      movingTimeSec: Value(movingTimeSec),
      summaryJson: Value(summaryJson),
    );
  }

  factory Ride.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ride(
      id: serializer.fromJson<String>(json['id']),
      bikeId: serializer.fromJson<String>(json['bikeId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      distanceKm: serializer.fromJson<double>(json['distanceKm']),
      movingTimeSec: serializer.fromJson<int>(json['movingTimeSec']),
      summaryJson: serializer.fromJson<String>(json['summaryJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bikeId': serializer.toJson<String>(bikeId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'distanceKm': serializer.toJson<double>(distanceKm),
      'movingTimeSec': serializer.toJson<int>(movingTimeSec),
      'summaryJson': serializer.toJson<String>(summaryJson),
    };
  }

  Ride copyWith(
          {String? id,
          String? bikeId,
          DateTime? startedAt,
          Value<DateTime?> endedAt = const Value.absent(),
          double? distanceKm,
          int? movingTimeSec,
          String? summaryJson}) =>
      Ride(
        id: id ?? this.id,
        bikeId: bikeId ?? this.bikeId,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt.present ? endedAt.value : this.endedAt,
        distanceKm: distanceKm ?? this.distanceKm,
        movingTimeSec: movingTimeSec ?? this.movingTimeSec,
        summaryJson: summaryJson ?? this.summaryJson,
      );
  Ride copyWithCompanion(RidesCompanion data) {
    return Ride(
      id: data.id.present ? data.id.value : this.id,
      bikeId: data.bikeId.present ? data.bikeId.value : this.bikeId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      distanceKm:
          data.distanceKm.present ? data.distanceKm.value : this.distanceKm,
      movingTimeSec: data.movingTimeSec.present
          ? data.movingTimeSec.value
          : this.movingTimeSec,
      summaryJson:
          data.summaryJson.present ? data.summaryJson.value : this.summaryJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ride(')
          ..write('id: $id, ')
          ..write('bikeId: $bikeId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('movingTimeSec: $movingTimeSec, ')
          ..write('summaryJson: $summaryJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, bikeId, startedAt, endedAt, distanceKm, movingTimeSec, summaryJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ride &&
          other.id == this.id &&
          other.bikeId == this.bikeId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.distanceKm == this.distanceKm &&
          other.movingTimeSec == this.movingTimeSec &&
          other.summaryJson == this.summaryJson);
}

class RidesCompanion extends UpdateCompanion<Ride> {
  final Value<String> id;
  final Value<String> bikeId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<double> distanceKm;
  final Value<int> movingTimeSec;
  final Value<String> summaryJson;
  final Value<int> rowid;
  const RidesCompanion({
    this.id = const Value.absent(),
    this.bikeId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.movingTimeSec = const Value.absent(),
    this.summaryJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RidesCompanion.insert({
    required String id,
    required String bikeId,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.movingTimeSec = const Value.absent(),
    this.summaryJson = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        bikeId = Value(bikeId),
        startedAt = Value(startedAt);
  static Insertable<Ride> custom({
    Expression<String>? id,
    Expression<String>? bikeId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<double>? distanceKm,
    Expression<int>? movingTimeSec,
    Expression<String>? summaryJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bikeId != null) 'bike_id': bikeId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (movingTimeSec != null) 'moving_time_sec': movingTimeSec,
      if (summaryJson != null) 'summary_json': summaryJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RidesCompanion copyWith(
      {Value<String>? id,
      Value<String>? bikeId,
      Value<DateTime>? startedAt,
      Value<DateTime?>? endedAt,
      Value<double>? distanceKm,
      Value<int>? movingTimeSec,
      Value<String>? summaryJson,
      Value<int>? rowid}) {
    return RidesCompanion(
      id: id ?? this.id,
      bikeId: bikeId ?? this.bikeId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      distanceKm: distanceKm ?? this.distanceKm,
      movingTimeSec: movingTimeSec ?? this.movingTimeSec,
      summaryJson: summaryJson ?? this.summaryJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bikeId.present) {
      map['bike_id'] = Variable<String>(bikeId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (distanceKm.present) {
      map['distance_km'] = Variable<double>(distanceKm.value);
    }
    if (movingTimeSec.present) {
      map['moving_time_sec'] = Variable<int>(movingTimeSec.value);
    }
    if (summaryJson.present) {
      map['summary_json'] = Variable<String>(summaryJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RidesCompanion(')
          ..write('id: $id, ')
          ..write('bikeId: $bikeId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('movingTimeSec: $movingTimeSec, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RideChunksMetaTable extends RideChunksMeta
    with TableInfo<$RideChunksMetaTable, RideChunksMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RideChunksMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rideIdMeta = const VerificationMeta('rideId');
  @override
  late final GeneratedColumn<String> rideId = GeneratedColumn<String>(
      'ride_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
      'seq', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _windowStartMeta =
      const VerificationMeta('windowStart');
  @override
  late final GeneratedColumn<DateTime> windowStart = GeneratedColumn<DateTime>(
      'window_start', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _windowEndMeta =
      const VerificationMeta('windowEnd');
  @override
  late final GeneratedColumn<DateTime> windowEnd = GeneratedColumn<DateTime>(
      'window_end', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, rideId, seq, windowStart, windowEnd, localPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ride_chunks_meta';
  @override
  VerificationContext validateIntegrity(Insertable<RideChunksMetaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ride_id')) {
      context.handle(_rideIdMeta,
          rideId.isAcceptableOrUnknown(data['ride_id']!, _rideIdMeta));
    } else if (isInserting) {
      context.missing(_rideIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
          _seqMeta, seq.isAcceptableOrUnknown(data['seq']!, _seqMeta));
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('window_start')) {
      context.handle(
          _windowStartMeta,
          windowStart.isAcceptableOrUnknown(
              data['window_start']!, _windowStartMeta));
    } else if (isInserting) {
      context.missing(_windowStartMeta);
    }
    if (data.containsKey('window_end')) {
      context.handle(_windowEndMeta,
          windowEnd.isAcceptableOrUnknown(data['window_end']!, _windowEndMeta));
    } else if (isInserting) {
      context.missing(_windowEndMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RideChunksMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RideChunksMetaData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      rideId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ride_id'])!,
      seq: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}seq'])!,
      windowStart: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}window_start'])!,
      windowEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}window_end'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
    );
  }

  @override
  $RideChunksMetaTable createAlias(String alias) {
    return $RideChunksMetaTable(attachedDatabase, alias);
  }
}

class RideChunksMetaData extends DataClass
    implements Insertable<RideChunksMetaData> {
  final String id;
  final String rideId;
  final int seq;
  final DateTime windowStart;
  final DateTime windowEnd;
  final String? localPath;
  const RideChunksMetaData(
      {required this.id,
      required this.rideId,
      required this.seq,
      required this.windowStart,
      required this.windowEnd,
      this.localPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['ride_id'] = Variable<String>(rideId);
    map['seq'] = Variable<int>(seq);
    map['window_start'] = Variable<DateTime>(windowStart);
    map['window_end'] = Variable<DateTime>(windowEnd);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    return map;
  }

  RideChunksMetaCompanion toCompanion(bool nullToAbsent) {
    return RideChunksMetaCompanion(
      id: Value(id),
      rideId: Value(rideId),
      seq: Value(seq),
      windowStart: Value(windowStart),
      windowEnd: Value(windowEnd),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
    );
  }

  factory RideChunksMetaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RideChunksMetaData(
      id: serializer.fromJson<String>(json['id']),
      rideId: serializer.fromJson<String>(json['rideId']),
      seq: serializer.fromJson<int>(json['seq']),
      windowStart: serializer.fromJson<DateTime>(json['windowStart']),
      windowEnd: serializer.fromJson<DateTime>(json['windowEnd']),
      localPath: serializer.fromJson<String?>(json['localPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rideId': serializer.toJson<String>(rideId),
      'seq': serializer.toJson<int>(seq),
      'windowStart': serializer.toJson<DateTime>(windowStart),
      'windowEnd': serializer.toJson<DateTime>(windowEnd),
      'localPath': serializer.toJson<String?>(localPath),
    };
  }

  RideChunksMetaData copyWith(
          {String? id,
          String? rideId,
          int? seq,
          DateTime? windowStart,
          DateTime? windowEnd,
          Value<String?> localPath = const Value.absent()}) =>
      RideChunksMetaData(
        id: id ?? this.id,
        rideId: rideId ?? this.rideId,
        seq: seq ?? this.seq,
        windowStart: windowStart ?? this.windowStart,
        windowEnd: windowEnd ?? this.windowEnd,
        localPath: localPath.present ? localPath.value : this.localPath,
      );
  RideChunksMetaData copyWithCompanion(RideChunksMetaCompanion data) {
    return RideChunksMetaData(
      id: data.id.present ? data.id.value : this.id,
      rideId: data.rideId.present ? data.rideId.value : this.rideId,
      seq: data.seq.present ? data.seq.value : this.seq,
      windowStart:
          data.windowStart.present ? data.windowStart.value : this.windowStart,
      windowEnd: data.windowEnd.present ? data.windowEnd.value : this.windowEnd,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RideChunksMetaData(')
          ..write('id: $id, ')
          ..write('rideId: $rideId, ')
          ..write('seq: $seq, ')
          ..write('windowStart: $windowStart, ')
          ..write('windowEnd: $windowEnd, ')
          ..write('localPath: $localPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, rideId, seq, windowStart, windowEnd, localPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RideChunksMetaData &&
          other.id == this.id &&
          other.rideId == this.rideId &&
          other.seq == this.seq &&
          other.windowStart == this.windowStart &&
          other.windowEnd == this.windowEnd &&
          other.localPath == this.localPath);
}

class RideChunksMetaCompanion extends UpdateCompanion<RideChunksMetaData> {
  final Value<String> id;
  final Value<String> rideId;
  final Value<int> seq;
  final Value<DateTime> windowStart;
  final Value<DateTime> windowEnd;
  final Value<String?> localPath;
  final Value<int> rowid;
  const RideChunksMetaCompanion({
    this.id = const Value.absent(),
    this.rideId = const Value.absent(),
    this.seq = const Value.absent(),
    this.windowStart = const Value.absent(),
    this.windowEnd = const Value.absent(),
    this.localPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RideChunksMetaCompanion.insert({
    required String id,
    required String rideId,
    required int seq,
    required DateTime windowStart,
    required DateTime windowEnd,
    this.localPath = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        rideId = Value(rideId),
        seq = Value(seq),
        windowStart = Value(windowStart),
        windowEnd = Value(windowEnd);
  static Insertable<RideChunksMetaData> custom({
    Expression<String>? id,
    Expression<String>? rideId,
    Expression<int>? seq,
    Expression<DateTime>? windowStart,
    Expression<DateTime>? windowEnd,
    Expression<String>? localPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rideId != null) 'ride_id': rideId,
      if (seq != null) 'seq': seq,
      if (windowStart != null) 'window_start': windowStart,
      if (windowEnd != null) 'window_end': windowEnd,
      if (localPath != null) 'local_path': localPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RideChunksMetaCompanion copyWith(
      {Value<String>? id,
      Value<String>? rideId,
      Value<int>? seq,
      Value<DateTime>? windowStart,
      Value<DateTime>? windowEnd,
      Value<String?>? localPath,
      Value<int>? rowid}) {
    return RideChunksMetaCompanion(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      seq: seq ?? this.seq,
      windowStart: windowStart ?? this.windowStart,
      windowEnd: windowEnd ?? this.windowEnd,
      localPath: localPath ?? this.localPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rideId.present) {
      map['ride_id'] = Variable<String>(rideId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (windowStart.present) {
      map['window_start'] = Variable<DateTime>(windowStart.value);
    }
    if (windowEnd.present) {
      map['window_end'] = Variable<DateTime>(windowEnd.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RideChunksMetaCompanion(')
          ..write('id: $id, ')
          ..write('rideId: $rideId, ')
          ..write('seq: $seq, ')
          ..write('windowStart: $windowStart, ')
          ..write('windowEnd: $windowEnd, ')
          ..write('localPath: $localPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConsentsTable extends Consents with TableInfo<$ConsentsTable, Consent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConsentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _grantedMeta =
      const VerificationMeta('granted');
  @override
  late final GeneratedColumn<bool> granted = GeneratedColumn<bool>(
      'granted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("granted" IN (0, 1))'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, key, granted, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'consents';
  @override
  VerificationContext validateIntegrity(Insertable<Consent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('granted')) {
      context.handle(_grantedMeta,
          granted.isAcceptableOrUnknown(data['granted']!, _grantedMeta));
    } else if (isInserting) {
      context.missing(_grantedMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Consent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Consent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      granted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}granted'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ConsentsTable createAlias(String alias) {
    return $ConsentsTable(attachedDatabase, alias);
  }
}

class Consent extends DataClass implements Insertable<Consent> {
  final String id;
  final String key;
  final bool granted;
  final DateTime updatedAt;
  const Consent(
      {required this.id,
      required this.key,
      required this.granted,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['key'] = Variable<String>(key);
    map['granted'] = Variable<bool>(granted);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ConsentsCompanion toCompanion(bool nullToAbsent) {
    return ConsentsCompanion(
      id: Value(id),
      key: Value(key),
      granted: Value(granted),
      updatedAt: Value(updatedAt),
    );
  }

  factory Consent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Consent(
      id: serializer.fromJson<String>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      granted: serializer.fromJson<bool>(json['granted']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'key': serializer.toJson<String>(key),
      'granted': serializer.toJson<bool>(granted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Consent copyWith(
          {String? id, String? key, bool? granted, DateTime? updatedAt}) =>
      Consent(
        id: id ?? this.id,
        key: key ?? this.key,
        granted: granted ?? this.granted,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Consent copyWithCompanion(ConsentsCompanion data) {
    return Consent(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      granted: data.granted.present ? data.granted.value : this.granted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Consent(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('granted: $granted, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, granted, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Consent &&
          other.id == this.id &&
          other.key == this.key &&
          other.granted == this.granted &&
          other.updatedAt == this.updatedAt);
}

class ConsentsCompanion extends UpdateCompanion<Consent> {
  final Value<String> id;
  final Value<String> key;
  final Value<bool> granted;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ConsentsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.granted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConsentsCompanion.insert({
    required String id,
    required String key,
    required bool granted,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        key = Value(key),
        granted = Value(granted),
        updatedAt = Value(updatedAt);
  static Insertable<Consent> custom({
    Expression<String>? id,
    Expression<String>? key,
    Expression<bool>? granted,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (granted != null) 'granted': granted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConsentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? key,
      Value<bool>? granted,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ConsentsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      granted: granted ?? this.granted,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (granted.present) {
      map['granted'] = Variable<bool>(granted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConsentsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('granted: $granted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _remoteUpdatedAtMeta =
      const VerificationMeta('remoteUpdatedAt');
  @override
  late final GeneratedColumn<String> remoteUpdatedAt = GeneratedColumn<String>(
      'remote_updated_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _localUpdatedAtMeta =
      const VerificationMeta('localUpdatedAt');
  @override
  late final GeneratedColumn<String> localUpdatedAt = GeneratedColumn<String>(
      'local_updated_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastDirectionMeta =
      const VerificationMeta('lastDirection');
  @override
  late final GeneratedColumn<String> lastDirection = GeneratedColumn<String>(
      'last_direction', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _payloadVersionMeta =
      const VerificationMeta('payloadVersion');
  @override
  late final GeneratedColumn<int> payloadVersion = GeneratedColumn<int>(
      'payload_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns =>
      [id, remoteUpdatedAt, localUpdatedAt, lastDirection, payloadVersion];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(Insertable<SyncStateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_updated_at')) {
      context.handle(
          _remoteUpdatedAtMeta,
          remoteUpdatedAt.isAcceptableOrUnknown(
              data['remote_updated_at']!, _remoteUpdatedAtMeta));
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
          _localUpdatedAtMeta,
          localUpdatedAt.isAcceptableOrUnknown(
              data['local_updated_at']!, _localUpdatedAtMeta));
    }
    if (data.containsKey('last_direction')) {
      context.handle(
          _lastDirectionMeta,
          lastDirection.isAcceptableOrUnknown(
              data['last_direction']!, _lastDirectionMeta));
    }
    if (data.containsKey('payload_version')) {
      context.handle(
          _payloadVersionMeta,
          payloadVersion.isAcceptableOrUnknown(
              data['payload_version']!, _payloadVersionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      remoteUpdatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}remote_updated_at']),
      localUpdatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}local_updated_at']),
      lastDirection: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_direction']),
      payloadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}payload_version'])!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final int id;
  final String? remoteUpdatedAt;
  final String? localUpdatedAt;
  final String? lastDirection;
  final int payloadVersion;
  const SyncStateData(
      {required this.id,
      this.remoteUpdatedAt,
      this.localUpdatedAt,
      this.lastDirection,
      required this.payloadVersion});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || remoteUpdatedAt != null) {
      map['remote_updated_at'] = Variable<String>(remoteUpdatedAt);
    }
    if (!nullToAbsent || localUpdatedAt != null) {
      map['local_updated_at'] = Variable<String>(localUpdatedAt);
    }
    if (!nullToAbsent || lastDirection != null) {
      map['last_direction'] = Variable<String>(lastDirection);
    }
    map['payload_version'] = Variable<int>(payloadVersion);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      id: Value(id),
      remoteUpdatedAt: remoteUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUpdatedAt),
      localUpdatedAt: localUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(localUpdatedAt),
      lastDirection: lastDirection == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDirection),
      payloadVersion: Value(payloadVersion),
    );
  }

  factory SyncStateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      id: serializer.fromJson<int>(json['id']),
      remoteUpdatedAt: serializer.fromJson<String?>(json['remoteUpdatedAt']),
      localUpdatedAt: serializer.fromJson<String?>(json['localUpdatedAt']),
      lastDirection: serializer.fromJson<String?>(json['lastDirection']),
      payloadVersion: serializer.fromJson<int>(json['payloadVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteUpdatedAt': serializer.toJson<String?>(remoteUpdatedAt),
      'localUpdatedAt': serializer.toJson<String?>(localUpdatedAt),
      'lastDirection': serializer.toJson<String?>(lastDirection),
      'payloadVersion': serializer.toJson<int>(payloadVersion),
    };
  }

  SyncStateData copyWith(
          {int? id,
          Value<String?> remoteUpdatedAt = const Value.absent(),
          Value<String?> localUpdatedAt = const Value.absent(),
          Value<String?> lastDirection = const Value.absent(),
          int? payloadVersion}) =>
      SyncStateData(
        id: id ?? this.id,
        remoteUpdatedAt: remoteUpdatedAt.present
            ? remoteUpdatedAt.value
            : this.remoteUpdatedAt,
        localUpdatedAt:
            localUpdatedAt.present ? localUpdatedAt.value : this.localUpdatedAt,
        lastDirection:
            lastDirection.present ? lastDirection.value : this.lastDirection,
        payloadVersion: payloadVersion ?? this.payloadVersion,
      );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      id: data.id.present ? data.id.value : this.id,
      remoteUpdatedAt: data.remoteUpdatedAt.present
          ? data.remoteUpdatedAt.value
          : this.remoteUpdatedAt,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      lastDirection: data.lastDirection.present
          ? data.lastDirection.value
          : this.lastDirection,
      payloadVersion: data.payloadVersion.present
          ? data.payloadVersion.value
          : this.payloadVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('id: $id, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('lastDirection: $lastDirection, ')
          ..write('payloadVersion: $payloadVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, remoteUpdatedAt, localUpdatedAt, lastDirection, payloadVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.id == this.id &&
          other.remoteUpdatedAt == this.remoteUpdatedAt &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.lastDirection == this.lastDirection &&
          other.payloadVersion == this.payloadVersion);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<int> id;
  final Value<String?> remoteUpdatedAt;
  final Value<String?> localUpdatedAt;
  final Value<String?> lastDirection;
  final Value<int> payloadVersion;
  const SyncStateCompanion({
    this.id = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.lastDirection = const Value.absent(),
    this.payloadVersion = const Value.absent(),
  });
  SyncStateCompanion.insert({
    this.id = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.lastDirection = const Value.absent(),
    this.payloadVersion = const Value.absent(),
  });
  static Insertable<SyncStateData> custom({
    Expression<int>? id,
    Expression<String>? remoteUpdatedAt,
    Expression<String>? localUpdatedAt,
    Expression<String>? lastDirection,
    Expression<int>? payloadVersion,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteUpdatedAt != null) 'remote_updated_at': remoteUpdatedAt,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (lastDirection != null) 'last_direction': lastDirection,
      if (payloadVersion != null) 'payload_version': payloadVersion,
    });
  }

  SyncStateCompanion copyWith(
      {Value<int>? id,
      Value<String?>? remoteUpdatedAt,
      Value<String?>? localUpdatedAt,
      Value<String?>? lastDirection,
      Value<int>? payloadVersion}) {
    return SyncStateCompanion(
      id: id ?? this.id,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      lastDirection: lastDirection ?? this.lastDirection,
      payloadVersion: payloadVersion ?? this.payloadVersion,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteUpdatedAt.present) {
      map['remote_updated_at'] = Variable<String>(remoteUpdatedAt.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<String>(localUpdatedAt.value);
    }
    if (lastDirection.present) {
      map['last_direction'] = Variable<String>(lastDirection.value);
    }
    if (payloadVersion.present) {
      map['payload_version'] = Variable<int>(payloadVersion.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('id: $id, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('lastDirection: $lastDirection, ')
          ..write('payloadVersion: $payloadVersion')
          ..write(')'))
        .toString();
  }
}

class $CatalogCacheTable extends CatalogCache
    with TableInfo<$CatalogCacheTable, CatalogCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
      'slot', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _manufacturerMeta =
      const VerificationMeta('manufacturer');
  @override
  late final GeneratedColumn<String> manufacturer = GeneratedColumn<String>(
      'manufacturer', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fetchedAtMeta =
      const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
      'fetched_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, slot, manufacturer, model, payloadJson, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_cache';
  @override
  VerificationContext validateIntegrity(Insertable<CatalogCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
          _slotMeta, slot.isAcceptableOrUnknown(data['slot']!, _slotMeta));
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('manufacturer')) {
      context.handle(
          _manufacturerMeta,
          manufacturer.isAcceptableOrUnknown(
              data['manufacturer']!, _manufacturerMeta));
    } else if (isInserting) {
      context.missing(_manufacturerMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta,
          fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CatalogCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogCacheData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      slot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slot'])!,
      manufacturer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}manufacturer'])!,
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      fetchedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}fetched_at'])!,
    );
  }

  @override
  $CatalogCacheTable createAlias(String alias) {
    return $CatalogCacheTable(attachedDatabase, alias);
  }
}

class CatalogCacheData extends DataClass
    implements Insertable<CatalogCacheData> {
  final String id;
  final String slot;
  final String manufacturer;
  final String model;
  final String payloadJson;
  final DateTime fetchedAt;
  const CatalogCacheData(
      {required this.id,
      required this.slot,
      required this.manufacturer,
      required this.model,
      required this.payloadJson,
      required this.fetchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['slot'] = Variable<String>(slot);
    map['manufacturer'] = Variable<String>(manufacturer);
    map['model'] = Variable<String>(model);
    map['payload_json'] = Variable<String>(payloadJson);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  CatalogCacheCompanion toCompanion(bool nullToAbsent) {
    return CatalogCacheCompanion(
      id: Value(id),
      slot: Value(slot),
      manufacturer: Value(manufacturer),
      model: Value(model),
      payloadJson: Value(payloadJson),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CatalogCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogCacheData(
      id: serializer.fromJson<String>(json['id']),
      slot: serializer.fromJson<String>(json['slot']),
      manufacturer: serializer.fromJson<String>(json['manufacturer']),
      model: serializer.fromJson<String>(json['model']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'slot': serializer.toJson<String>(slot),
      'manufacturer': serializer.toJson<String>(manufacturer),
      'model': serializer.toJson<String>(model),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  CatalogCacheData copyWith(
          {String? id,
          String? slot,
          String? manufacturer,
          String? model,
          String? payloadJson,
          DateTime? fetchedAt}) =>
      CatalogCacheData(
        id: id ?? this.id,
        slot: slot ?? this.slot,
        manufacturer: manufacturer ?? this.manufacturer,
        model: model ?? this.model,
        payloadJson: payloadJson ?? this.payloadJson,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  CatalogCacheData copyWithCompanion(CatalogCacheCompanion data) {
    return CatalogCacheData(
      id: data.id.present ? data.id.value : this.id,
      slot: data.slot.present ? data.slot.value : this.slot,
      manufacturer: data.manufacturer.present
          ? data.manufacturer.value
          : this.manufacturer,
      model: data.model.present ? data.model.value : this.model,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogCacheData(')
          ..write('id: $id, ')
          ..write('slot: $slot, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('model: $model, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, slot, manufacturer, model, payloadJson, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogCacheData &&
          other.id == this.id &&
          other.slot == this.slot &&
          other.manufacturer == this.manufacturer &&
          other.model == this.model &&
          other.payloadJson == this.payloadJson &&
          other.fetchedAt == this.fetchedAt);
}

class CatalogCacheCompanion extends UpdateCompanion<CatalogCacheData> {
  final Value<String> id;
  final Value<String> slot;
  final Value<String> manufacturer;
  final Value<String> model;
  final Value<String> payloadJson;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const CatalogCacheCompanion({
    this.id = const Value.absent(),
    this.slot = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.model = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogCacheCompanion.insert({
    required String id,
    required String slot,
    required String manufacturer,
    required String model,
    required String payloadJson,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        slot = Value(slot),
        manufacturer = Value(manufacturer),
        model = Value(model),
        payloadJson = Value(payloadJson),
        fetchedAt = Value(fetchedAt);
  static Insertable<CatalogCacheData> custom({
    Expression<String>? id,
    Expression<String>? slot,
    Expression<String>? manufacturer,
    Expression<String>? model,
    Expression<String>? payloadJson,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slot != null) 'slot': slot,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (model != null) 'model': model,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogCacheCompanion copyWith(
      {Value<String>? id,
      Value<String>? slot,
      Value<String>? manufacturer,
      Value<String>? model,
      Value<String>? payloadJson,
      Value<DateTime>? fetchedAt,
      Value<int>? rowid}) {
    return CatalogCacheCompanion(
      id: id ?? this.id,
      slot: slot ?? this.slot,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      payloadJson: payloadJson ?? this.payloadJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (manufacturer.present) {
      map['manufacturer'] = Variable<String>(manufacturer.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogCacheCompanion(')
          ..write('id: $id, ')
          ..write('slot: $slot, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('model: $model, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BikesTable bikes = $BikesTable(this);
  late final $ComponentsTable components = $ComponentsTable(this);
  late final $SetupsTable setups = $SetupsTable(this);
  late final $RidesTable rides = $RidesTable(this);
  late final $RideChunksMetaTable rideChunksMeta = $RideChunksMetaTable(this);
  late final $ConsentsTable consents = $ConsentsTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $CatalogCacheTable catalogCache = $CatalogCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        bikes,
        components,
        setups,
        rides,
        rideChunksMeta,
        consents,
        syncState,
        catalogCache
      ];
}

typedef $$BikesTableCreateCompanionBuilder = BikesCompanion Function({
  required String id,
  required String name,
  required String category,
  Value<String?> brand,
  Value<String?> model,
  Value<int?> year,
  Value<String?> wheelSize,
  Value<double> odometerKm,
  Value<bool> isActive,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$BikesTableUpdateCompanionBuilder = BikesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> category,
  Value<String?> brand,
  Value<String?> model,
  Value<int?> year,
  Value<String?> wheelSize,
  Value<double> odometerKm,
  Value<bool> isActive,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$BikesTableFilterComposer extends Composer<_$AppDatabase, $BikesTable> {
  $$BikesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get brand => $composableBuilder(
      column: $table.brand, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get wheelSize => $composableBuilder(
      column: $table.wheelSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get odometerKm => $composableBuilder(
      column: $table.odometerKm, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$BikesTableOrderingComposer
    extends Composer<_$AppDatabase, $BikesTable> {
  $$BikesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get brand => $composableBuilder(
      column: $table.brand, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get wheelSize => $composableBuilder(
      column: $table.wheelSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get odometerKm => $composableBuilder(
      column: $table.odometerKm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$BikesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BikesTable> {
  $$BikesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get wheelSize =>
      $composableBuilder(column: $table.wheelSize, builder: (column) => column);

  GeneratedColumn<double> get odometerKm => $composableBuilder(
      column: $table.odometerKm, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BikesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BikesTable,
    BikeRow,
    $$BikesTableFilterComposer,
    $$BikesTableOrderingComposer,
    $$BikesTableAnnotationComposer,
    $$BikesTableCreateCompanionBuilder,
    $$BikesTableUpdateCompanionBuilder,
    (BikeRow, BaseReferences<_$AppDatabase, $BikesTable, BikeRow>),
    BikeRow,
    PrefetchHooks Function()> {
  $$BikesTableTableManager(_$AppDatabase db, $BikesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BikesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BikesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BikesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String?> brand = const Value.absent(),
            Value<String?> model = const Value.absent(),
            Value<int?> year = const Value.absent(),
            Value<String?> wheelSize = const Value.absent(),
            Value<double> odometerKm = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BikesCompanion(
            id: id,
            name: name,
            category: category,
            brand: brand,
            model: model,
            year: year,
            wheelSize: wheelSize,
            odometerKm: odometerKm,
            isActive: isActive,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String category,
            Value<String?> brand = const Value.absent(),
            Value<String?> model = const Value.absent(),
            Value<int?> year = const Value.absent(),
            Value<String?> wheelSize = const Value.absent(),
            Value<double> odometerKm = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BikesCompanion.insert(
            id: id,
            name: name,
            category: category,
            brand: brand,
            model: model,
            year: year,
            wheelSize: wheelSize,
            odometerKm: odometerKm,
            isActive: isActive,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BikesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BikesTable,
    BikeRow,
    $$BikesTableFilterComposer,
    $$BikesTableOrderingComposer,
    $$BikesTableAnnotationComposer,
    $$BikesTableCreateCompanionBuilder,
    $$BikesTableUpdateCompanionBuilder,
    (BikeRow, BaseReferences<_$AppDatabase, $BikesTable, BikeRow>),
    BikeRow,
    PrefetchHooks Function()>;
typedef $$ComponentsTableCreateCompanionBuilder = ComponentsCompanion Function({
  required String id,
  required String bikeId,
  required String slot,
  Value<String?> manufacturer,
  Value<String?> model,
  Value<String?> catalogModelId,
  Value<DateTime?> installedAt,
  Value<DateTime?> removedAt,
  Value<double> odometerKm,
  Value<String> attributesJson,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ComponentsTableUpdateCompanionBuilder = ComponentsCompanion Function({
  Value<String> id,
  Value<String> bikeId,
  Value<String> slot,
  Value<String?> manufacturer,
  Value<String?> model,
  Value<String?> catalogModelId,
  Value<DateTime?> installedAt,
  Value<DateTime?> removedAt,
  Value<double> odometerKm,
  Value<String> attributesJson,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ComponentsTableFilterComposer
    extends Composer<_$AppDatabase, $ComponentsTable> {
  $$ComponentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bikeId => $composableBuilder(
      column: $table.bikeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get manufacturer => $composableBuilder(
      column: $table.manufacturer, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get catalogModelId => $composableBuilder(
      column: $table.catalogModelId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get installedAt => $composableBuilder(
      column: $table.installedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get removedAt => $composableBuilder(
      column: $table.removedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get odometerKm => $composableBuilder(
      column: $table.odometerKm, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attributesJson => $composableBuilder(
      column: $table.attributesJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ComponentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ComponentsTable> {
  $$ComponentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bikeId => $composableBuilder(
      column: $table.bikeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get manufacturer => $composableBuilder(
      column: $table.manufacturer,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get catalogModelId => $composableBuilder(
      column: $table.catalogModelId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get installedAt => $composableBuilder(
      column: $table.installedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get removedAt => $composableBuilder(
      column: $table.removedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get odometerKm => $composableBuilder(
      column: $table.odometerKm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attributesJson => $composableBuilder(
      column: $table.attributesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ComponentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ComponentsTable> {
  $$ComponentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bikeId =>
      $composableBuilder(column: $table.bikeId, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get manufacturer => $composableBuilder(
      column: $table.manufacturer, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get catalogModelId => $composableBuilder(
      column: $table.catalogModelId, builder: (column) => column);

  GeneratedColumn<DateTime> get installedAt => $composableBuilder(
      column: $table.installedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get removedAt =>
      $composableBuilder(column: $table.removedAt, builder: (column) => column);

  GeneratedColumn<double> get odometerKm => $composableBuilder(
      column: $table.odometerKm, builder: (column) => column);

  GeneratedColumn<String> get attributesJson => $composableBuilder(
      column: $table.attributesJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ComponentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ComponentsTable,
    Component,
    $$ComponentsTableFilterComposer,
    $$ComponentsTableOrderingComposer,
    $$ComponentsTableAnnotationComposer,
    $$ComponentsTableCreateCompanionBuilder,
    $$ComponentsTableUpdateCompanionBuilder,
    (Component, BaseReferences<_$AppDatabase, $ComponentsTable, Component>),
    Component,
    PrefetchHooks Function()> {
  $$ComponentsTableTableManager(_$AppDatabase db, $ComponentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ComponentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ComponentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ComponentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> bikeId = const Value.absent(),
            Value<String> slot = const Value.absent(),
            Value<String?> manufacturer = const Value.absent(),
            Value<String?> model = const Value.absent(),
            Value<String?> catalogModelId = const Value.absent(),
            Value<DateTime?> installedAt = const Value.absent(),
            Value<DateTime?> removedAt = const Value.absent(),
            Value<double> odometerKm = const Value.absent(),
            Value<String> attributesJson = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ComponentsCompanion(
            id: id,
            bikeId: bikeId,
            slot: slot,
            manufacturer: manufacturer,
            model: model,
            catalogModelId: catalogModelId,
            installedAt: installedAt,
            removedAt: removedAt,
            odometerKm: odometerKm,
            attributesJson: attributesJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String bikeId,
            required String slot,
            Value<String?> manufacturer = const Value.absent(),
            Value<String?> model = const Value.absent(),
            Value<String?> catalogModelId = const Value.absent(),
            Value<DateTime?> installedAt = const Value.absent(),
            Value<DateTime?> removedAt = const Value.absent(),
            Value<double> odometerKm = const Value.absent(),
            Value<String> attributesJson = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ComponentsCompanion.insert(
            id: id,
            bikeId: bikeId,
            slot: slot,
            manufacturer: manufacturer,
            model: model,
            catalogModelId: catalogModelId,
            installedAt: installedAt,
            removedAt: removedAt,
            odometerKm: odometerKm,
            attributesJson: attributesJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ComponentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ComponentsTable,
    Component,
    $$ComponentsTableFilterComposer,
    $$ComponentsTableOrderingComposer,
    $$ComponentsTableAnnotationComposer,
    $$ComponentsTableCreateCompanionBuilder,
    $$ComponentsTableUpdateCompanionBuilder,
    (Component, BaseReferences<_$AppDatabase, $ComponentsTable, Component>),
    Component,
    PrefetchHooks Function()>;
typedef $$SetupsTableCreateCompanionBuilder = SetupsCompanion Function({
  required String id,
  required String bikeId,
  required String label,
  required String valuesJson,
  required DateTime createdAt,
  Value<bool> immutable,
  Value<int> rowid,
});
typedef $$SetupsTableUpdateCompanionBuilder = SetupsCompanion Function({
  Value<String> id,
  Value<String> bikeId,
  Value<String> label,
  Value<String> valuesJson,
  Value<DateTime> createdAt,
  Value<bool> immutable,
  Value<int> rowid,
});

class $$SetupsTableFilterComposer
    extends Composer<_$AppDatabase, $SetupsTable> {
  $$SetupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bikeId => $composableBuilder(
      column: $table.bikeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get valuesJson => $composableBuilder(
      column: $table.valuesJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get immutable => $composableBuilder(
      column: $table.immutable, builder: (column) => ColumnFilters(column));
}

class $$SetupsTableOrderingComposer
    extends Composer<_$AppDatabase, $SetupsTable> {
  $$SetupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bikeId => $composableBuilder(
      column: $table.bikeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get valuesJson => $composableBuilder(
      column: $table.valuesJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get immutable => $composableBuilder(
      column: $table.immutable, builder: (column) => ColumnOrderings(column));
}

class $$SetupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetupsTable> {
  $$SetupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bikeId =>
      $composableBuilder(column: $table.bikeId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get valuesJson => $composableBuilder(
      column: $table.valuesJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get immutable =>
      $composableBuilder(column: $table.immutable, builder: (column) => column);
}

class $$SetupsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SetupsTable,
    Setup,
    $$SetupsTableFilterComposer,
    $$SetupsTableOrderingComposer,
    $$SetupsTableAnnotationComposer,
    $$SetupsTableCreateCompanionBuilder,
    $$SetupsTableUpdateCompanionBuilder,
    (Setup, BaseReferences<_$AppDatabase, $SetupsTable, Setup>),
    Setup,
    PrefetchHooks Function()> {
  $$SetupsTableTableManager(_$AppDatabase db, $SetupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> bikeId = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String> valuesJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> immutable = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SetupsCompanion(
            id: id,
            bikeId: bikeId,
            label: label,
            valuesJson: valuesJson,
            createdAt: createdAt,
            immutable: immutable,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String bikeId,
            required String label,
            required String valuesJson,
            required DateTime createdAt,
            Value<bool> immutable = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SetupsCompanion.insert(
            id: id,
            bikeId: bikeId,
            label: label,
            valuesJson: valuesJson,
            createdAt: createdAt,
            immutable: immutable,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SetupsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SetupsTable,
    Setup,
    $$SetupsTableFilterComposer,
    $$SetupsTableOrderingComposer,
    $$SetupsTableAnnotationComposer,
    $$SetupsTableCreateCompanionBuilder,
    $$SetupsTableUpdateCompanionBuilder,
    (Setup, BaseReferences<_$AppDatabase, $SetupsTable, Setup>),
    Setup,
    PrefetchHooks Function()>;
typedef $$RidesTableCreateCompanionBuilder = RidesCompanion Function({
  required String id,
  required String bikeId,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  Value<double> distanceKm,
  Value<int> movingTimeSec,
  Value<String> summaryJson,
  Value<int> rowid,
});
typedef $$RidesTableUpdateCompanionBuilder = RidesCompanion Function({
  Value<String> id,
  Value<String> bikeId,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<double> distanceKm,
  Value<int> movingTimeSec,
  Value<String> summaryJson,
  Value<int> rowid,
});

class $$RidesTableFilterComposer extends Composer<_$AppDatabase, $RidesTable> {
  $$RidesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bikeId => $composableBuilder(
      column: $table.bikeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceKm => $composableBuilder(
      column: $table.distanceKm, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get movingTimeSec => $composableBuilder(
      column: $table.movingTimeSec, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summaryJson => $composableBuilder(
      column: $table.summaryJson, builder: (column) => ColumnFilters(column));
}

class $$RidesTableOrderingComposer
    extends Composer<_$AppDatabase, $RidesTable> {
  $$RidesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bikeId => $composableBuilder(
      column: $table.bikeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceKm => $composableBuilder(
      column: $table.distanceKm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get movingTimeSec => $composableBuilder(
      column: $table.movingTimeSec,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summaryJson => $composableBuilder(
      column: $table.summaryJson, builder: (column) => ColumnOrderings(column));
}

class $$RidesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RidesTable> {
  $$RidesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bikeId =>
      $composableBuilder(column: $table.bikeId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<double> get distanceKm => $composableBuilder(
      column: $table.distanceKm, builder: (column) => column);

  GeneratedColumn<int> get movingTimeSec => $composableBuilder(
      column: $table.movingTimeSec, builder: (column) => column);

  GeneratedColumn<String> get summaryJson => $composableBuilder(
      column: $table.summaryJson, builder: (column) => column);
}

class $$RidesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RidesTable,
    Ride,
    $$RidesTableFilterComposer,
    $$RidesTableOrderingComposer,
    $$RidesTableAnnotationComposer,
    $$RidesTableCreateCompanionBuilder,
    $$RidesTableUpdateCompanionBuilder,
    (Ride, BaseReferences<_$AppDatabase, $RidesTable, Ride>),
    Ride,
    PrefetchHooks Function()> {
  $$RidesTableTableManager(_$AppDatabase db, $RidesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RidesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RidesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RidesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> bikeId = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> endedAt = const Value.absent(),
            Value<double> distanceKm = const Value.absent(),
            Value<int> movingTimeSec = const Value.absent(),
            Value<String> summaryJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RidesCompanion(
            id: id,
            bikeId: bikeId,
            startedAt: startedAt,
            endedAt: endedAt,
            distanceKm: distanceKm,
            movingTimeSec: movingTimeSec,
            summaryJson: summaryJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String bikeId,
            required DateTime startedAt,
            Value<DateTime?> endedAt = const Value.absent(),
            Value<double> distanceKm = const Value.absent(),
            Value<int> movingTimeSec = const Value.absent(),
            Value<String> summaryJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RidesCompanion.insert(
            id: id,
            bikeId: bikeId,
            startedAt: startedAt,
            endedAt: endedAt,
            distanceKm: distanceKm,
            movingTimeSec: movingTimeSec,
            summaryJson: summaryJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RidesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RidesTable,
    Ride,
    $$RidesTableFilterComposer,
    $$RidesTableOrderingComposer,
    $$RidesTableAnnotationComposer,
    $$RidesTableCreateCompanionBuilder,
    $$RidesTableUpdateCompanionBuilder,
    (Ride, BaseReferences<_$AppDatabase, $RidesTable, Ride>),
    Ride,
    PrefetchHooks Function()>;
typedef $$RideChunksMetaTableCreateCompanionBuilder = RideChunksMetaCompanion
    Function({
  required String id,
  required String rideId,
  required int seq,
  required DateTime windowStart,
  required DateTime windowEnd,
  Value<String?> localPath,
  Value<int> rowid,
});
typedef $$RideChunksMetaTableUpdateCompanionBuilder = RideChunksMetaCompanion
    Function({
  Value<String> id,
  Value<String> rideId,
  Value<int> seq,
  Value<DateTime> windowStart,
  Value<DateTime> windowEnd,
  Value<String?> localPath,
  Value<int> rowid,
});

class $$RideChunksMetaTableFilterComposer
    extends Composer<_$AppDatabase, $RideChunksMetaTable> {
  $$RideChunksMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rideId => $composableBuilder(
      column: $table.rideId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seq => $composableBuilder(
      column: $table.seq, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get windowStart => $composableBuilder(
      column: $table.windowStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get windowEnd => $composableBuilder(
      column: $table.windowEnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));
}

class $$RideChunksMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $RideChunksMetaTable> {
  $$RideChunksMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rideId => $composableBuilder(
      column: $table.rideId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seq => $composableBuilder(
      column: $table.seq, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get windowStart => $composableBuilder(
      column: $table.windowStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get windowEnd => $composableBuilder(
      column: $table.windowEnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));
}

class $$RideChunksMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $RideChunksMetaTable> {
  $$RideChunksMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rideId =>
      $composableBuilder(column: $table.rideId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<DateTime> get windowStart => $composableBuilder(
      column: $table.windowStart, builder: (column) => column);

  GeneratedColumn<DateTime> get windowEnd =>
      $composableBuilder(column: $table.windowEnd, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);
}

class $$RideChunksMetaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RideChunksMetaTable,
    RideChunksMetaData,
    $$RideChunksMetaTableFilterComposer,
    $$RideChunksMetaTableOrderingComposer,
    $$RideChunksMetaTableAnnotationComposer,
    $$RideChunksMetaTableCreateCompanionBuilder,
    $$RideChunksMetaTableUpdateCompanionBuilder,
    (
      RideChunksMetaData,
      BaseReferences<_$AppDatabase, $RideChunksMetaTable, RideChunksMetaData>
    ),
    RideChunksMetaData,
    PrefetchHooks Function()> {
  $$RideChunksMetaTableTableManager(
      _$AppDatabase db, $RideChunksMetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RideChunksMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RideChunksMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RideChunksMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> rideId = const Value.absent(),
            Value<int> seq = const Value.absent(),
            Value<DateTime> windowStart = const Value.absent(),
            Value<DateTime> windowEnd = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RideChunksMetaCompanion(
            id: id,
            rideId: rideId,
            seq: seq,
            windowStart: windowStart,
            windowEnd: windowEnd,
            localPath: localPath,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String rideId,
            required int seq,
            required DateTime windowStart,
            required DateTime windowEnd,
            Value<String?> localPath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RideChunksMetaCompanion.insert(
            id: id,
            rideId: rideId,
            seq: seq,
            windowStart: windowStart,
            windowEnd: windowEnd,
            localPath: localPath,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RideChunksMetaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RideChunksMetaTable,
    RideChunksMetaData,
    $$RideChunksMetaTableFilterComposer,
    $$RideChunksMetaTableOrderingComposer,
    $$RideChunksMetaTableAnnotationComposer,
    $$RideChunksMetaTableCreateCompanionBuilder,
    $$RideChunksMetaTableUpdateCompanionBuilder,
    (
      RideChunksMetaData,
      BaseReferences<_$AppDatabase, $RideChunksMetaTable, RideChunksMetaData>
    ),
    RideChunksMetaData,
    PrefetchHooks Function()>;
typedef $$ConsentsTableCreateCompanionBuilder = ConsentsCompanion Function({
  required String id,
  required String key,
  required bool granted,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ConsentsTableUpdateCompanionBuilder = ConsentsCompanion Function({
  Value<String> id,
  Value<String> key,
  Value<bool> granted,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ConsentsTableFilterComposer
    extends Composer<_$AppDatabase, $ConsentsTable> {
  $$ConsentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get granted => $composableBuilder(
      column: $table.granted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ConsentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConsentsTable> {
  $$ConsentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get granted => $composableBuilder(
      column: $table.granted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ConsentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConsentsTable> {
  $$ConsentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<bool> get granted =>
      $composableBuilder(column: $table.granted, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ConsentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConsentsTable,
    Consent,
    $$ConsentsTableFilterComposer,
    $$ConsentsTableOrderingComposer,
    $$ConsentsTableAnnotationComposer,
    $$ConsentsTableCreateCompanionBuilder,
    $$ConsentsTableUpdateCompanionBuilder,
    (Consent, BaseReferences<_$AppDatabase, $ConsentsTable, Consent>),
    Consent,
    PrefetchHooks Function()> {
  $$ConsentsTableTableManager(_$AppDatabase db, $ConsentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConsentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConsentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConsentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> key = const Value.absent(),
            Value<bool> granted = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConsentsCompanion(
            id: id,
            key: key,
            granted: granted,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String key,
            required bool granted,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ConsentsCompanion.insert(
            id: id,
            key: key,
            granted: granted,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ConsentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ConsentsTable,
    Consent,
    $$ConsentsTableFilterComposer,
    $$ConsentsTableOrderingComposer,
    $$ConsentsTableAnnotationComposer,
    $$ConsentsTableCreateCompanionBuilder,
    $$ConsentsTableUpdateCompanionBuilder,
    (Consent, BaseReferences<_$AppDatabase, $ConsentsTable, Consent>),
    Consent,
    PrefetchHooks Function()>;
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  Value<int> id,
  Value<String?> remoteUpdatedAt,
  Value<String?> localUpdatedAt,
  Value<String?> lastDirection,
  Value<int> payloadVersion,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<int> id,
  Value<String?> remoteUpdatedAt,
  Value<String?> localUpdatedAt,
  Value<String?> lastDirection,
  Value<int> payloadVersion,
});

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteUpdatedAt => $composableBuilder(
      column: $table.remoteUpdatedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localUpdatedAt => $composableBuilder(
      column: $table.localUpdatedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastDirection => $composableBuilder(
      column: $table.lastDirection, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get payloadVersion => $composableBuilder(
      column: $table.payloadVersion,
      builder: (column) => ColumnFilters(column));
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteUpdatedAt => $composableBuilder(
      column: $table.remoteUpdatedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localUpdatedAt => $composableBuilder(
      column: $table.localUpdatedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastDirection => $composableBuilder(
      column: $table.lastDirection,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get payloadVersion => $composableBuilder(
      column: $table.payloadVersion,
      builder: (column) => ColumnOrderings(column));
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteUpdatedAt => $composableBuilder(
      column: $table.remoteUpdatedAt, builder: (column) => column);

  GeneratedColumn<String> get localUpdatedAt => $composableBuilder(
      column: $table.localUpdatedAt, builder: (column) => column);

  GeneratedColumn<String> get lastDirection => $composableBuilder(
      column: $table.lastDirection, builder: (column) => column);

  GeneratedColumn<int> get payloadVersion => $composableBuilder(
      column: $table.payloadVersion, builder: (column) => column);
}

class $$SyncStateTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncStateTable,
    SyncStateData,
    $$SyncStateTableFilterComposer,
    $$SyncStateTableOrderingComposer,
    $$SyncStateTableAnnotationComposer,
    $$SyncStateTableCreateCompanionBuilder,
    $$SyncStateTableUpdateCompanionBuilder,
    (
      SyncStateData,
      BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>
    ),
    SyncStateData,
    PrefetchHooks Function()> {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> remoteUpdatedAt = const Value.absent(),
            Value<String?> localUpdatedAt = const Value.absent(),
            Value<String?> lastDirection = const Value.absent(),
            Value<int> payloadVersion = const Value.absent(),
          }) =>
              SyncStateCompanion(
            id: id,
            remoteUpdatedAt: remoteUpdatedAt,
            localUpdatedAt: localUpdatedAt,
            lastDirection: lastDirection,
            payloadVersion: payloadVersion,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> remoteUpdatedAt = const Value.absent(),
            Value<String?> localUpdatedAt = const Value.absent(),
            Value<String?> lastDirection = const Value.absent(),
            Value<int> payloadVersion = const Value.absent(),
          }) =>
              SyncStateCompanion.insert(
            id: id,
            remoteUpdatedAt: remoteUpdatedAt,
            localUpdatedAt: localUpdatedAt,
            lastDirection: lastDirection,
            payloadVersion: payloadVersion,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncStateTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncStateTable,
    SyncStateData,
    $$SyncStateTableFilterComposer,
    $$SyncStateTableOrderingComposer,
    $$SyncStateTableAnnotationComposer,
    $$SyncStateTableCreateCompanionBuilder,
    $$SyncStateTableUpdateCompanionBuilder,
    (
      SyncStateData,
      BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>
    ),
    SyncStateData,
    PrefetchHooks Function()>;
typedef $$CatalogCacheTableCreateCompanionBuilder = CatalogCacheCompanion
    Function({
  required String id,
  required String slot,
  required String manufacturer,
  required String model,
  required String payloadJson,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$CatalogCacheTableUpdateCompanionBuilder = CatalogCacheCompanion
    Function({
  Value<String> id,
  Value<String> slot,
  Value<String> manufacturer,
  Value<String> model,
  Value<String> payloadJson,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

class $$CatalogCacheTableFilterComposer
    extends Composer<_$AppDatabase, $CatalogCacheTable> {
  $$CatalogCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get manufacturer => $composableBuilder(
      column: $table.manufacturer, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnFilters(column));
}

class $$CatalogCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $CatalogCacheTable> {
  $$CatalogCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get manufacturer => $composableBuilder(
      column: $table.manufacturer,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnOrderings(column));
}

class $$CatalogCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $CatalogCacheTable> {
  $$CatalogCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get manufacturer => $composableBuilder(
      column: $table.manufacturer, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CatalogCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CatalogCacheTable,
    CatalogCacheData,
    $$CatalogCacheTableFilterComposer,
    $$CatalogCacheTableOrderingComposer,
    $$CatalogCacheTableAnnotationComposer,
    $$CatalogCacheTableCreateCompanionBuilder,
    $$CatalogCacheTableUpdateCompanionBuilder,
    (
      CatalogCacheData,
      BaseReferences<_$AppDatabase, $CatalogCacheTable, CatalogCacheData>
    ),
    CatalogCacheData,
    PrefetchHooks Function()> {
  $$CatalogCacheTableTableManager(_$AppDatabase db, $CatalogCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatalogCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> slot = const Value.absent(),
            Value<String> manufacturer = const Value.absent(),
            Value<String> model = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> fetchedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CatalogCacheCompanion(
            id: id,
            slot: slot,
            manufacturer: manufacturer,
            model: model,
            payloadJson: payloadJson,
            fetchedAt: fetchedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String slot,
            required String manufacturer,
            required String model,
            required String payloadJson,
            required DateTime fetchedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CatalogCacheCompanion.insert(
            id: id,
            slot: slot,
            manufacturer: manufacturer,
            model: model,
            payloadJson: payloadJson,
            fetchedAt: fetchedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CatalogCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CatalogCacheTable,
    CatalogCacheData,
    $$CatalogCacheTableFilterComposer,
    $$CatalogCacheTableOrderingComposer,
    $$CatalogCacheTableAnnotationComposer,
    $$CatalogCacheTableCreateCompanionBuilder,
    $$CatalogCacheTableUpdateCompanionBuilder,
    (
      CatalogCacheData,
      BaseReferences<_$AppDatabase, $CatalogCacheTable, CatalogCacheData>
    ),
    CatalogCacheData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BikesTableTableManager get bikes =>
      $$BikesTableTableManager(_db, _db.bikes);
  $$ComponentsTableTableManager get components =>
      $$ComponentsTableTableManager(_db, _db.components);
  $$SetupsTableTableManager get setups =>
      $$SetupsTableTableManager(_db, _db.setups);
  $$RidesTableTableManager get rides =>
      $$RidesTableTableManager(_db, _db.rides);
  $$RideChunksMetaTableTableManager get rideChunksMeta =>
      $$RideChunksMetaTableTableManager(_db, _db.rideChunksMeta);
  $$ConsentsTableTableManager get consents =>
      $$ConsentsTableTableManager(_db, _db.consents);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$CatalogCacheTableTableManager get catalogCache =>
      $$CatalogCacheTableTableManager(_db, _db.catalogCache);
}
