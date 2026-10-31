import 'dart:io';

/// Skip reason for tests that need the copyrighted PSX files in assets/test.
///
/// That folder is gitignored and only exists on a developer's machine, so CI
/// skips these tests and relies on the synthetic-data tests instead.
final Object skipWithoutLocalTestData = Directory('assets/test').existsSync()
    ? false
    : 'Requires local PSX test data in assets/test';
