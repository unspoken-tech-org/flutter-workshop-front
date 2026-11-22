class EnvConfig {
  EnvConfig._();

  static String get githubOwner => const String.fromEnvironment('GITHUB_OWNER');
  static String get githubRepo => const String.fromEnvironment('GITHUB_REPO');
  static String get updateFeedUrl =>
      const String.fromEnvironment('UPDATE_FEED_URL');
}
