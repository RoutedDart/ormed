library;

import 'package:ormed/src/annotations.dart';
import 'package:ormed/src/query/query.dart';
import 'package:ormed/src/query/query_plan.dart';

import '../model_definition.dart';

/// Utility class for resolving and building relation metadata.
///
/// This class extracts shared logic for relation resolution used by both
/// the query builder and lazy loading on models.
class RelationResolver {
  const RelationResolver(this.context);

  final QueryContext context;

  /// Resolves a dotted relation path (e.g., "posts.comments") into segments.
  ///
  /// Each segment contains the metadata needed to load that part of the relation.
  ///
  /// Example:
  /// ```dart
  /// final resolver = RelationResolver(context);
  /// final path = resolver.resolvePath(userDefinition, 'posts.comments');
  /// // Returns: RelationPath with segments for 'posts' and 'comments'
  /// ```
  ///
  /// Throws [ArgumentError] if any part of the relation path is invalid.
  RelationPath resolvePath(
    ModelDefinition<dynamic> startDefinition,
    String relation,
  ) {
    final names = relation.split('.');
    final segments = <RelationSegment>[];
    ModelDefinition<dynamic> current = startDefinition;

    for (final name in names) {
      final relationDef = current.relations
          .cast<RelationDefinition?>()
          .firstWhere((r) => r?.name == name, orElse: () => null);

      if (relationDef == null) {
        throw ArgumentError.value(
          relation,
          'relation',
          'Unknown relation $name on ${current.modelName}.',
        );
      }

      final segment = segmentFor(current, relationDef);
      segments.add(segment);
      current = segment.targetDefinition;
    }

    return RelationPath(segments: segments);
  }

  /// Builds a [RelationSegment] for a single relation.
  ///
  /// Contains all the metadata needed to load this relation, including
  /// foreign keys, pivot tables, morph columns, etc.
  ///
  /// Example:
  /// ```dart
  /// final resolver = RelationResolver(context);
  /// final segment = resolver.segmentFor(postDefinition, commentsRelation);
  /// // Returns: RelationSegment with childKey, parentKey, etc.
  /// ```
  RelationSegment segmentFor(
    ModelDefinition<dynamic> parent,
    RelationDefinition relation,
  ) {
    final target = context.registry.expectByName(relation.targetModel);
    final parentKey = relation.localKey ?? parent.primaryKeyField?.columnName;

    if (parentKey == null) {
      throw StateError('Relation ${relation.name} requires a parent key.');
    }

    switch (relation.kind) {
      case RelationKind.hasOne:
      case RelationKind.hasMany:
        final childKey = relation.foreignKey ?? '${parent.tableName}_id';
        return RelationSegment(
          name: relation.name,
          relation: relation,
          parentDefinition: parent,
          targetDefinition: target,
          parentKey: parentKey,
          childKey: childKey,
          expectSingleResult: relation.kind == RelationKind.hasOne,
        );

      case RelationKind.belongsTo:
        final foreignKey = relation.foreignKey ?? '${relation.name}_id';
        final ownerKey =
            relation.localKey ?? target.primaryKeyField?.columnName;
        if (ownerKey == null) {
          throw StateError('Relation ${relation.name} requires a target key.');
        }
        return RelationSegment(
          name: relation.name,
          relation: relation,
          parentDefinition: parent,
          targetDefinition: target,
          parentKey: foreignKey,
          childKey: ownerKey,
          foreignKeyOnParent: true,
          expectSingleResult: true,
        );

      case RelationKind.manyToMany:
        final pivotTable =
            relation.through ?? '${parent.tableName}_${target.tableName}';
        final pivotParentKey =
            relation.pivotForeignKey ?? '${parent.tableName}_id';
        final pivotRelatedKey =
            relation.pivotRelatedKey ?? '${target.tableName}_id';
        final targetKey =
            relation.localKey ?? target.primaryKeyField?.columnName;
        if (targetKey == null) {
          throw StateError('Relation ${relation.name} requires a target key.');
        }
        return RelationSegment(
          name: relation.name,
          relation: relation,
          parentDefinition: parent,
          targetDefinition: target,
          parentKey: parentKey,
          childKey: targetKey,
          pivotTable: pivotTable,
          pivotParentKey: pivotParentKey,
          pivotRelatedKey: pivotRelatedKey,
        );

      case RelationKind.morphOne:
      case RelationKind.morphMany:
        final childKey =
            relation.foreignKey ??
            (throw StateError(
              'Relation ${relation.name} requires a foreign key.',
            ));
        final morphColumn =
            relation.morphType ??
            (throw StateError(
              'Relation ${relation.name} requires a morph type column.',
            ));
        final morphClass =
            relation.morphClass ??
            (throw StateError(
              'Relation ${relation.name} requires a morph class.',
            ));
        return RelationSegment(
          name: relation.name,
          relation: relation,
          parentDefinition: parent,
          targetDefinition: target,
          parentKey: parentKey,
          childKey: childKey,
          morphTypeColumn: morphColumn,
          morphClass: morphClass,
          expectSingleResult: relation.kind == RelationKind.morphOne,
        );
    }
  }

  /// Converts a constraint callback to a [QueryPredicate].
  ///
  /// This allows constraint callbacks to be converted into predicates
  /// that can be applied to relation queries.
  ///
  /// Example:
  /// ```dart
  /// final resolver = RelationResolver(context);
  /// final predicate = resolver.predicateFor(
  ///   commentsRelation,
  ///   (q) => q.where('approved', true),
  /// );
  /// ```
  ///
  /// Returns `null` if no constraint is provided.
  QueryPredicate? predicateFor(
    RelationDefinition relation,
    PredicateCallback<dynamic>? constraint,
  ) {
    if (constraint == null) return null;

    final target = context.registry.expectByName(relation.targetModel);
    final builder = PredicateBuilder<dynamic>(target);
    constraint(builder);
    return builder.build();
  }

  /// Converts a constraint callback to a [QueryPredicate] using a relation path.
  ///
  /// This is useful for nested relation constraints where you need the
  /// final target definition from the path.
  ///
  /// Example:
  /// ```dart
  /// final resolver = RelationResolver(context);
  /// final path = resolver.resolvePath(userDef, 'posts.comments');
  /// final predicate = resolver.predicateForPath(
  ///   path,
  ///   (q) => q.where('approved', true),
  /// );
  /// ```
  ///
  /// Returns `null` if no constraint is provided.
  QueryPredicate? predicateForPath(
    RelationPath path,
    PredicateCallback<dynamic>? constraint,
  ) {
    if (constraint == null) return null;

    final builder = PredicateBuilder<dynamic>(path.leaf.targetDefinition);
    constraint(builder);
    return builder.build();
  }
}
