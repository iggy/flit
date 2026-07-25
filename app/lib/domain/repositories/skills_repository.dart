import 'package:flit/domain/models/skill_catalog.dart';

/// Intent-level skills operations (ticket P5-09).
abstract interface class SkillsRepository {
  /// `skills.manage {action:'list'}` → skill catalog grouped by category.
  Future<SkillCatalog> list();

  /// `skills.manage {action:'browse', page, page_size}` → paginated browse.
  Future<SkillBrowseResult> browse({int page = 1, int pageSize = 20});

  /// `skills.reload {}` → reload results (added/removed/unchanged).
  Future<SkillReloadResult> reload();
}
