#!/usr/bin/env ruby
# Adjust a CocoaPods-generated iOS workspace so Swift Build (sweetpad on Linux) builds it as Xcode does.
#   ruby pods/fix-pods-project.rb <ios-dir>
# Each fix covers a behavior Xcode has that Swift Build, given the same project, does not:
#  1. Swift package products in a target's packageProductDependencies are linked by Xcode even
#     with no Frameworks build file. React Native's spm_dependency bridge only adds the dependency.
#  2. A Clang module a package builds (Stripe3DS2) is found by Xcode in importers of the package's
#     Swift modules; Swift Build only passes its generated module map to direct dependents.
#  3. Icon Composer .icon folders that `expo prebuild` adds with lastKnownFileType "unknown" are
#     still sent to actool by Xcode; Swift Build needs the folder.iconcomposer.icon type.
require 'xcodeproj'

ios = ARGV.fetch(0) { abort 'usage: fix-pods-project.rb <ios-dir>' }

pods = Xcodeproj::Project.open(File.join(ios, 'Pods', 'Pods.xcodeproj'))
changed = false
pods.native_targets.each do |target|
  deps = target.package_product_dependencies
  next if deps.empty?

  phase = target.frameworks_build_phase
  linked = phase.files.map(&:product_ref).compact
  (deps - linked).each do |dep|
    file = pods.new(Xcodeproj::Project::Object::PBXBuildFile)
    file.product_ref = dep
    phase.files << file
    changed = true
    puts "#{target.name}: link package product #{dep.product_name}"
  end

  # Clang modules among the package's targets: products whose name has no Swift module of its own
  # are not visible here, so name the ones known to be imported transitively.
  next unless deps.any? { |d| d.product_name.start_with?('Stripe') }

  flag = '-Xcc -fmodule-map-file=$(OBJROOT)/GeneratedModuleMaps-$(PLATFORM_NAME)/Stripe3DS2.modulemap'
  target.build_configurations.each do |config|
    xcconfig = config.base_configuration_reference&.real_path
    next unless xcconfig && File.exist?(xcconfig)

    text = File.read(xcconfig)
    next if text.include?('Stripe3DS2.modulemap')

    text = text.sub(/^OTHER_SWIFT_FLAGS = \$\(inherited\)/, "OTHER_SWIFT_FLAGS = $(inherited) #{flag}")
    File.write(xcconfig, text)
    puts "#{target.name} (#{config.name}): Stripe3DS2 module map"
  end
end
pods.save if changed

Dir.glob(File.join(ios, '*.xcodeproj')).each do |path|
  app = Xcodeproj::Project.open(path)
  icons = app.files.select { |f| f.path.to_s.end_with?('.icon') && f.last_known_file_type != 'folder.iconcomposer.icon' }
  next if icons.empty?

  icons.each do |f|
    f.last_known_file_type = 'folder.iconcomposer.icon'
    f.explicit_file_type = nil
    puts "#{File.basename(path)}: #{f.path} as folder.iconcomposer.icon"
  end
  app.save
end
