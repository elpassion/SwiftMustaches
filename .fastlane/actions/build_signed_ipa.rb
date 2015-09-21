module Fastlane
  module Actions
    module SharedValues
      IPA_OUTPUT_PATH = :IPA_OUTPUT_PATH
    end

    class BuildSignedIpaAction < Action
      def self.run(params)
        workspace_path        = params[:workspace_path]
        scheme                = params[:scheme]
        configuration         = params[:configuration]
        sdk                   = params[:sdk]
        build_path            = params[:build_path]
        app_name              = params[:app_name]
        sign_identity         = params[:sign_identity]
        mobileprovision_path  = params[:mobileprovision_path]
        mobileprovision_uuid  = params[:mobileprovision_uuid]

        Helper.log.info 'Building application...'

        Actions.sh [
          "xctool",
          "clean",
          "build",
          "-workspace", "\"#{workspace_path}\"",
          "-scheme", "\"#{scheme}\"",
          "-configuration", "\"#{configuration}\"",
          "-sdk", "\"#{sdk}\"",
          "ONLY_ACTIVE_ARCH=NO",
          "CONFIGURATION_BUILD_DIR=\"#{build_path}\"",
          "PROVISIONING_PROFILE=\"#{mobileprovision_uuid}\""
        ].join(" ")
        
        Helper.log.info 'Creating signed IPA file...'

        ipa_path = "#{build_path}/#{app_name}.ipa"

        Actions.sh [
          "xcrun",
          "-log", 
          "-sdk", "#{sdk}", 
          "PackageApplication" ,
          "\"#{build_path}/#{app_name}.app\"", 
          "-o", "\"#{ipa_path}\"", 
          "-sign", "\"#{sign_identity}\"", 
          "-embed", "\"#{mobileprovision_path}\""
        ].join(" ")

        Actions.lane_context[Actions::SharedValues::IPA_OUTPUT_PATH] = "#{ipa_path}"

      end

      def self.description
        "Clean and build using xctool then create IPA with xcrun PackageApplication"
      end

      def self.available_options
        [
          ['workspace_path', 'Path to .xcworkspace file'],
          ['scheme', 'Build scheme'],
          ['configuration', 'Build configuration (e.g. "Release")'],
          ['sdk', 'SDK to use (e.g. "iphoneos")'],
          ['build_path', 'Build directory path'],
          ['app_name', 'Application name'],
          ['sign_identity', 'Signing identity (e.g. "iPhone Distribution: MyCompany")'],
          ['mobileprovision_path', 'Path to .mobileprovision file'],
          ['mobileprovision_uuid', 'Mobile Provisioning Profile UUID'],
        ]
      end

      def self.output
        [
          ['IPA_OUTPUT_PATH', 'Path to IPA file']
        ]
      end

      def self.author
        "Darrarski"
      end

      def self.is_supported?(platform)
        platform == :ios
      end
      
    end
  end
end