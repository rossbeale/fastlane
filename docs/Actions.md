# Actions

There are lots of predefined `fastlane` actions you can use. If you have ideas for more, please [let me know](https://github.com/KrauseFx/fastlane/issues/new).

To get the most up-to-date information from the command line on your current verion you can also run:

```sh
fastlane actions: List all available fastlane actions
fastlane action [action_name]:
```

- [Building](#building)
- [Testing](#testing)
- [Deploying](#deploying)
- [Modifying Project](#modifying-project)
- [Developer Portal](#developer-portal)
- [Using git](#using-git)
- [Notifications](#notifications)

## Building

### [CocoaPods](http://cocoapods.org)

Everyone using [CocoaPods](http://cocoapods.org) will probably want to run a ```pod install``` before running tests and building the app.

```ruby
cocoapods # this will run pod install
```

### [Carthage](https://github.com/Carthage/Carthage)

This will execute `carthage bootstrap`

```ruby
carthage
```

### [xctool](https://github.com/facebook/xctool)

You can run any xctool action. This will require having [xctool](https://github.com/facebook/xctool) installed through [homebrew](http://brew.sh/).

```ruby
xctool :test
```

It is recommended to have the `xctool` configuration stored in a [`.xctool-args`](https://github.com/facebook/xctool#configuration-xctool-args) file.

If you prefer to have the build configuration stored in the `Fastfile`:

```ruby
xctool :test, [
      "--workspace", "'AwesomeApp.xcworkspace'",
      "--scheme", "'Schema Name'",
      "--configuration", "Debug",
      "--sdk", "iphonesimulator",
      "--arch", "i386"
    ].join(" ")
```


### [snapshot](https://github.com/KrauseFx/snapshot)

```ruby
snapshot
```

To make `snapshot` work without user interaction, follow the [CI-Guide of `snapshot`](https://github.com/KrauseFx/snapshot#run-in-continuous-integration).

To skip cleaning the project on every build:
```ruby
snapshot :noclean
```

To show the output of `UIAutomation`:
```ruby
snapshot :verbose
```

### ipa

Build your app right inside `fastlane` and the path to the resulting ipa is automatically available to all other actions.

```ruby
ipa(
  workspace: "MyApp.xcworkspace",
  configuration: "Debug",
  scheme: "MyApp",
  # (optionals)
  clean: true,                     # This means 'Do Clean'. Cleans project before building (the default if not specified).
  destination: "path/to/dir",      # Destination directory. Defaults to current directory.
  ipa: "my-app.ipa",               # specify the name of the .ipa file to generate (including file extension)
  xcargs: "MY_ADHOC=0",            # pass additional arguments to xcodebuild when building the app.
  embed: "my.mobileprovision",     # Sign .ipa file with .mobileprovision
  identity: "MyIdentity",          # Identity to be used along with --embed
  sdk: "10.0",                     # use SDK as the name or path of the base SDK when building the project.
  archive: nil,                    # this means 'Do Archive'. Archive project after building.
  verbose: nil,                    # this means 'Do Verbose'.
)
```

The `ipa` action uses [shenzhen](https://github.com/nomad/shenzhen) under the hood.

The path to the `ipa` is automatically used by `Crashlytics`, `Hockey` and `DeployGate`.


**Important:**

To also use it in `deliver`, update your `Deliverfile` and remove all code in the `Building and Testing` section, in particular all `ipa` and `beta_ipa` blocks.

### [xcode_select](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/xcode-select.1.html)
Use this command if you are supporting multiple versions of Xcode

```ruby
xcode_select "/Applications/Xcode6.1.app"
```

### [resign](https://github.com/krausefx/sigh#resign)
This will resign an ipa with another signing identity and provisioning profile.

If you have used the `ipa` and `sigh` actions, then this action automatically gets the `ipa` and `provisioning_profile` values respectively from those actions and you don't need to manually set them (although you can always override them).

```ruby
resign(
  ipa: 'path/to/ipa', # can omit if using the `ipa` action
  signing_identity: 'iPhone Distribution: Luka Mirosevic (0123456789)',
  provisioning_profile: 'path/to/profile', # can omit if using the `sigh` action
)
```

### [xcodebuild](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/xcodebuild.1.html)
Enables the use of the `xcodebuild` tool within fastlane to perform xcode tasks
such as; archive, build, clean, test, export & more.

```ruby
# Create an archive. (./build-dir/MyApp.xcarchive)
xcodebuild(
  archive: true,
  archive_path: './build-dir/MyApp.xcarchive',
  scheme: 'MyApp',
  workspace: 'MyApp.xcworkspace'
)
```

`build_settings` are variables which are exposed inside the build process as ENV variables, and can be used to override project settings, or dynamically set values inside a Plist.

`output_style` sets the output format of the console output. Supported options are: 1) `:standard`, this is the default and will output pretty colored UTF8, and 2) `:basic`, which will output monochrome ASCII, useful for a CI environment like TeamCity that doesn't support color/UTF8.

```ruby
xcodebuild(
  workspace: "...",
  scheme: "...",
  build_settings: {
    "CODE_SIGN_IDENTITY" => "iPhone Developer: ...",
    "PROVISIONING_PROFILE" => "...",
    "JOBS" => 16
  },
  output_style: :basic
)
```

To keep your Fastfile lightweight, there are also alias actions available for
the most common `xcodebuild` operations: `xcarchive`, `xcbuild`, `xcclean`, `xctest` & `xcexport`.

Environment variables may be added to a .env file in place of some parameters:

```
XCODE_PROJECT="./MyApp.xcodeproj"
XCODE_WORKSPACE="./MyApp.xcworkspace"
XCODE_SCHEME="MyApp"
XCODE_BUILD_PATH="./build"
```

More usage examples (assumes the above .env setup is being used):
```ruby
  # Clean the project
  xcclean

  # Build the project
  xcbuild

  # Run tests in given simulator
  xctest(
    destination: "name=iPhone 5s,OS=8.1"
  )

  # Create an archive (./build-dir/MyApp.xcarchive)
  xcarchive

  # Export a signed binary (./build-dir/MyApp.ipa)
  xcexport
```

### clean_build_artifacts
This action deletes the files that get created in your repo as a result of running the `ipa` and `sigh` commands. It doesn't delete the `fastlane/report.xml` though, this is probably more suited for the .gitignore.

Useful if you quickly want to send out a test build by dropping down to the command line and typing something like `fastlane beta`, without leaving your repo in a messy state afterwards.

```ruby
clean_build_artifacts
```

### [frameit](https://github.com/KrauseFx/frameit)
By default, the device color will be black
```ruby
frameit
```

To use white (sorry, silver) device frames
```ruby
frameit :silver
```

### dsym_zip

Create a zipped dSYM file from your `.xcarchive`, useful if you use the `xcodebuild` action in combination with `crashlytics` or `hockey`.

```ruby
dsym_zip
```

You can manually specify the path to the xcarchive (not needed if you use `xcodebuild`/`xcarchive` to build your archive):

```ruby
dsym_zip(
  archive_path: 'MyApp.xcarchive'
)
```

## Testing

### xctest

Use the `xctest` command to run unit tests.

When running tests, coverage reports can be generated via [xcpretty](https://github.com/supermarin/xcpretty) reporters:
```ruby
  # Run tests in given simulator
  xctest(
    destination: "name=iPhone 5s,OS=8.1",
    reports: [{
      report: 'html',
      output: './build-dir/test-report.html',  # will use XCODE_BUILD_PATH/report, if output is not provided
      screenshots: 1
    },
    {
      report: 'junit',
      output: './build-dir/test-report.xml'
    }]
  )
```

### [gcovr](http://gcovr.com/)
Generate summarized code coverage reports.

```ruby
gcovr(
  html: true,
  html_details: true,
  output: "./code-coverage/report.html"
)
```

### [OCLint](http://oclint.org)
Run the static analyzer tool [OCLint](http://oclint.org) for your project. You need to have a `compile_commands.json` file in your `fastlane` directory or pass a path to your file.

```
oclint({
  compile_commands: 'commands.json', # The json compilation database, use xctool reporter 'json-compilation-database'
  select_reqex: /ViewController.m/,  # Select all files matching this reqex
  report_type: 'pmd',                # The type of the report (default: html)
  max_priority_1: 10,                # The max allowed number of priority 1 violations
  max_priority_2: 100,               # The max allowed number of priority 2 violations
  max_priority_3: 1000,              # The max allowed number of priority 3 violations
  rc: 'LONG_LINE=200'                # Override the default behavior of rules
})  
```

## Deploying

### [deliver](https://github.com/KrauseFx/deliver)
```ruby
deliver
```

To upload a new build to TestFlight use ```deliver(beta: true)```.

If you don't want a PDF report for App Store builds, append ```:force``` to the command. This is useful when running ```fastlane``` on your Continuous Integration server: `deliver(force: true)`

Other options

```ruby
deliver(
  force: true,# Set to true to skip PDF verification
  beta: true, # Upload a new version to TestFlight
  skip_deploy: true, # To don't submit the app for review (works with both App Store and beta builds)
  deliver_file_path: './nothere' # Specify a path to the directory containing the Deliverfile
)
```

If you want to use a different Apple ID for iTunes Connect in `deliver`, just add this to your `Deliverfile`:

```ruby
email "itunes@connect.com"
```

### [HockeyApp](http://hockeyapp.net)
```ruby
hockey(
  api_token: '...',
  ipa: './app.ipa',
  notes: "Changelog"
)
```

Symbols will also be uploaded automatically if a `app.dSYM.zip` file is found next to `app.ipa`. In case it is located in a different place you can specify the path explicitly in `:dsym` parameter.

More information about the available options can be found in the [HockeyApp Docs](http://support.hockeyapp.net/kb/api/api-versions#upload-version).

### [Crashlytics Beta](http://try.crashlytics.com/beta/)
```ruby
crashlytics(
  crashlytics_path: './Crashlytics.framework', # path to your 'Crashlytics.framework'
  api_token: '...',
  build_secret: '...',
  ipa_path: './app.ipa'
)
```
Additionally you can specify `notes_path`, `emails`, `groups` and `notifications`.

The following environment variables may be used in place of parameters: `CRASHLYTICS_API_TOKEN`, `CRASHLYTICS_BUILD_SECRET`, and `CRASHLYTICS_FRAMEWORK_PATH`.

### AWS S3 Distribution

Upload a new build to Amazon S3 to distribute the build to beta testers. Works for both Ad Hoc and Enterprise signed applications. This step will generate the necessary HTML and plist files for you.

Add the `s3` action after the `ipa` step:

```ruby
s3
```

You can also customize a lot of options:
```ruby
s3(
  # All of these are used to make Shenzhen's `ipa distribute:s3` command
  access_key: ENV['S3_ACCESS_KEY'],               # Required from user.
  secret_access_key: ENV['S3_SECRET_ACCESS_KEY'], # Required from user.
  bucket: ENV['S3_BUCKET'],                       # Required from user.
  file: 'AppName.ipa',                            # This would come from IpaAction.
  dsym: 'AppName.app.dSYM.zip',                   # This would come from IpaAction.
  path: 'v{CFBundleShortVersionString}_b{CFBundleVersion}/' # This is actually the default.
)
```

It is recommended to **not** store the AWS access keys in the `Fastfile`.

### [DeployGate](https://deploygate.com/)

You can retrieve your username and API token on [your settings page](https://deploygate.com/settings).

```ruby
deploygate(
  api_token: '...',
  user: 'target username or organization name',
  ipa: './ipa_file.ipa',
  message: "Build #{Actions.lane_context[Actions::SharedValues::BUILD_NUMBER]}",
)
```

If you put `deploygate` after `ipa` action, you don't have to specify IPA file path, as it is extracted from the lane context automatically.

More information about the available options can be found in the [DeployGate Push API document](https://deploygate.com/docs/api).

## Modifying Project

### [increment_build_number](https://developer.apple.com/library/ios/qa/qa1827/_index.html)
This method will increment the **build number**, not the app version. Usually this is just an auto incremented number. You first have to [set up your Xcode project](https://developer.apple.com/library/ios/qa/qa1827/_index.html), if you haven't done it already.

```ruby
increment_build_number # automatically increment by one
increment_build_number(
  build_number: '75' # set a specific number
)

increment_build_numer(
  build_number: 75, # specify specific build number (optional, omitting it increments by one)
  xcodeproj: './path/to/MyApp.xcodeproj' # (optional, you must specify the path to your main Xcode project if it is not in the project root directory)
)
```

### [increment_version_number](https://developer.apple.com/library/ios/qa/qa1827/_index.html)
This action will increment the **version number**. You first have to [set up your Xcode project](https://developer.apple.com/library/ios/qa/qa1827/_index.html), if you haven't done it already.

```ruby
increment_version_number # Automatically increment patch version number.
increment_version_number(
  bump_type: "patch" # Automatically increment patch version number
)
increment_version_number(
  bump_type: "minor" # Automatically increment minor version number
)
increment_version_number(
  bump_type: "major" # Automatically increment major version number
)
increment_version_number(
  version_number: '2.1.1' # Set a specific version number
)

increment_version_number(
  version_number: '2.1.1',                # specify specific version number (optional, omitting it increments patch version number)
  xcodeproj: './path/to/MyApp.xcodeproj'  # (optional, you must specify the path to your main Xcode project if it is not in the project root directory)
)
```

### set_build_number_repository
```ruby
set_build_number_repository
```

This action will set the **build number** according to what the SCM HEAD reports.
Currently supported SCMs are svn (uses root revision), git-svn (uses svn revision) and git (uses short hash).

There are no options currently available for this action.

## Developer Portal

### [sigh](https://github.com/KrauseFx/sigh)
This will generate and download your App Store provisioning profile. `sigh` will store the generated profile in the current folder.

```ruby
sigh
```

You can pass all options listed in `sigh --help` in `fastlane`:

```ruby
sigh(
  adhoc: true,
  force: true,
  filename: "myFile.mobileprovision"
)
```

### [PEM](https://github.com/KrauseFx/PEM)

This will generate a new push profile if necessary (the old one is about to expire).

Use it like this:

```ruby
pem
```

```ruby
pem(
  force: true, # create a new profile, even if the old one is still valid
  app_identifier: 'net.sunapps.9', # optional app identifier,
  save_private_key: true,
  new_profile: Proc.new do |profile_path| # this block gets called when a new profile was generated
    puts profile_path # the absolute path to the new PEM file
    # insert the code to upload the PEM file to the server
  end
)
```

Use the `fastlane action pem` command to view all available options.

### [cert](https://github.com/KrauseFx/cert)

The `cert` action can be used to make sure to have the latest signing certificate installed. More information on the [`cert` project page](https://github.com/KrauseFx/cert).

```ruby
cert
```

`fastlane` will automatically pass the signing certificate to use to `sigh`.

You can pass all options listed in `sigh --help` in `fastlane`:

```ruby
cert(
  development: true,
  username: "user@email.com"
)
```

### [produce](https://github.com/KrauseFx/produce)

Create new apps on iTunes Connect and Apple Developer Portal. If the app already exists, `produce` will not do anything.

```ruby
produce(
  produce_username: 'felix@krausefx.com',
  produce_app_identifier: 'com.krausefx.app',
  produce_app_name: 'MyApp',
  produce_language: 'English',
  produce_version: '1.0',
  produce_sku: 123,
  produce_team_name: 'SunApps GmbH' # Only necessary when in multiple teams.
)
```

### register_devices
This will register iOS devices with the Developer Portal so that you can include them in your provisioning profiles.

This is an optimistic action, in that it will only ever add new devices to the member center, and never remove devices. If a device which has already been registered within the member center is not passed to this action, it will be left alone in the member center and continue to work.

If you're a member of multiple teams, you don't need to explicitly specify the team ID. In this case the action will try to get the team ID from `ENV['CUPERTINO_TEAM_ID']`, or `ENV['FASTLANE_TEAM_ID']`, in that order. So if you've specified the team ID using the team_id action, this action will automatically pick it up.

The action will connect to the Apple Developer Portal using the username you specified in your `Appfile` with `apple_id`, but you can override it using the `username` option, or by setting the env variable `ENV['CUPERTINO_USERNAME']`.

```ruby
# Simply provide a list of devices as a Hash
register_devices(
  devices: {
    'Luka iPhone 6' => '1234567890123456789012345678901234567890',
    'Felix iPad Air 2' => 'abcdefghijklmnopqrstvuwxyzabcdefghijklmn',
  }
)

# Alternatively provide a standard UDID export .txt file, see the Apple Sample (https://devimages.apple.com.edgekey.net/downloads/devices/Multiple-Upload-Samples.zip)
register_devices(
  devices_file: './devices.txt'
)

# Advanced
register_devices(
  devices_file: './devices.txt', # You must pass in either `devices_file` or `devices`.
  team_id: 'XXXXXXXXXX',         # Optional, if you're a member of multiple teams, then you need to pass the team ID here.
  username: 'luka@goonbee.com'   # Optional, lets you override the Apple Member Center username.
)
```

## Using git

### ensure_git_status_clean
A sanity check to make sure you are working in a repo that is clean. Especially useful to put at the beginning of your Fastfile in the `before_all` block, if some of your other actions will touch your filesystem, do things to your git repo, or just as a general reminder to save your work. Also needed as a prerequisite for some other actions like `reset_git_repo`.

```ruby
ensure_git_status_clean
```

### commit_version_bump
This action will create a "Version Bump" commit in your repo. Useful in conjunction with `increment_build_number`.

It checks the repo to make sure that only the relevant files have changed, these are the files that `increment_build_number` (`agvtool`) touches:
- All .plist files
- The `.xcodeproj/project.pbxproj` file

Then commits those files to the repo.

Customise the message with the `:message` option, defaults to "Version Bump"

If you have other uncommitted changes in your repo, this action will fail. If you started off in a clean repo, and used the `ipa` and or `sigh` actions, then you can use the `clean_build_artifacts` action to clean those temporary files up before running this action.

```ruby
commit_version_bump

commit_version_bump(
  message: 'Version Bump',                    # create a commit with a custom message
  xcodeproj: './path/to/MyProject.xcodeproj', # optional, if you have multiple Xcode project files, you must specify your main project here
)
```

### add_git_tag
This will automatically tag your build with the following format: `<grouping>/<lane>/<prefix><build_number>`, where:

- `grouping` is just to keep your tags organised under one "folder", defaults to 'builds'
- `lane` is the name of the current fastlane lane
- `prefix` is anything you want to stick in front of the version number, e.g. "v"
- `build_number` is the build number, which defaults to the value emitted by the `increment_build_number` action

For example for build 1234 in the "appstore" lane it will tag the commit with `builds/appstore/1234`

```ruby
add_git_tag # simple tag with default values

add_git_tag(
  grouping: 'fastlane-builds',
  prefix: 'v',
  build_number: 123
)
```

Alternatively, you can specify your own tag. Note that if you do specify a tag, all other arguments are ignored.

```ruby
add_git_tag(
  tag: 'my_custom_tag',
)
```

### push_to_git_remote
Lets you push your local commits to a remote git repo. Useful if you make local changes such as adding a version bump commit (using `commit_version_bump`) or a git tag (using 'add_git_tag') on a CI server, and you want to push those changes back to your canonical/main repo.

Tags will be pushed as well.

```ruby
push_to_git_remote # simple version. pushes 'master' branch to 'origin' remote

push_to_git_remote(
  remote: 'origin',         # optional, default: 'origin'
  local_branch: 'develop',  # optional, aliased by 'branch', default: 'master'
  remote_branch: 'develop', # optional, default is set to local_branch
  force: true,              # optional, default: false
)
```

### reset_git_repo
This action will reset your git repo to a clean state, discarding any uncommitted and untracked changes. Useful in case you need to revert the repo back to a clean state, e.g. after the fastlane run.

It's a pretty drastic action so it comes with a sort of safety latch. It will only proceed with the reset if either of these conditions are met:

- You have called the `ensure_git_status_clean` action prior to calling this action. This ensures that your repo started off in a clean state, so the only things that will get destroyed by this action are files that are created as a byproduct of the fastlane run.
- You call it with the `:force` option, in which case "you have been warned".

Also useful for putting in your `error` block, to bring things back to a pristine state (again with the caveat that you have called `ensure_git_status_clean` before)

```ruby
reset_git_repo
reset_git_repo :force # If you don't care about warnings and are absolutely sure that you want to discard all changes. This will reset the repo even if you have valuable uncommitted changes, so use with care!

# You can also specify a list of files that should be resetted.
reset_git_repo(
  force: true,
  files: [
    "./file.txt"
  ])
```

## Notifications

### [Slack](http://slack.com)
Create an Incoming WebHook and export this as `SLACK_URL`. Can send a message to **#channel** (by default), a direct message to **@username** or a message to a private group **group** with success (green) or failure (red) status.

```ruby
slack(
  message: "App successfully released!"
)

slack(
  message: "App successfully released!",
  channel: "#channel",  # Optional, by default will post to the default channel configured for the POST URL.
  success: true,        # Optional, defaults to true.
  payload: {            # Optional, lets you specify any number of your own Slack attachments.
    'Build Date' => Time.new.to_s,
    'Built by' => 'Jenkins',
  },
  default_payloads: [:git_branch, :git_author] # Optional, lets you specify a whitelist of default payloads to include. Pass an empty array to suppress all the default payloads. Don't add this key, or pass nil, if you want all the default payloads. The available default payloads are: `lane`, `test_result`, `git_branch`, `git_author`, `last_git_commit`.
)
```

### [Mailgun](http://www.mailgun.com)
Send email notifications right from `fastlane` using [Mailgun](http://www.mailgun.com). 

```ruby
ENV['MAILGUN_SANDBOX_DOMAIN'] ||= "MY_SANDBOX_DOMAIN"
ENV['MAILGUN_SANDBOX_POSTMASTER'] ||= "MY_POSTMASTER"
ENV['MAILGUN_APIKEY'] = "MY_API_KEY"

mailgun(
  to: "fastlane@krausefx.com",
  success: true,
  message: "This is the mail's content"
)

or

mailgun(
  mailgun_sandbox_domain: "SANDBOX_DOMAIN",
  mailgun_sandbox_postmaster: "MY_POSTMASTER",
  mailgun_apikey: "MY_API_KEY",
  to: "DESTINATION_EMAIL",
  success: true,
  message: "Mail Body"
)
```

### [HipChat](http://www.hipchat.com/)
Send a message to **room** (by default) or a direct message to **@username** with success (green) or failure (red) status.

```ruby
  ENV["HIPCHAT_API_TOKEN"] = "Your API token"
  ENV["HIPCHAT_API_VERSION"] = "1 for API version 1 or 2 for API version 2"

  hipchat(
    message: "App successfully released!",
    channel: "Room or @username",
    success: true
  )
```

### [Typetalk](https://typetalk.in/)
Send a message to **topic** with success (:smile:) or failure (:rage:) status.
[Using Bot's Typetalk Token](https://developer.nulab-inc.com/docs/typetalk/auth#tttoken)

```ruby
  typetalk(
    message: "App successfully released!",
    note_path: 'ChangeLog.md',
    topicId: 1,
    success: true,
    typetalk_token: 'Your Typetalk Token'
  )
```

### [Hall](https://hall.com/)
Post a message to a **group**

```ruby
  ENV["HALL_GROUP_API_TOKEN"] = "Your Group API token" # Activate an Incoming Webhook integration to get your Group API token

  hall(
    message: "App successfully released!",
    title: "fastlane",
    picture: "https://s3-eu-west-1.amazonaws.com/fastlane.tools/fastlane.png"
  )
```

### [ChatWork](http://www.chatwork.com/)
Post a message to a **group chat**.

[How to authenticate ChatWork API](http://developer.chatwork.com/ja/authenticate.html)

```ruby
  ENV["CHATWORK_API_TOKEN"] = "Your API token"

  chatwork(
    message: "App successfully released!",
    roomid: 12345,
    success: true
  )
```

### Notify
Display a notification using the OS X notification centre. Uses [terminal-notifier](https://github.com/alloy/terminal-notifier).

```ruby
  notify "Finished driving lane"
```

### [Testmunk](http://testmunk.com)
Run your functional tests on real iOS devices over the cloud (for free on an iPod). With this simple [testcase](https://github.com/testmunk/TMSample/blob/master/testcases/smoke/smoke_features.zip) you can ensure your app launches and there is no crash at launch. Tests can be extended with [Testmunk's library](http://docs.testmunk.com/en/latest/steps.html) or custom steps. More details about this action can be found in [`testmunk.rb`](https://github.com/KrauseFx/fastlane/blob/master/lib/fastlane/actions/testmunk.rb).

```ruby
ENV['TESTMUNK_EMAIL'] = 'email@email.com'
# Additionally, you have to set TESTMUNK_API, TESTMUNK_APP and TESTMUNK_IPA
testmunk
```

## Other

### update_fastlane

This action will look at all installed fastlane tools and update them to the next available minor version - major version updates will not be performed automatically, as they might include breaking changes. If an update was performed, fastlane will be restarted before the run continues.

If you are using rbenv or rvm, everything should be good to go. However, if you are using the system's default ruby, some additional setup is needed for this action to work correctly. In short, fastlane needs to be able to access your gem library without running in `sudo` mode.

The simplest possible fix for this is putting the following lines into your `~/.bashrc` or `~/.zshrc` file:

```bash
  export GEM_HOME=~/.gems
  export PATH=$PATH:~/.gems/bin
```

After the above changes, restart your terminal, then run `mkdir $GEM_HOME` to create the new gem directory. After this, you're good to go!

Recommended usage of the `update_fastlane` action is at the top of the `before_all` block, before running any other action:

```ruby
  before_all do
    update_fastlane

    cocoapods
    increment_build_number
    ...
  end
```
