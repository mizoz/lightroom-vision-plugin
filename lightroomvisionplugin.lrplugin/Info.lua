return {
  LrSdkVersion = 6.0,
  LrSdkMinimumVersion = 6.0,
  LrPluginName = "Vision Analyzer",
  LrToolkitIdentifier = "com.mizoz.lightroom.visionanalyzer",
  LrPluginInfoUrl = "https://github.com/mizoz/lightroom-vision-plugin",
  LrLibraryMenuItems = {
      {
          title = "Generate Alt Text",
          file = "AltTextGenerator.lua",
      },
      {
          title = "Extract Keywords",
          file = "KeywordExtractor.lua",
      },
      {
          title = "Full Analysis",
          file = "FullAnalyzer.lua",
      },
  },
  LrPluginInfoProvider = 'PluginInfoProvider.lua',
  VERSION = { major=1, minor=0, revision=0, build=0, },
}
