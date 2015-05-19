require 'erb'
require 'ostruct'
require 'shenzhen'

module Fastlane
  module Actions

    module SharedValues
      S3_IPA_OUTPUT_PATH = :S3_IPA_OUTPUT_PATH
      S3_DSYM_OUTPUT_PATH = :S3_DSYM_OUTPUT_PATH
    end

    S3_ARGS_MAP = {
      ipa: '-f',
      dsym: '-d',
      access_key: '-a',
      secret_access_key: '-s',
      bucket: '-b',
      region: '-r',
      acl: '--acl',
      source: '--source-dir',p
      path: '-P',
    }

    class S3Action < Action
      def self.run(config)

        # Calling fetch on config so that default values will be used
        params = {}
        params[:ipa] = config[:ipa]
        params[:dsym] = config[:dsym]
        params[:access_key] = config[:access_key]
        params[:secret_access_key] = config[:secret_access_key]
        params[:bucket] = config[:bucket]
        params[:region] = config[:region]
        params[:acl] = config[:acl]
        params[:source] = config[:source]
        params[:path] = config[:path]

        # Maps nice developer build parameters to Shenzhen args
        build_args = params_to_build_args(params)

        # Pulling parameters for other uses
        s3_subdomain = params[:region] ? "s3-#{params[:region]}" : "s3"
        s3_access_key = params[:access_key]
        s3_secret_access_key = params[:secret_access_key]
        s3_bucket = params[:bucket]
        ipa_file = params[:ipa]
        dsym_file = params[:dsym]
        s3_path = params[:path]

        raise "No S3 access key given, pass using `access_key: 'key'`".red unless s3_access_key.to_s.length > 0
        raise "No S3 secret access key given, pass using `secret_access_key: 'secret key'`".red unless s3_secret_access_key.to_s.length > 0
        raise "No S3 bucket given, pass using `bucket: 'bucket'`".red unless s3_bucket.to_s.length > 0
        raise "No IPA file path given, pass using `ipa: 'ipa path'`".red unless ipa_file.to_s.length > 0

        if Helper.is_test?
          return build_args 
        end

        # Joins args into space delimited string
        build_args = build_args.join(' ')

        command = "ipa distribute:s3 #{build_args}"
        Helper.log.debug command
        Actions.sh command

        # Gets info used for the plist
        bundle_id, bundle_version, title = get_ipa_info( ipa_file )

        # Gets URL for IPA file
        url_part = expand_path_with_substitutions_from_ipa_plist( ipa_file, s3_path )
        ipa_file_name = File.basename(ipa_file)
        ipa_url = "https://#{s3_subdomain}.amazonaws.com/#{s3_bucket}/#{url_part}#{ipa_file_name}"
        dsym_url = "https://#{s3_subdomain}.amazonaws.com/#{s3_bucket}/#{url_part}#{dsym_file}" if dsym_file

        # Setting action and environment variables
        Actions.lane_context[SharedValues::S3_IPA_OUTPUT_PATH] = ipa_url
        ENV[SharedValues::S3_IPA_OUTPUT_PATH.to_s] = ipa_url

        if dsym_file
          Actions.lane_context[SharedValues::S3_DSYM_OUTPUT_PATH] = dsym_url
          ENV[SharedValues::S3_DSYM_OUTPUT_PATH.to_s] = dsym_url
        end

        return true

      end

      def self.params_to_build_args(params)
        # Remove nil value params unless :clean or :archive
        params = params.delete_if { |k, v| (k != :clean && k != :archive ) && v.nil? }

        # Maps nice developer param names to Shenzhen's `ipa build` arguments
        params.collect do |k,v|
          v ||= ''
          if args = S3_ARGS_MAP[k]
            value = (v.to_s.length > 0 ? "\"#{v}\"" : "")
            "#{S3_ARGS_MAP[k]} #{value}".strip
          end
        end.compact
      end

      #
      # NOT a fan of this as this was taken straight from Shenzhen
      # https://github.com/nomad/shenzhen/blob/986792db5d4d16a80c865a2748ee96ba63644821/lib/shenzhen/plugins/s3.rb#L32
      # 
      # Need to find a way to not use this copied method
      #
      # AGAIN, I am not happy about this right now.
      # Using this for prototype reasons.
      #
      def self.expand_path_with_substitutions_from_ipa_plist(ipa, path)
        substitutions = path.scan(/\{CFBundle[^}]+\}/)
        return path if substitutions.empty?

        Dir.mktmpdir do |dir|
          system "unzip -q #{ipa} -d #{dir} 2> /dev/null"

          plist = Dir["#{dir}/**/*.app/Info.plist"].last

          substitutions.uniq.each do |substitution|
            key = substitution[1...-1]
            value = Shenzhen::PlistBuddy.print(plist, key)

            path.gsub!(Regexp.new(substitution), value) if value
          end
        end

        return path
      end

      def self.get_ipa_info(ipa_file)
        bundle_id, bundle_version, title = nil
        Dir.mktmpdir do |dir|

          system "unzip -q #{ipa_file} -d #{dir} 2> /dev/null"
          plist = Dir["#{dir}/**/*.app/Info.plist"].last

          bundle_id = Shenzhen::PlistBuddy.print(plist, 'CFBundleIdentifier')
          bundle_version = Shenzhen::PlistBuddy.print(plist, 'CFBundleShortVersionString')
          title = Shenzhen::PlistBuddy.print(plist, 'CFBundleName')

        end
        return bundle_id, bundle_version, title
      end

      def self.description
        "Generates a plist file and uploads all to AWS S3"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :ipa,
                                       env_name: "",
                                       description: ".ipa file for the build ",
                                       optional: true,
                                       default_value: Actions.lane_context[SharedValues::IPA_OUTPUT_PATH]),
          FastlaneCore::ConfigItem.new(key: :dsym,
                                       env_name: "",
                                       description: "zipped .dsym package for the build ",
                                       optional: true,
                                       default_value: Actions.lane_context[SharedValues::DSYM_OUTPUT_PATH]),
          FastlaneCore::ConfigItem.new(key: :plist_template_path,
                                       env_name: "",
                                       description: "plist template path",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :html_template_path,
                                       env_name: "",
                                       description: "html erb template path",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :html_file_name,
                                       env_name: "",
                                       description: "uploaded html filename",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :access_key,
                                       env_name: "S3_ACCESS_KEY",
                                       description: "AWS Access Key ID ",
                                       optional: true,
                                       default_value: ENV['AWS_ACCESS_KEY_ID']),
          FastlaneCore::ConfigItem.new(key: :secret_access_key,
                                       env_name: "S3_SECRET_ACCESS_KEY",
                                       description: "AWS Secret Access Key ",
                                       optional: true,
                                       default_value: ENV['AWS_SECRET_ACCESS_KEY']),
          FastlaneCore::ConfigItem.new(key: :bucket,
                                       env_name: "S3_BUCKET",
                                       description: "AWS bucket name",
                                       optional: true,
                                       default_value: ENV['AWS_BUCKET_NAME']),
          FastlaneCore::ConfigItem.new(key: :region,
                                       env_name: "S3_REGION",
                                       description: "AWS region (for bucket creation) ",
                                       optional: true,
                                       default_value: ENV['AWS_REGION']),
          FastlaneCore::ConfigItem.new(key: :path,
                                       env_name: "S3_PATH",
                                       description: "S3 'path'. Values from Info.plist will be substituded for keys wrapped in {}  ",
                                       optional: true,
                                       default_value: 'v{CFBundleShortVersionString}_b{CFBundleVersion}/'),
          FastlaneCore::ConfigItem.new(key: :source,
                                       env_name: "S3_SOURCE",
                                       description: "Optional source directory e.g. ./build ",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :acl,
                                       env_name: "S3_ACL",
                                       description: "Uploaded object permissions e.g public_read (default), private, public_read_write, authenticated_read ",
                                       optional: true,),
        ]
      end

      def self.output
        [
          ['S3_IPA_OUTPUT_PATH', 'Direct HTTP link to the uploaded ipa file'],
          ['S3_DSYM_OUTPUT_PATH', 'Direct HTTP link to the uploaded dsym file']
        ]
      end

      def self.author
        "joshdholtz"
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end

class ErbalT < OpenStruct
  def render(template)
    ERB.new(template).result(binding)
  end
end
