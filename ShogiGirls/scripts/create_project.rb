require 'xcodeproj'
root = File.expand_path('..', __dir__)
project = Xcodeproj::Project.new(File.join(root, 'ShogiGirls.xcodeproj'))
app = project.new_target(:application, 'ShogiGirls', :ios, '16.0')
tests = project.new_target(:ui_test_bundle, 'ShogiGirlsUITests', :ios, '16.0')
tests.add_dependency(app)
group = project.main_group.new_group('Sources')
Dir[File.join(root, 'Sources', 'ShogiCore', '*.swift'), File.join(root, 'App', '*.swift')].sort.each { |p| app.source_build_phase.add_file_reference(group.new_file(p.delete_prefix(root + '/'))) }
resources = project.main_group.new_group('Resources')
Dir[File.join(root, 'App', 'Resources', '*')].sort.each { |p| app.resources_build_phase.add_file_reference(resources.new_file(p.delete_prefix(root + '/'))) }
Dir[File.join(root, 'UITests', '*.swift')].each { |p| tests.source_build_phase.add_file_reference(group.new_file(p.delete_prefix(root + '/'))) }
project.build_configurations.each { |c| c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0' }
app.build_configurations.each do |c|
  c.build_settings.merge!({ 'SWIFT_VERSION' => '5.0', 'PRODUCT_BUNDLE_IDENTIFIER' => 'com.takeo.ShogiGirls', 'INFOPLIST_FILE' => 'App/Info.plist', 'TARGETED_DEVICE_FAMILY' => '1,2', 'DEVELOPMENT_TEAM' => 'JS3245KG7Q', 'CODE_SIGN_STYLE' => 'Automatic', 'MARKETING_VERSION' => '1.0.0', 'CURRENT_PROJECT_VERSION' => '1', 'SWIFT_OPTIMIZATION_LEVEL' => '-O', 'ASSETCATALOG_COMPILER_APPICON_NAME' => 'AppIcon' })
  c.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG' if c.name == 'Debug'
end
tests.build_configurations.each { |c| c.build_settings.merge!({ 'SWIFT_VERSION' => '5.0', 'PRODUCT_BUNDLE_IDENTIFIER' => 'com.takeo.ShogiGirls.UITests', 'GENERATE_INFOPLIST_FILE' => 'YES', 'TEST_TARGET_NAME' => 'ShogiGirls', 'DEVELOPMENT_TEAM' => 'JS3245KG7Q' }) }
package = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
package.repositoryURL = 'https://github.com/googleads/swift-package-manager-google-mobile-ads.git'
package.requirement = { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => '12.0.0' }
project.root_object.package_references << package
product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
product.package = package; product.product_name = 'GoogleMobileAds'
app.package_product_dependencies << product
build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
build_file.product_ref = product
app.frameworks_build_phase.files << build_file
ump = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
ump.repositoryURL = 'https://github.com/googleads/swift-package-manager-google-user-messaging-platform.git'
ump.requirement = { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => '3.0.0' }
project.root_object.package_references << ump
ump_product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
ump_product.package = ump; ump_product.product_name = 'GoogleUserMessagingPlatform'
app.package_product_dependencies << ump_product
ump_file = project.new(Xcodeproj::Project::Object::PBXBuildFile); ump_file.product_ref = ump_product
app.frameworks_build_phase.files << ump_file
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.set_launch_target(app)
scheme.add_test_target(tests)
scheme.save_as(project.path, 'ShogiGirls', true)
